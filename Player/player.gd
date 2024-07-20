extends CharacterBody3D

signal died

@onready var camera_pivot = $CameraPivot
@onready var footsteps: AudioStreamPlayer = $Footsteps
@onready var zipline_ray_cast = %ZiplineRayCast
@onready var zipline_shapecast = $ZiplineShapecast
@onready var crosshair = %Crosshair
@onready var zipline_from = %ZiplineFrom

enum State {
	Idle,
	ZiplineStart,
	Zipline,
	Dead
}

const SPEED = 5.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var mouse_sensitivity := 0.003

var mouse_motion := Vector2.ZERO
var zipline_point := Vector3.ZERO
var state : State = State.Idle

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	state = State.Idle

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_motion = -event.relative * mouse_sensitivity
	
	check_zipline(event)
	set_zipline_marker(event)

func check_zipline(event: InputEvent) -> void:
	if event.is_action_pressed("zipline"):
		var point = zipline_ray_cast.get_collision_point()
		if global_position.y > point.y and zipline_ray_cast.is_colliding():
			zipline_point = point
			state = State.Zipline

func set_zipline_marker(event: InputEvent) -> void:
	if event.is_action_pressed("set_zip") and zipline_ray_cast.is_colliding():
		build_zipline(zipline_from.global_position, zipline_ray_cast.get_collision_point())
	
func build_zipline(from_point: Vector3, to_point: Vector3):
	var color := Color.WHITE_SMOKE
	var cylinder_mesh := CylinderMesh.new()
	var mesh_instance := MeshInstance3D.new()
	var material := ORMMaterial3D.new()
	
	#mesh_instance.mesh = immediate_mesh
	mesh_instance.mesh = cylinder_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	#immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	#immediate_mesh.surface_add_vertex(from_point)
	#immediate_mesh.surface_add_vertex(to_point)
	#
	#immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color

	#await final_cleanup(mesh_instance, -1)
	cylinder_mesh.height = from_point.distance_to(to_point)
	cylinder_mesh.top_radius = 0.08
	cylinder_mesh.bottom_radius = 0.08
	
	get_tree().get_root().add_child(mesh_instance)
	mesh_instance.position.z = -cylinder_mesh.height / 2
	mesh_instance.global_position = $CameraPivot/ZiplineFrom/DebugMesh.global_position
	mesh_instance.global_rotation = $CameraPivot/ZiplineFrom/DebugMesh.global_rotation

func _physics_process(delta: float):
	match state:
		State.Idle: 
			idle_state(delta)
		State.Zipline:
			zipline_state(delta)
		
func zipline_state(delta: float) -> void:
	handle_camera_rotation()
	var direction = global_position.direction_to(zipline_point)

	velocity += direction * 10 * delta
	move_and_slide()
	
	var diff = global_position - zipline_point
	
	if abs(diff.x) <= 0.5 and abs(diff.z) <= 0.5:
		velocity = Vector3.ZERO
		state = State.Idle
	
	if zipline_shapecast.is_colliding():
		velocity = Vector3.ZERO
		state = State.Idle

func idle_state(delta: float) -> void:
	handle_camera_rotation()

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
	
func play_footsteps(input_dir):
	if not footsteps.playing and input_dir != Vector2.ZERO:
		footsteps.play()

func player_died():
	died.emit()
	crosshair.visible = false
	state = State.Dead
