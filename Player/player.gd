extends CharacterBody3D

@onready var camera_pivot = $CameraPivot
@onready var interaction_cast = %InteractionCast
@onready var footsteps: AudioStreamPlayer = $Footsteps

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var mouse_sensitivity := 0.003

var mouse_motion := Vector2.ZERO
var last_collider = null
var last_marker = 0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_motion = -event.relative * mouse_sensitivity
		
	if event.is_action_pressed("jump"):
		var markers = get_tree().get_nodes_in_group("marker")
		global_position = markers[last_marker].global_position
		last_marker += 1

func _physics_process(delta):
	handle_camera_rotation()
	check_interaction()

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	play_footsteps(input_dir)

func handle_camera_rotation():
	rotate_y(mouse_motion.x)
	camera_pivot.rotate_x(clampf(mouse_motion.y, -75, 75))
	camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, -PI/2, PI/2)
	mouse_motion = Vector2.ZERO
	
func check_interaction():
	if not interaction_cast.is_colliding():
		if last_collider != null:
			last_collider._being_targeted = false
		return

	var collider = interaction_cast.get_collider()
	if collider != null:
		collider._being_targeted = true
		last_collider = collider
		if Input.is_action_just_pressed("interact") and collider != null:
			printt('metadata:', collider.interactable_resource.popup_text)

func play_footsteps(input_dir):
	if not footsteps.playing and input_dir != Vector2.ZERO:
		footsteps.play()
