extends CenterContainer

@export var RETICLE_LINES : Array[Line2D]
@export var PLAYER_CONTROLLER : CharacterBody3D
@export var RETICLE_SPEED : float = 0.25
@export var RETICLE_DISTANCE : float = 2.0
@export var DOT_RADIUS : float = 1.0
@export var DOT_COLOR : Color = Color.WHITE

func _ready():
	queue_redraw()

func _process(delta):
	adjust_redicle_lines()

func _draw():
	draw_circle(Vector2(0, 0), DOT_RADIUS, DOT_COLOR)

func adjust_redicle_lines():
	var vel = PLAYER_CONTROLLER.get_real_velocity()
	var origin = Vector3(0, 0, 0)
	var pos = Vector2(0, 0)
	var speed = origin.distance_to(vel)

#Adjust reticle line position.
	var offsets := [
	Vector2(0, -1),  # Top
	Vector2(-1, 0),  # Left
	Vector2(0, 1),   # Bottom
	Vector2(1, 0)    # Right
]

	for i in RETICLE_LINES.size():
		var target = pos + offsets[i] * speed * RETICLE_DISTANCE
		RETICLE_LINES[i].position = lerp(RETICLE_LINES[i].position, target, RETICLE_SPEED)
