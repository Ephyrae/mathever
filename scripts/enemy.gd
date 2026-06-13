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

# Sound Placeholders - Set these in setup() or via CombatManager
var sfx_attack: Variant = ""
var sfx_hit: Variant = ""
var sfx_death: Variant = ""

var sfx_vol_attack: float = 0.0
var sfx_vol_hit: float = 0.0
var sfx_vol_death: float = 0.0

func _ready() -> void:
	reset_properties()
	if has_node("AnimationPlayer"):
		$AnimationPlayer.animation_finished.connect(_on_animation_finished_player)

func _on_animation_finished_player(_anim_name: StringName) -> void:
	_on_animation_finished()

var death_tween: Tween

func reset_properties() -> void:
	if death_tween and death_tween.is_valid():
		death_tween.kill()
	damage_modifier = 0
	poison_ticks = 0
	show()
	modulate.a = 1.0
	is_attacking = false

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
	elif active_sprite and active_sprite.sprite_frames.has_animation("attack"):
		active_sprite.play("attack")
	
	# attack sfx
	if sfx_attack != null and str(sfx_attack) != "":
		SoundManager.play_sfx(sfx_attack, sfx_vol_attack)

func play_hit() -> void:
	if has_node("AnimationPlayer") and $AnimationPlayer.has_animation("hit"):
		$AnimationPlayer.play("hit")
	elif active_sprite and active_sprite.sprite_frames.has_animation("hit"):
		active_sprite.play("hit")
	
	# hit sfx
	if sfx_hit != null and str(sfx_hit) != "":
		SoundManager.play_sfx(sfx_hit, sfx_vol_hit)

func play_death() -> void:
	if has_node("AnimationPlayer") and $AnimationPlayer.has_animation("death"):
		$AnimationPlayer.play("death")
	elif active_sprite and active_sprite.sprite_frames.has_animation("death"):
		active_sprite.play("death")
	else:
		# Fallback: simple fade out
		death_tween = create_tween()
		death_tween.tween_interval(2.0)
		death_tween.tween_property(self, "modulate:a", 0.0, 1.0)
		death_tween.tween_callback(hide)
	
	# death sfx
	if sfx_death != null and str(sfx_death) != "":
		SoundManager.play_sfx(sfx_death, sfx_vol_death)

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
			# Keep the final frame visible
			pass

func process_curse_turn() -> void:
	if poison_ticks > 0:
		take_damage(poison_damage)
		poison_ticks -= 1
