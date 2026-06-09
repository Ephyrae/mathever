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
	SoundManager.play_sfx(SoundManager.SFX_ENEMY_BLOCK)
	
	if current_health <= 0:
		play_death()
	else:
		play_hit()

func get_damage() -> int:
	return max(1, base_damage + damage_modifier)

func play_attack() -> void:
	if has_node("AnimationPlayer") and $AnimationPlayer.has_animation("attack"):
		$AnimationPlayer.play("attack")
		SoundManager.play_sfx(SoundManager.SFX_ENEMY_ATTACK)
	elif has_node("AnimatedSprite2D") and $AnimatedSprite2D.sprite_frames.has_animation("attack"):
		$AnimatedSprite2D.play("attack")
		SoundManager.play_sfx(SoundManager.SFX_ENEMY_ATTACK)

func play_hit() -> void:
	if has_node("AnimationPlayer") and $AnimationPlayer.has_animation("hit"):
		$AnimationPlayer.play("hit")
	elif has_node("AnimatedSprite2D") and $AnimatedSprite2D.sprite_frames.has_animation("hit"):
		if not $AnimatedSprite2D.animation_finished.is_connected(_on_animation_finished):
			$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)
		$AnimatedSprite2D.play("hit")
	SoundManager.play_sfx(SoundManager.SFX_E1HIT)

func play_death() -> void:
	if has_node("AnimationPlayer") and $AnimationPlayer.has_animation("death"):
		$AnimationPlayer.play("death")
	elif has_node("AnimatedSprite2D") and $AnimatedSprite2D.sprite_frames.has_animation("death"):
		if not $AnimatedSprite2D.animation_finished.is_connected(_on_animation_finished):
			$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)
		$AnimatedSprite2D.play("death")
	else:
		# Fallback: simple fade out
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 1.0)
		tween.tween_callback(hide)
	SoundManager.play_sfx(SoundManager.SFX_E1DEATH)

func _on_animation_finished() -> void:
	if has_node("AnimatedSprite2D"):
		if $AnimatedSprite2D.animation == "hit":
			$AnimatedSprite2D.play("idle")
		elif $AnimatedSprite2D.animation == "attack":
			$AnimatedSprite2D.play("idle")
		elif $AnimatedSprite2D.animation == "death":
			hide()

func process_curse_turn() -> void:
	if poison_ticks > 0:
		take_damage(poison_damage)
		poison_ticks -= 1
