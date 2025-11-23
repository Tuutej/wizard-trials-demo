extends CanvasLayer

signal spell_selected(spell_name)

var spell_options = [
	{"name": "fireball", "description": "Launches a fireball that deals high damage. Uses E key."},
	{"name": "iceshard", "description": "Shoots ice shards that slow enemies. Uses Q key."}, 
	{"name": "lightning", "description": "Casts lightning that chains between enemies. Uses F key."}
]

func _ready():
	
	visible = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	get_tree().paused = true
	# connect buttons
	$Panel/BoxContainer/SpellButton1.pressed.connect(_on_spell1_selected)
	$Panel/BoxContainer/SpellButton2.pressed.connect(_on_spell2_selected)
	$Panel/BoxContainer/SpellButton3.pressed.connect(_on_spell3_selected)
	
	$Panel/BoxContainer/SpellButton1.mouse_entered.connect(_on_spell1_hover.bind())
	$Panel/BoxContainer/SpellButton2.mouse_entered.connect(_on_spell2_hover.bind())
	$Panel/BoxContainer/SpellButton3.mouse_entered.connect(_on_spell3_hover.bind())
	
	# set button texts
	$Panel/BoxContainer/SpellButton1/SpellName.text = "Fireball (E)"
	$Panel/BoxContainer/SpellButton2/SpellName.text = "Ice Shard (Q)"
	$Panel/BoxContainer/SpellButton3/SpellName.text = "Lightning (F)"
	
	# set initial description
	$Panel/Description.text = spell_options[0]["description"]
	$Panel/BoxContainer/SpellButton1.grab_focus()

func _on_spell1_selected():
	get_tree().paused = false
	emit_signal("spell_selected", "fireball")
	queue_free()

func _on_spell2_selected():
	get_tree().paused = false
	emit_signal("spell_selected", "iceshard")
	queue_free()

func _on_spell3_selected():
	get_tree().paused = false
	emit_signal("spell_selected", "lightning")
	queue_free()

func _on_spell1_hover():
	$Panel/Description.text = spell_options[0]["description"]

func _on_spell2_hover():
	$Panel/Description.text = spell_options[1]["description"]

func _on_spell3_hover():
	$Panel/Description.text = spell_options[2]["description"]
