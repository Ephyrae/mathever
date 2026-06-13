extends Camera2D

@export var randomStrength: float = 7.0
@export var shakeFade: float = 10

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var shake_strength: float = 0.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func apply_shake() -> void:
	shake_strength = randomStrength

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
