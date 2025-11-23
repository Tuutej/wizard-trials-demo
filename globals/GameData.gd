extends Node

var gems: int = 0

var meta_hp_bonus: int = 0
var meta_mana_bonus: int = 0
var meta_speed_bonus: float = 0.0
var meta_mana_regen_bonus: float = 0.0
var meta_health_regen_bonus: float = 0.0

const COST := {
	"hp": 3,
	"mana": 3,
	"speed": 3,
	"mana_regen": 6,
	"health_regen": 6,
}

func add_gems(amount := 1) -> void:
	gems += amount

func can_buy(stat: String) -> bool:
	return gems >= COST.get(stat, 99999)

func buy(stat: String) -> bool:
	if not can_buy(stat):
		return false
	gems -= COST[stat]
	match stat:
		"hp":           meta_hp_bonus += 10
		"mana":         meta_mana_bonus += 10
		"speed":        meta_speed_bonus += 10.0
		"mana_regen":   meta_mana_regen_bonus += 2.0
		"health_regen": meta_health_regen_bonus += 0.5
	return true

# save/load
func save():
	var d = {
		"gems": gems,
		"meta_hp_bonus": meta_hp_bonus,
		"meta_mana_bonus": meta_mana_bonus,
		"meta_speed_bonus": meta_speed_bonus,
		"meta_mana_regen_bonus": meta_mana_regen_bonus,
		"meta_health_regen_bonus": meta_health_regen_bonus,
	}
	var f = FileAccess.open("user://meta.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(d)); f.close()

func load():
	if not FileAccess.file_exists("user://meta.json"): return
	var f = FileAccess.open("user://meta.json", FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text()); f.close()
	if typeof(d) == TYPE_DICTIONARY:
		for k in d.keys():
			set(k, d[k])
