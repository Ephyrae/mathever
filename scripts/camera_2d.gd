extends Camera2D

@export var randomStrength: float = 7.0
@export var shakeFade: float = 10
@export var triple_shake_delays: Array[float] = [0.0, 0.4, 0.9]

var rng = RandomNumberGenerator.new()

var shake_strength: float = 0.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func apply_shake() -> void:
	shake_strength = randomStrength

func apply_triple_shake() -> void:
	for delay: float in triple_shake_delays:
		if delay > 0:
			await get_tree().create_timer(delay).timeout
		apply_shake()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength,0,shakeFade * delta)
		
		offset = randomOffset()
		if shake_strength < 0.1:
			shake_strength = 0.0
			offset = Vector2.ZERO

func randomOffset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strength,shake_strength),rng.randf_range(-shake_strength,shake_strength))
