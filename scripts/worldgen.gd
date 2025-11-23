extends Node2D

# --- tiles / chunking ---
@export var layer: int = 0
@export var chunk_size: int = 96
@export var chunk_radius: int = 2
@export var floor_name: String = "Floor"
@export var wall_name: String = "Wall"

# --- enclosures (houses) ---
# smaller rooms, more of them
@export var enclosures_min: int = 5          # more rooms
@export var enclosures_max: int = 10
@export var encl_w_min: int = 6              # smaller widths
@export var encl_w_max: int = 12
@export var encl_h_min: int = 6
@export var encl_h_max: int = 12
@export var wall_thickness: int = 1
@export var doorway_width: int = 2
@export var carve_margin: int = 1
@export_range(0.0,1.0,0.05) var room_cluster_bias: float = 0.75
@export var min_gap_between_walls: int = 1

# --- fences (fewer random walls) ---
@export var fences_min: int = 0
@export var fences_max: int = 2
@export var fence_len_min: int = 12
@export var fence_len_max: int = 40
@export var connector_overhang: int = 2
@export var fence_place_retries: int = 6

# --- gems / meta progression pickups ---
@export var gem_scene: PackedScene           # assign gem_pickup.tscn in inspector
@export_range(0.0, 1.0, 0.05) var gem_spawn_chance: float = 0.6
@export var gems_min_per_room: int = 1
@export var gems_max_per_room: int = 1

@onready var tm: TileMap = $World

var tiles: Dictionary = {}
var generated := {}
var seed: int = 0

# centers recorded for later gem spawns
var nooks: Dictionary = {}                   # chunk -> Array[Vector2i]

@export var auto_generate_on_ready := true

func _ready() -> void:
	_build_tile_lookup()
	if auto_generate_on_ready:
		regenerate()

func regenerate(center: Vector2 = Vector2.ZERO, new_seed: int = -1) -> void:
	if new_seed == -1:
		randomize()
		seed = randi()
	else:
		seed = new_seed

	generated.clear()
	tm.clear()
	_ensure_chunks_around(center)

# ---------------- chunk streaming ----------------
func _ensure_chunks_around(world_pos: Vector2) -> void:
	var cell: Vector2i = tm.local_to_map(tm.to_local(world_pos))
	var cx: int = int(floor(float(cell.x) / float(chunk_size)))
	var cy: int = int(floor(float(cell.y) / float(chunk_size)))
	for dy in range(-chunk_radius, chunk_radius + 1):
		for dx in range(-chunk_radius, chunk_radius + 1):
			var key := Vector2i(cx + dx, cy + dy)
			if not generated.has(key):
				_generate_chunk(key)
				generated[key] = true

# ---------------- generation ----------------
func _generate_chunk(chunk: Vector2i) -> void:
	var base_x: int = chunk.x * chunk_size
	var base_y: int = chunk.y * chunk_size

	# fill with floor
	for ly in range(chunk_size):
		for lx in range(chunk_size):
			_put(floor_name, Vector2i(base_x + lx, base_y + ly))

	# occupancy map of existing walls for this chunk
	var occ := {}   # Dictionary[Vector2i] = true

	# deterministic RNG per chunk
	var rng := RandomNumberGenerator.new()
	rng.seed = int(seed) ^ (chunk.x * 19349663) ^ (chunk.y * 83492791)

	# ---- place clustered enclosures with doors ----
	var rooms: Array[Rect2i] = []
	var encl_count: int = rng.randi_range(enclosures_min, enclosures_max)

	for i in range(encl_count):
		var placed := false
		for attempt in range(16):
			# size (smaller than before)
			var w: int = rng.randi_range(encl_w_min, encl_w_max)
			var h: int = rng.randi_range(encl_h_min, encl_h_max)

			# position: bias toward an existing room center
			var rx: int
			var ry: int
			if rooms.size() > 0 and rng.randf() < room_cluster_bias:
				var anchor: Rect2i = rooms[rng.randi_range(0, rooms.size() - 1)]
				var c := _rect_center(anchor)
				var off_x := rng.randi_range(-20, 20)
				var off_y := rng.randi_range(-20, 20)
				rx = clamp(c.x + off_x - w / 2, base_x + carve_margin, base_x + chunk_size - w - carve_margin)
				ry = clamp(c.y + off_y - h / 2, base_y + carve_margin, base_y + chunk_size - h - carve_margin)
			else:
				rx = base_x + carve_margin + rng.randi_range(0, max(1, chunk_size - w - carve_margin * 2))
				ry = base_y + carve_margin + rng.randi_range(0, max(1, chunk_size - h - carve_margin * 2))

			var rect := Rect2i(Vector2i(rx, ry), Vector2i(w, h))

			# outline cells + door
			var cells: Array[Vector2i] = _rect_outline_cells(rect, wall_thickness)
			var door_cells := _pick_door_cells(rect, doorway_width, wall_thickness, rng)
			for d in door_cells:
				cells.erase(d)

			if _cells_free_with_gap(cells, occ, min_gap_between_walls):
				_commit_walls(cells, occ)
				rooms.append(rect)
				if not nooks.has(chunk):
					nooks[chunk] = []
				(nooks[chunk] as Array).append(_rect_center(rect))
				placed = true
				break

	# ---- very few fences; also avoid overlaps ----
	var fence_count: int = rng.randi_range(fences_min, fences_max)
	for j in range(fence_count):
		var placed_fence := false
		for attempt in range(fence_place_retries):
			var horizontal := rng.randf() < 0.5
			if horizontal:
				var y := base_y + rng.randi_range(carve_margin, chunk_size - carve_margin - 1)
				var x0 := base_x + rng.randi_range(-connector_overhang, chunk_size - fence_len_min)
				var len := rng.randi_range(fence_len_min, fence_len_max)
				var cells := _h_line_cells(x0, x0 + len, y, wall_thickness)
				if _cells_free_with_gap(cells, occ, min_gap_between_walls):
					_commit_walls(cells, occ); placed_fence = true; break
			else:
				var x := base_x + rng.randi_range(carve_margin, chunk_size - carve_margin - 1)
				var y0 := base_y + rng.randi_range(-connector_overhang, chunk_size - fence_len_min)
				var vlen := rng.randi_range(fence_len_min, fence_len_max)
				var vcells := _v_line_cells(y0, y0 + vlen, x, wall_thickness)
				if _cells_free_with_gap(vcells, occ, min_gap_between_walls):
					_commit_walls(vcells, occ); placed_fence = true; break

	# ---- short edge connectors (still avoid overlaps) ----
	var y_mid: int = base_y + rng.randi_range(4, chunk_size - 5)
	var right_stub := _h_line_cells(base_x + chunk_size - connector_overhang, base_x + chunk_size + connector_overhang, y_mid, wall_thickness)
	if _cells_free_with_gap(right_stub, occ, min_gap_between_walls):
		_commit_walls(right_stub, occ)

	var x_mid: int = base_x + rng.randi_range(4, chunk_size - 5)
	var bottom_stub := _v_line_cells(base_y + chunk_size - connector_overhang, base_y + chunk_size + connector_overhang, x_mid, wall_thickness)
	if _cells_free_with_gap(bottom_stub, occ, min_gap_between_walls):
		_commit_walls(bottom_stub, occ)

	# ---- GEM SPAWNS INSIDE SOME ROOMS ----
	if gem_scene:
		for r in rooms:
			# only some rooms get gems
			if rng.randf() <= gem_spawn_chance:
				var center_cell: Vector2i = _rect_center(r)
				var local_pos: Vector2 = tm.map_to_local(center_cell)
				var world_pos: Vector2 = tm.to_global(local_pos)

				var count := rng.randi_range(gems_min_per_room, gems_max_per_room)
				for k in range(count):
					var gem := gem_scene.instantiate()
					var offset := Vector2(rng.randf_range(-8.0, 8.0), rng.randf_range(-8.0, 8.0))
					gem.global_position = world_pos + offset
					add_child(gem)

# ---------------- helpers: geometry & occupancy ----------------
func _rect_center(r: Rect2i) -> Vector2i:
	return Vector2i(r.position.x + r.size.x / 2, r.position.y + r.size.y / 2)

func _rect_outline_cells(r: Rect2i, t: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for yy in range(r.position.y, r.position.y + t):
		for xx in range(r.position.x, r.position.x + r.size.x):
			cells.append(Vector2i(xx, yy))
	for yy2 in range(r.position.y + r.size.y - t, r.position.y + r.size.y):
		for xx2 in range(r.position.x, r.position.x + r.size.x):
			cells.append(Vector2i(xx2, yy2))
	for xx3 in range(r.position.x, r.position.x + t):
		for yy3 in range(r.position.y, r.position.y + r.size.y):
			cells.append(Vector2i(xx3, yy3))
	for xx4 in range(r.position.x + r.size.x - t, r.position.x + r.size.x):
		for yy4 in range(r.position.y, r.position.y + r.size.y):
			cells.append(Vector2i(xx4, yy4))
	return cells

func _pick_door_cells(r: Rect2i, door_w: int, t: int, rng: RandomNumberGenerator) -> Array[Vector2i]:
	door_w = max(1, door_w)
	var cells: Array[Vector2i] = []
	var side := rng.randi_range(0, 3)
	match side:
		0:
			var x0 := r.position.x + t + rng.randi_range(0, max(1, r.size.x - t*2 - door_w))
			for x in range(x0, x0 + door_w):
				for yy in range(r.position.y, r.position.y + t):
					cells.append(Vector2i(x, yy))
		1:
			var x1 := r.position.x + t + rng.randi_range(0, max(1, r.size.x - t*2 - door_w))
			for x in range(x1, x1 + door_w):
				for yy in range(r.position.y + r.size.y - t, r.position.y + r.size.y):
					cells.append(Vector2i(x, yy))
		2:
			var y0 := r.position.y + t + rng.randi_range(0, max(1, r.size.y - t*2 - door_w))
			for y in range(y0, y0 + door_w):
				for xx in range(r.position.x, r.position.x + t):
					cells.append(Vector2i(xx, y))
		3:
			var y1 := r.position.y + t + rng.randi_range(0, max(1, r.size.y - t*2 - door_w))
			for y in range(y1, y1 + door_w):
				for xx in range(r.position.x + r.size.x - t, r.position.x + r.size.x):
					cells.append(Vector2i(xx, y))
	return cells

func _h_line_cells(x0: int, x1: int, y: int, t: int) -> Array[Vector2i]:
	if x1 < x0:
		var tmp := x0
		x0 = x1
		x1 = tmp
	var cells: Array[Vector2i] = []
	for yy in range(y - (t - 1) / 2, y + t / 2 + 1):
		for xx in range(x0, x1 + 1):
			cells.append(Vector2i(xx, yy))
	return cells

func _v_line_cells(y0: int, y1: int, x: int, t: int) -> Array[Vector2i]:
	if y1 < y0:
		var tmp := y0
		y0 = y1
		y1 = tmp
	var cells: Array[Vector2i] = []
	for xx in range(x - (t - 1) / 2, x + t / 2 + 1):
		for yy in range(y0, y1 + 1):
			cells.append(Vector2i(xx, yy))
	return cells

func _cells_free_with_gap(cells: Array, occ: Dictionary, gap: int) -> bool:
	if gap <= 0:
		for c in cells:
			if occ.has(c):
				return false
		return true
	for c in cells:
		for dy in range(-gap, gap + 1):
			for dx in range(-gap, gap + 1):
				var k := Vector2i(c.x + dx, c.y + dy)
				if occ.has(k):
					return false
	return true

func _commit_walls(cells: Array, occ: Dictionary) -> void:
	for c in cells:
		_put(wall_name, c)
		occ[c] = true

# ---------------- tileset lookup & paint ----------------
func _build_tile_lookup() -> void:
	tiles.clear()
	var ts: TileSet = tm.tile_set
	if ts == null:
		push_warning("TileMap has no TileSet.")
		return

	var source_ids: Array[int] = []
	if ts.has_method("get_source_count") and ts.has_method("get_source_id"):
		var count: int = ts.call("get_source_count")
		for i in range(count):
			source_ids.append(int(ts.call("get_source_id", i)))
	elif ts.has_method("get_source_ids"):
		source_ids = ts.call("get_source_ids")

	for source_id in source_ids:
		var src := ts.get_source(source_id)
		if src is TileSetAtlasSource:
			var atlas: TileSetAtlasSource = src
			var ids: Array = []
			if atlas.has_method("get_tiles_ids"):
				ids = atlas.call("get_tiles_ids")
			elif atlas.has_method("get_tiles_count") and atlas.has_method("get_tile_id"):
				var tcount: int = int(atlas.call("get_tiles_count"))
				for ti in range(tcount):
					ids.append(atlas.call("get_tile_id", ti))
			for tile_id in ids:
				var coords: Vector2i = tile_id
				var td: TileData = atlas.get_tile_data(coords, 0)
				if td == null:
					continue
				var raw = td.get_custom_data("name")
				if raw == null:
					continue
				var n := str(raw).strip_edges()
				if n.length() >= 2 and n.begins_with('"') and n.ends_with('"'):
					n = n.substr(1, n.length() - 2)
				if n == floor_name or n == wall_name:
					tiles[n] = {"source_id": int(source_id), "atlas": coords, "alt": 0}

func _put(name: String, cell: Vector2i) -> void:
	if not tiles.has(name):
		return
	var t: Dictionary = tiles[name]
	tm.set_cell(layer, cell, t["source_id"], t["atlas"], t["alt"])
