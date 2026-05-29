extends Node2D
class_name Player

signal health_changed(current: int, max_val: int)

@export var max_health: int = 80
var current_health: int = 80
var base_damage: int = 10

var damage_modifier: int = 0
var poison_ticks: int = 0
var poison_damage: int = 4

func _ready() -> void:
	reset_properties()

func reset_properties() -> void:
	current_health = max_health
	damage_modifier = 0
	poison_ticks = 0
	health_changed.emit(current_health, max_health)

func take_damage(amount: int) -> void:
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)

func get_damage() -> int:
	return max(1, base_damage + damage_modifier)

func apply_poison() -> void:
	poison_ticks = 3

func apply_damage_debuff() -> void:
	damage_modifier = -3

func process_curse_turn() -> void:
	if poison_ticks > 0:
		take_damage(poison_damage)
		poison_ticks -= 1
	else:
		poison_ticks = 0

func play_attack() -> void:
	pass
