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

var original_position: Vector2 = Vector2.ZERO
var is_attacking: bool = false

var active_sprite: AnimatedSprite2D = null

func _ready() -> void:
	reset_properties()
	if has_node("AnimationPlayer"):
		$AnimationPlayer.animation_finished.connect(_on_animation_finished_player)

func _on_animation_finished_player(_anim_name: StringName) -> void:
	_on_animation_finished()

func reset_properties() -> void:
	damage_modifier = 0
	poison_ticks = 0

func setup(hp: int, n_name: String, _texture: Texture2D = null) -> void:
	reset_properties()
	max_health = hp
	current_health = hp
	enemy_name = n_name
	
	# Handle specific sprite nodes (Frosty, Darky, etc.)
	active_sprite = null
	for child in get_children():
		if child is AnimatedSprite2D:
			child.hide()
			if child.name == n_name:
				active_sprite = child
	
	if active_sprite:
		active_sprite.show()
		if active_sprite.sprite_frames.has_animation("idle"):
			active_sprite.play("idle")
		if not active_sprite.animation_finished.is_connected(_on_animation_finished):
			active_sprite.animation_finished.connect(_on_animation_finished)
	
	# Fallback to Sprite2D if no specific AnimatedSprite2D is found
	if has_node("Sprite2D"):
		var sprite = get_node("Sprite2D")
		if active_sprite:
			sprite.hide()
		else:
			sprite.show()
			if _texture != null:
				sprite.texture = _texture
		
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
	is_attacking = true
	original_position = position
	
	if has_node("AnimationPlayer") and $AnimationPlayer.has_animation("attack"):
		$AnimationPlayer.play("attack")
		SoundManager.play_sfx(SoundManager.SFX_E1SLASH)
	elif active_sprite and active_sprite.sprite_frames.has_animation("attack"):
		active_sprite.play("attack")
		SoundManager.play_sfx(SoundManager.SFX_E1SLASH)

func play_hit() -> void:
	if has_node("AnimationPlayer") and $AnimationPlayer.has_animation("hit"):
		$AnimationPlayer.play("hit")
	elif active_sprite and active_sprite.sprite_frames.has_animation("hit"):
		active_sprite.play("hit")
	SoundManager.play_sfx(SoundManager.SFX_E1HIT)

func play_death() -> void:
	if has_node("AnimationPlayer") and $AnimationPlayer.has_animation("death"):
		$AnimationPlayer.play("death")
	elif active_sprite and active_sprite.sprite_frames.has_animation("death"):
		active_sprite.play("death")
	else:
		# Fallback: simple fade out
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 1.0)
		tween.tween_callback(hide)
	SoundManager.play_sfx(SoundManager.SFX_E1DEATH)

func _on_animation_finished() -> void:
	if active_sprite:
		var current_anim: StringName = active_sprite.animation
		if current_anim == "attack":
			is_attacking = false
			position = original_position
			if active_sprite.sprite_frames.has_animation("idle"):
				active_sprite.play("idle")
		elif current_anim == "hit":
			if active_sprite.sprite_frames.has_animation("idle"):
				active_sprite.play("idle")
		elif current_anim == "death":
			hide()

func process_curse_turn() -> void:
	if poison_ticks > 0:
		take_damage(poison_damage)
		poison_ticks -= 1
