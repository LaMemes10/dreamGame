extends CharacterBody3D

var player = null
var hp = 100.0

const SPEED = 4.0
const ATTACK_RANGE = 2.0
const DAMAGE = 10.0

@export var player_path : NodePath

@onready var nav_agent = $NavigationAgent3D

func _ready() -> void:
	player = get_node(player_path)

func _physics_process(delta : float) -> void:
	velocity = Vector3.ZERO
	
	nav_agent.set_target_position(player.global_position)
	var next_nav_point = nav_agent.get_next_path_position()
	velocity = (next_nav_point - global_position).normalized() * SPEED
	
	move_and_slide()
