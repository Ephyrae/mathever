extends Node2D
class_name Player

signal health_changed(current: int, max_val: int)

@export var max_health: int = 80
var current_health: int = 80
var base_damage: int = 10
var is_active: bool = true

var damage_modifier: int = 0
var poison_ticks: int = 0
var poison_damage: int = 4

var slash_attack := ""
var slash_animations = [
	"slash",
	"slash2",
	"slash3"
]

func _ready() -> void:
	reset_properties()
	randomize()
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	if $AnimatedSprite2D.animation == slash_attack:
		$AnimatedSprite2D.play("idle")
	elif $AnimatedSprite2D.animation == "hit":
		$AnimatedSprite2D.play("idle")

func reset_properties() -> void:
	current_health = max_health
	damage_modifier = 0
	poison_ticks = 0
	show()
	health_changed.emit(current_health, max_health)
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("idle")

func take_damage(amount: int) -> void:
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("hit")
	SoundManager.play_random_sfx(SoundManager.SFX_HIT, 0.0, randf_range(1.1,1.3 ))

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
	if has_node("AnimatedSprite2D"):
		slash_attack = slash_animations.pick_random()
		$AnimatedSprite2D.play(slash_attack)
		SoundManager.play_random_sfx(SoundManager.SFX_SLASHES, 0.0, randf_range(0.9,1.1))
	if slash_attack == "slash": #Pag double slash
			await get_tree().create_timer(0.5).timeout
			SoundManager.play_random_sfx(SoundManager.SFX_SLASHES, 0.0, randf_range(0.9, 1.1))

func play_death() -> void:
	if has_node("Sprite2D"):
		$Sprite2D.hide()
	if has_node("AnimatedSprite2D"):
		var anim: AnimatedSprite2D = $AnimatedSprite2D
		anim.show()
		anim.stop()
		anim.frame = 0
		anim.play("death")
		SoundManager.stop_bgm(2) #bgm stop
		SoundManager.play_sfx(SoundManager.SFX_DEATH)
