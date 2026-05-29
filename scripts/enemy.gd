extends Node2D
class_name Enemy

signal health_changed(current: int, max_val: int)

var max_health: int = 50
var current_health: int = 50
var base_damage: int = 8
var enemy_name: String = "Enemy"

var damage_modifier: int = 0
var poison_ticks: int = 0
var poison_damage: int = 4

func _ready() -> void:
	reset_properties()

func reset_properties() -> void:
	damage_modifier = 0
	poison_ticks = 0

func setup(hp: int, n_name: String, _texture: Texture2D = null) -> void:
	reset_properties()
	max_health = hp
	current_health = hp
	enemy_name = n_name
	
	if has_node("Sprite2D") and _texture != null:
		get_node("Sprite2D").texture = _texture
		
	health_changed.emit(current_health, max_health)

func take_damage(amount: int) -> void:
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)

func get_damage() -> int:
	return max(1, base_damage + damage_modifier)

func process_curse_turn() -> void:
	if poison_ticks > 0:
		take_damage(poison_damage)
		poison_ticks -= 1
