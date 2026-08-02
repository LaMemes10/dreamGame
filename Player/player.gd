extends CharacterBody3D

var speed : float
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5
var mouse_sensitivity := 0.001
var current_ammo = 30

var is_crouching : bool = false

#Head bob variable.
const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var t_bob = 0.0

#Fov variables.
var BASE_FOV = 60
const FOV_CHANGE = 1.5

#Bullets.
var bullets = load("res://scenes/bullet.tscn")
var instance

@export var SPEED_DEFAULT : float = 5.0
@export var SPEED_CROUCH : float = 2.0
@export var max_ammo = 120
@export var health = 100.0
@export var animation_player : AnimationPlayer
@export_range(5, 10, 0.1) var crouch_speed : float = 7.0
@export var crouch_shapecast : Node3D
@export var TOGGLE_CROUCH : bool = true

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var gun_anim = $Head/Camera3D/Wep_AK47/AnimationPlayer
@onready var gun_barrel = $Head/Camera3D/Wep_AK47/RayCast3D

func _ready() -> void:
	#Get mouse input.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	speed = SPEED_DEFAULT
	
	#Add crouch check shapecast collision for CharacterBody3D node.
	crouch_shapecast.add_exception($".")

func _damage(damage: float) -> void:
	health -= damage

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file("res://scenes/mainMenu.tscn")

#Camera movement.
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	if event.is_action_pressed("crouch") and TOGGLE_CROUCH == true:
		toggle_crouch()
	
	#Hold to crouch.
	if event.is_action_pressed("crouch") and is_crouching == false and TOGGLE_CROUCH == false:
		crouching(true)
	#Release to uncrouch.
	if event.is_action_released("crouch") and TOGGLE_CROUCH == false:
		if crouch_shapecast.is_colliding() == false:
			crouching(false)
		elif crouch_shapecast.is_colliding() == true:
			uncrouch_check()

func _physics_process(delta: float) -> void:
	#Show properties on debug panel from player.
	Global.debug.add_property("MovementSpeed", speed, 2)
	Global.debug.add_property("MouseRotationX", camera.rotation.x, 3); Global.debug.add_property("MouseRotationY", head.rotation.y, 4)
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and is_crouching == false:
		velocity.y = JUMP_VELOCITY
	
#Handle sprint.
	if is_crouching:
		speed = SPEED_CROUCH
	elif Input.is_action_pressed("sprint") and !is_crouching:
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, 0.0, delta * 7.0)
			velocity.z = lerp(velocity.z, 0.0, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	
#Head bob.
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
# FOV.
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + (FOV_CHANGE * velocity_clamped)
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
#Shooting.
	if Input.is_action_pressed("shoot"):
		if !gun_anim.is_playing():
			gun_anim.play("shoot")
			instance = bullets.instantiate()
			instance.position = gun_barrel.global_position
			instance.transform.basis = gun_barrel.global_transform.basis
			get_tree().root.add_child(instance)
	
	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

func toggle_crouch():
	if is_crouching == true and crouch_shapecast.is_colliding() == false:
		crouching(false)
	elif is_crouching == false:
		crouching(true)

func uncrouch_check():
	if crouch_shapecast.is_colliding() == false:
		crouching(false)
	if crouch_shapecast.is_colliding() == true:
		await get_tree().create_timer(0.1).timeout
		uncrouch_check()

func crouching(state : bool):
	is_crouching = state
	
	match state:
		true:
			animation_player.play("crouch", 0, crouch_speed)
			set_movement_speed("crouching")
		false:
			animation_player.play("crouch", 0, -crouch_speed, true)
			set_movement_speed("default")

#Set movement speed of player.
func set_movement_speed(state : String):
	match state:
		"default":
			speed = SPEED_DEFAULT
		"crouching":
			speed = SPEED_CROUCH
