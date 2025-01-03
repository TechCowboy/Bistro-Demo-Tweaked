extends CharacterBody3D

@export_category("Extra Options")
@export var enable_physics_gun: bool = false
@export var enable_depth_of_field: bool = false
@export var disable_shadow_in_first_person: bool = false
@export var enable_audio: bool = false
@export var flashlight_intensity: float = 1.0

# --- Stuff you might be interested in tweaking ---
const LOOK_SENSITIVITY = 0.0025
const ZOOM_SENSITIVITY_MULTIPLIER = 0.5
const JOYSTICK_LOOK_MULTIPLIER = 1300.0
const MOVE_MULT = 1.4
const RUN_MULT = 1.25
const FP_FOV = 75.0
const TP_FOV = 60.0
const ZOOM_MULT = 0.35
const DOF_AREA_SOFTNESS = 1.15
const DOF_AREA_SIZE_MULTIPLIER = 0.0
const DOF_MAX_RANGE = 1000.0
const FLASHLIGHT_ANGLE = 35.0
# WARNING: in Godot Jolt physics damping seems to have inconsistent behavior between different physics tick rates
const PHYSICS_GUN_DAMPING = 30.0
const PHYSICS_GUN_PULL_FORCE = 800.0
const PHYSICS_GUN_SHOOT_FORCE = 13.0
const PHYSICS_GUN_HOLD_DISTANCE = 2.5
const PHYSICS_GUN_PULL_RANGE = 15.0
# --- Stuff you might be interested in tweaking ---

const FP_CAMERA_HEIGHT = 1.655
const TP_CAMERA_HEIGHT = 1.544
const TP_CAMERA_OFFSET = 0.5
const TP_CAMERA_DISTANCE = 2.1
const FLASHLIGHT_DISTANCE_FROM_MODEL = 0.35
const TRANSITION_SPEED = 0.25
const LOOK_LIMIT_UPPER = 1.25
const LOOK_LIMIT_LOWER = -1.25
const ANIM_MOVE_SPEED = 3.0
const ANIM_RUN_SPEED = 5.5
const JUMP_LAND_TIMEOUT = 0.1
const NOCLIP_MULT = 4.0
const ROTATE_SPEED = 12.0
const STEP_HEIGHT = 0.25
const JUMP_FORCE = 15.0
const GRAVITY_FORCE = 50.0
# 285 seems to be enough to move a max of 200kg
const COLLIDE_FORCE = 200.0
const MAX_PUSHABLE_WEIGHT = 200.0
const PHYSICS_GUN_PULL_MARGIN = 2.0
const PHYSICS_GUN_PULL_WIDTH = 0.8
const TOGGLE_COOLDOWN = 0.25
const DOF_MOVE_SPEED = 30.0
const DOF_INTENSITY = 0.25
const BUMP_AUDIO_TIMEOUT = 0.15
const BUMP_AUDIO_FORCE_THRESHOLD = 400.0
const BUMP_AUDIO_VOLUME_DB = -20.0
const BUMP_AUDIO_ATTENUATION_THRESHOLD = 0.2

var move_direction = Vector3.ZERO
var move_direction_no_y = Vector3.ZERO
var camera_rotation = Quaternion.IDENTITY
var camera_rotation_no_y = Quaternion.IDENTITY
var is_off_floor_duration = 0.0
var is_on_floor_duration = 0.0
var has_landed_from_fall = false
var boot_sound_timeout = true
var noclip_on = false
var noclip_toggle_cooldown = 0.0
var flashlight_on = false
var flashlight_toggle_cooldown = 0.0
var sprint_on = false
var sprint_toggle_cooldown = 0.0
var previous_sprint_isdown = false
var cam_is_fp = false
var cam_toggle_cooldown = 0.0
var cam_is_zoomed = false
var cam_zoom_cooldown = 0.0
var dof_target_distance = 0.0
var dof_amount_to_apply = 0.0
var shoulder_is_swapped = false
var shoulder_cooldown = 0.0
var mousecapture_on = true
var mousecapture_toggle_cooldown = 0.0
var physics_gun_cooldown = 0.0
var is_cam_transitioning = false
var input_velocity = Vector3.ZERO
var orig_transform = Transform3D.IDENTITY
var rigidbody_collisions = []
var colliders_in_contact = []
var collider_bump_cooldowns = []
var physics_gun_has_grabbed = false
var physics_gun_object = null
var physics_gun_object_linear_damp = 0.0
var physics_gun_object_angular_damp = 0.0
var physics_gun_hit_point = Vector3.ZERO

var look_movement = Vector2.ZERO
var mouse_look = Vector2.ZERO
var joystick_look = Vector2.ZERO
var joystick_move = Vector2.ZERO
var forward_isdown = false
var backward_isdown = false
var left_isdown = false
var right_isdown = false
var cam_toggle_isdown = false
var noclip_isdown = false
var flashlight_isdown = false
var sprint_isdown = false
var jump_isdown = false
var mousecapture_isdown = false
var zoom_isdown = false
var shoulder_isdown = false
var physics_gun_fire_isdown = false

@onready var model_root = $"ModelRoot"
@onready var anim_player = $"ModelRoot/HumanModel/AnimationPlayer"
@onready var player_mesh = $"ModelRoot/HumanModel/root/Skeleton3D/mannequiny"
@onready var collision_shape = $"CollisionShape"
@onready var camera_pivot = $"CameraPivot"
@onready var spring_arm = $"CameraPivot/SpringArm"
@onready var camera = $"CameraPivot/SpringArm/Camera"
@onready var focus_ray = $"CameraPivot/SpringArm/Camera/RayCast3D"
@onready var audio_listener = $"CameraPivot/SpringArm/Camera/AudioListener3D"
@onready var right_footstep = $"ModelRoot/HumanModel/root/Skeleton3D/RightFootLocation/FootstepPlayer"
@onready var left_footstep = $"ModelRoot/HumanModel/root/Skeleton3D/LeftFootLocation/FootstepPlayer"
@onready var jump_land_audio = $"ModelRoot/JumpLandPlayer"
@onready var physics_object_collector = $"CameraPivot/SpringArm/PhysicsGun/PhysicsObjectCollector"
@onready var physics_object_collector_collider = $"CameraPivot/SpringArm/PhysicsGun/PhysicsObjectCollector/CollisionShape3D"
@onready var physics_gun_raycast = $"CameraPivot/SpringArm/PhysicsGun/RayCast3D"
@onready var flashlight_pin = $"ModelRoot/HumanModel/root/Skeleton3D/FlashlightPin/FlashlightOffset"
@onready var flashlight = $"ModelRoot/HumanModel/root/Skeleton3D/FlashlightPin/FlashlightOffset/SpotLight3D"

@onready var bump_audio = load("res://Godot-Human-For-Scale/Assets/BumpAudio.tscn")

@onready var footstep_sounds = [
	load("res://Godot-Human-For-Scale/Assets/Audio/Footstep1.wav"),
	load("res://Godot-Human-For-Scale/Assets/Audio/Footstep2.wav"),
	load("res://Godot-Human-For-Scale/Assets/Audio/Footstep3.wav"),
	load("res://Godot-Human-For-Scale/Assets/Audio/Footstep4.wav")
	]

@onready var bump_sounds = [
	load("res://Godot-Human-For-Scale/Assets/Audio/Bump1.wav"),
	load("res://Godot-Human-For-Scale/Assets/Audio/Bump2.wav"),
	load("res://Godot-Human-For-Scale/Assets/Audio/Bump3.wav")
	]

func _ready():
	var y_rotation = Vector3(0.0, global_rotation.y, 0.0)
	
	global_rotation = Vector3.ZERO
	
	physics_object_collector_collider.shape.height = PHYSICS_GUN_PULL_RANGE
	physics_object_collector_collider.shape.radius = PHYSICS_GUN_PULL_WIDTH
	physics_object_collector_collider.position.z = -(PHYSICS_GUN_PULL_RANGE/2)
	physics_gun_raycast.target_position.z = -PHYSICS_GUN_PULL_RANGE
	
	camera_pivot.global_rotation = y_rotation
	model_root.global_rotation = y_rotation
	camera_rotation = Quaternion.from_euler(camera_pivot.global_rotation)
	camera_rotation_no_y = Quaternion.from_euler(camera_pivot.global_rotation)
	
	flashlight.light_energy = flashlight_intensity
	flashlight.spot_angle = FLASHLIGHT_ANGLE
	
	camera.make_current()
	
	if enable_depth_of_field:
		hijack_camera_attributes()
	
	if enable_audio:
		audio_listener.make_current()
	
	await get_tree().create_timer(0.25).timeout
	boot_sound_timeout = false

func _process(delta):
	process_camera(delta)
	process_off_on_floor_time(delta)
	process_movement()
	process_animation(delta)
	process_mousecapture(delta)
	process_noclip(delta)
	process_flashlight(delta)
	process_sprint(delta)
	process_cam_toggle(delta)
	process_cam_zoom(delta)
	process_shoulder_swap(delta)
	process_physics_gun_fire(delta)
	process_dof(delta)
	
	var move_speed = ANIM_MOVE_SPEED * MOVE_MULT
	if sprint_on:
		move_speed = ANIM_RUN_SPEED * RUN_MULT
	
	if noclip_on:
		velocity = move_direction * (move_speed * NOCLIP_MULT)
	else:
		velocity.x = move_direction_no_y.x * move_speed 
		velocity.z = move_direction_no_y.z * move_speed
		if !is_on_floor():
			velocity.y -= GRAVITY_FORCE * delta
		if jump_isdown and is_on_floor():
			velocity.y = JUMP_FORCE
			play_jump_land_sound()
	
	if is_on_floor_duration >= JUMP_LAND_TIMEOUT and !has_landed_from_fall:
		has_landed_from_fall = true
		play_jump_land_sound()
	if is_off_floor_duration >= JUMP_LAND_TIMEOUT and has_landed_from_fall:
		has_landed_from_fall = false
	
	input_velocity = velocity
	orig_transform = global_transform
	
	move_and_slide()
	
	rigidbody_collisions = []
	
	var has_stairstepped = stairstepping(orig_transform, delta)
	
	# Rigidbody interactions don't play nice with stairstepping ☹️
	if !has_stairstepped:
		collate_rigidbody_interactions()
	
	flashlight.global_position = flashlight_pin.global_position
	var backwards = Basis(camera_rotation_no_y).z
	var up = flashlight_pin.global_basis.y
	var right = up.cross(backwards)
	flashlight.global_basis = Basis(right, up, right.cross(up)).orthonormalized()
	flashlight.position = flashlight.position + (-flashlight.basis.z * FLASHLIGHT_DISTANCE_FROM_MODEL)
	flashlight.global_rotation = camera_pivot.global_rotation

func _physics_process(delta):
	process_physics_gun(delta)
	
	var collide_force = COLLIDE_FORCE * delta
	var central_multiplier = input_velocity.length() * collide_force
	
	var collider_indexes_still_in_contact = []
	var colliders_still_in_contact = []
	var non_expired_cooldowns = []
	
	for collision in rigidbody_collisions:
		if collision.get_collider() == null:
			continue
		var collider = collision.get_collider()
		var weight = collider.mass
		var direction = -collision.get_normal()
		var mult_actual = lerp(0.0, central_multiplier, ease_out_circ(clamp(weight/MAX_PUSHABLE_WEIGHT, 0.0, 1.0)))
		
		collider.apply_central_impulse(direction * mult_actual)
		collider_indexes_still_in_contact.append(colliders_in_contact.find(collider))
		
		if !colliders_in_contact.has(collider):
			colliders_in_contact.append(collider)
			var volume_scale = mult_actual/(BUMP_AUDIO_FORCE_THRESHOLD * delta)
			if volume_scale > BUMP_AUDIO_ATTENUATION_THRESHOLD:
				var has_collider = false
				for cooldown in collider_bump_cooldowns:
					if cooldown["collider"] != null and cooldown["collider"] == collider:
						has_collider = true
						break
				if !has_collider:
					play_bump_audio(collision.get_position(), volume_scale)
					var cooldown = {"collider": collider, "cooldown": BUMP_AUDIO_TIMEOUT}
					collider_bump_cooldowns.append(cooldown)
	
	for index in collider_indexes_still_in_contact:
		colliders_still_in_contact.append(colliders_in_contact[index])
	
	colliders_in_contact = colliders_still_in_contact
	
	for cooldown in collider_bump_cooldowns:
		cooldown["cooldown"] -= delta
	
	for cooldown in collider_bump_cooldowns:
		if cooldown["cooldown"] > 0.0:
			non_expired_cooldowns.append(cooldown)
	
	collider_bump_cooldowns = non_expired_cooldowns

func stairstepping(starting_transform, delta):
	if (input_velocity.x == 0 and input_velocity.z == 0) or noclip_on or !is_on_floor() or !is_on_wall():
		return false
	
	var collision_out = KinematicCollision3D.new()
	var begin_transform = starting_transform
	var test_direction = Vector3.UP * STEP_HEIGHT
	# Test to above current position
	var can_not_step = test_move(begin_transform, test_direction)
	
	if can_not_step:
		return false
	
	begin_transform.origin = begin_transform.origin + test_direction
	test_direction = Vector3(input_velocity.x, 0, input_velocity.z) * delta
	# Then, test towards player's direction running into wall
	can_not_step = test_move(begin_transform, test_direction)
	
	if can_not_step:
		return false
	
	begin_transform.origin = begin_transform.origin + test_direction
	test_direction = Vector3.DOWN * STEP_HEIGHT
	# Then, test downwards
	can_not_step = test_move(begin_transform, test_direction, collision_out)
	
	if can_not_step:
		# If we hit something, teleport towards hit location
		begin_transform.origin = begin_transform.origin + collision_out.get_travel()
	else:
		# If we hit nothing, teleport back to original height
		begin_transform.origin = begin_transform.origin + test_direction
	
	# Without the buffer the player can fail to make steps, especially at higher framerates
	var step_landing_buffer = floor_snap_length - safe_margin
	begin_transform.origin = begin_transform.origin + (Vector3.UP * step_landing_buffer)
	global_transform = begin_transform
	return true

func collate_rigidbody_interactions():
	for index in get_slide_collision_count():
		if get_slide_collision(index) == null:
			continue
		var collision = get_slide_collision(index)
		if collision.get_collider() is RigidBody3D:
			rigidbody_collisions.append(collision)

func _on_right_footstep():
	if !enable_audio:
		return
	right_footstep.stream = footstep_sounds.pick_random()
	right_footstep.play()

func _on_left_footstep():
	if !enable_audio:
		return
	left_footstep.stream = footstep_sounds.pick_random()
	left_footstep.play()

func play_jump_land_sound():
	if !enable_audio or boot_sound_timeout:
		return
	if !left_footstep.playing or !right_footstep.playing:
		jump_land_audio.stream = footstep_sounds.pick_random()
		jump_land_audio.play()

func play_bump_audio(global_audio_position, volume_scale):
	if !enable_audio:
		return
	var spawned_bump_audio = bump_audio.instantiate()
	get_tree().root.get_child(0).add_child(spawned_bump_audio)
	spawned_bump_audio.global_position = global_audio_position
	spawned_bump_audio.stream = bump_sounds.pick_random()
	volume_scale = clamp(volume_scale, 0.0, 1.0)
	spawned_bump_audio.volume_db = lerp(-80.0, BUMP_AUDIO_VOLUME_DB, ease_out_circ(volume_scale))
	spawned_bump_audio.play()
	await get_tree().create_timer(0.5).timeout
	spawned_bump_audio.queue_free()

func process_off_on_floor_time(delta):
	if is_on_floor():
		is_on_floor_duration += delta
		is_off_floor_duration = 0.0
	else:
		is_on_floor_duration = 0.0
		is_off_floor_duration += delta
	is_on_floor_duration = clamp(is_on_floor_duration, 0.0, JUMP_LAND_TIMEOUT)
	is_off_floor_duration = clamp(is_off_floor_duration, 0.0, JUMP_LAND_TIMEOUT)

func process_camera(delta):
	look_movement -= (map_square_to_circle(joystick_look) * delta) * JOYSTICK_LOOK_MULTIPLIER
	look_movement -= mouse_look
	
	if cam_is_zoomed:
		look_movement = look_movement * ZOOM_SENSITIVITY_MULTIPLIER
	
	var camera_rotation_euler = camera_rotation.get_euler()
	
	if mousecapture_on:
		camera_rotation_euler += Vector3(look_movement.y, look_movement.x, 0.0) * LOOK_SENSITIVITY
		camera_rotation_euler.x = clamp(camera_rotation_euler.x, LOOK_LIMIT_LOWER, LOOK_LIMIT_UPPER)
	
	camera_rotation = Quaternion.from_euler(camera_rotation_euler)
	camera_pivot.global_basis = Basis(camera_rotation)
	camera_rotation_no_y = Basis(camera_pivot.global_basis.x, Vector3.UP, camera_pivot.global_basis.z).get_rotation_quaternion()
	
	mouse_look = Vector2.ZERO
	look_movement = Vector2.ZERO

func process_movement():
	var input_direction = Vector3.ZERO
	
	if forward_isdown:
		input_direction.z -= 1.0
	if backward_isdown:
		input_direction.z += 1.0
	if left_isdown:
		input_direction.x -= 1.0
	if right_isdown:
		input_direction.x += 1.0
	
	input_direction.z += map_square_to_circle(joystick_move).y
	input_direction.x += map_square_to_circle(joystick_move).x
	
	move_direction = camera_rotation * input_direction
	move_direction_no_y = camera_rotation_no_y * input_direction
	move_direction = move_direction.normalized()
	move_direction_no_y = move_direction_no_y.normalized()

func process_animation(delta):
	if is_off_floor_duration >= JUMP_LAND_TIMEOUT:
		switch_anim("Fall")
	elif move_direction != Vector3.ZERO:
		if sprint_on:
			switch_anim("Run", RUN_MULT)
		else:
			switch_anim("Jog", MOVE_MULT)
	else:
		switch_anim("Idle")
	
	if move_direction != Vector3.ZERO:
		model_root.global_basis = basis_rotate_toward(model_root.global_basis, Basis.looking_at(move_direction_no_y), ROTATE_SPEED * delta)

func process_mousecapture(delta):
	if mousecapture_isdown and mousecapture_toggle_cooldown == 0.0:
		mousecapture_on = !mousecapture_on
		mousecapture_toggle_cooldown = TOGGLE_COOLDOWN
	
	if mousecapture_on:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	mousecapture_toggle_cooldown -= delta
	mousecapture_toggle_cooldown = clamp(mousecapture_toggle_cooldown, 0.0, TOGGLE_COOLDOWN)

func process_noclip(delta):
	if noclip_isdown and noclip_toggle_cooldown == 0.0:
		noclip_on = !noclip_on
		collision_shape.disabled = !collision_shape.disabled
		noclip_toggle_cooldown = TOGGLE_COOLDOWN
	
	noclip_toggle_cooldown -= delta
	noclip_toggle_cooldown = clamp(noclip_toggle_cooldown, 0.0, TOGGLE_COOLDOWN)

func process_flashlight(delta):
	if flashlight_isdown and flashlight_toggle_cooldown == 0.0:
		flashlight_on = !flashlight_on
		flashlight.visible = flashlight_on
		flashlight_toggle_cooldown = TOGGLE_COOLDOWN
	
	flashlight_toggle_cooldown -= delta
	flashlight_toggle_cooldown = clamp(flashlight_toggle_cooldown, 0.0, TOGGLE_COOLDOWN)

func process_sprint(delta):
	if move_direction == Vector3.ZERO:
		sprint_on = false
	
	if sprint_isdown and sprint_toggle_cooldown == 0.0 and !previous_sprint_isdown:
		if move_direction != Vector3.ZERO:
			sprint_on = !sprint_on
		
		sprint_toggle_cooldown = TOGGLE_COOLDOWN
	
	previous_sprint_isdown = sprint_isdown
	sprint_toggle_cooldown -= delta
	sprint_toggle_cooldown = clamp(sprint_toggle_cooldown, 0.0, TOGGLE_COOLDOWN)

func process_cam_toggle(delta):
	if cam_toggle_isdown and cam_toggle_cooldown == 0.0 and !is_cam_transitioning:
		cam_is_fp = !cam_is_fp
		cam_toggle_cooldown = TOGGLE_COOLDOWN
		cam_transition()
	
	cam_toggle_cooldown -= delta
	cam_toggle_cooldown = clamp(cam_toggle_cooldown, 0.0, TOGGLE_COOLDOWN)

func process_cam_zoom(delta):
	if !mousecapture_on:
		return
	
	if zoom_isdown and cam_zoom_cooldown == 0.0 and !is_cam_transitioning:
		cam_is_zoomed = !cam_is_zoomed
		cam_zoom_cooldown = TOGGLE_COOLDOWN
		cam_transition()
	
	cam_zoom_cooldown -= delta
	cam_zoom_cooldown = clamp(cam_zoom_cooldown, 0.0, TOGGLE_COOLDOWN)

func process_shoulder_swap(delta):
	if shoulder_isdown and !cam_is_fp and shoulder_cooldown == 0.0 and !is_cam_transitioning:
		shoulder_is_swapped = !shoulder_is_swapped
		shoulder_cooldown = TOGGLE_COOLDOWN
		cam_transition()
	
	shoulder_cooldown -= delta
	shoulder_cooldown = clamp(shoulder_cooldown, 0.0, TOGGLE_COOLDOWN)

func process_physics_gun_fire(delta):
	if !enable_physics_gun or !mousecapture_on:
		return
	
	if physics_gun_fire_isdown and physics_gun_cooldown == 0.0:
		if physics_gun_has_grabbed:
			fire_physics_gun()
		else:
			grab_physics_gun()
		physics_gun_cooldown = TOGGLE_COOLDOWN
	
	physics_gun_cooldown -= delta
	physics_gun_cooldown = clamp(physics_gun_cooldown, 0.0, TOGGLE_COOLDOWN)

func grab_physics_gun():
	var rigidbodies_detected = []
	
	for node in physics_object_collector.get_overlapping_bodies():
		if node is RigidBody3D:
			rigidbodies_detected.append(node)
	
	if physics_gun_raycast.is_colliding():
		physics_gun_hit_point = physics_gun_raycast.get_collision_point()
	else:
		physics_gun_hit_point = spring_arm.global_position
	
	rigidbodies_detected.sort_custom(rigidbody_distance_sort)
	
	if rigidbodies_detected.size() == 0 or rigidbodies_detected[0] == null:
		return
	
	physics_gun_object = rigidbodies_detected[0]
	
	physics_gun_object_linear_damp = physics_gun_object.linear_damp
	physics_gun_object_angular_damp = physics_gun_object.angular_damp
	physics_gun_object.linear_damp = PHYSICS_GUN_DAMPING
	physics_gun_object.angular_damp = PHYSICS_GUN_DAMPING
	
	physics_gun_has_grabbed = true

func rigidbody_distance_sort(rigidbody_a, rigidbody_b):
	if physics_gun_hit_point.distance_to(rigidbody_a.global_position) < physics_gun_hit_point.distance_to(rigidbody_b.global_position):
		return true
	else:
		return false

func fire_physics_gun():
	physics_gun_has_grabbed = false
	
	physics_gun_object.linear_damp = physics_gun_object_linear_damp
	physics_gun_object.angular_damp = physics_gun_object_angular_damp
	
	physics_gun_object.linear_velocity = Vector3.ZERO
	physics_gun_object.angular_velocity = Vector3.ZERO
	physics_gun_object.constant_force = Vector3.ZERO
	
	physics_gun_object.apply_central_impulse(-camera_pivot.basis.z * (PHYSICS_GUN_SHOOT_FORCE * physics_gun_object.mass))

func process_physics_gun(delta):
	if !enable_physics_gun or !physics_gun_has_grabbed:
		return
	
	if physics_gun_object == null:
		physics_gun_has_grabbed = false
		return
	
	var physics_gun_hold_location = camera_pivot.global_position + (-camera_pivot.global_basis.z * PHYSICS_GUN_HOLD_DISTANCE)
	
	var lerp_force = physics_gun_hold_location.distance_to(physics_gun_object.global_position) / PHYSICS_GUN_PULL_MARGIN
	lerp_force = clamp(lerp_force, 0.0, 1.0)
	
	var physics_gun_suck = physics_gun_object.global_position.direction_to(physics_gun_hold_location) * PHYSICS_GUN_PULL_FORCE
	physics_gun_suck = physics_gun_suck * physics_gun_object.mass
	physics_gun_suck = lerp(Vector3.ZERO, physics_gun_suck, lerp_force)
	
	physics_gun_object.constant_force = physics_gun_suck

func cam_transition():
	if is_cam_transitioning:
		return
	
	var fov
	var offset
	
	if cam_is_zoomed:
		if cam_is_fp:
			fov = FP_FOV * ZOOM_MULT
		else:
			fov = TP_FOV * ZOOM_MULT
	else:
		if cam_is_fp:
			fov = FP_FOV
		else:
			fov = TP_FOV
	
	if shoulder_is_swapped:
		offset = -TP_CAMERA_OFFSET
	else:
		offset = TP_CAMERA_OFFSET
	
	if cam_is_fp:
		cam_transitioning(FP_CAMERA_HEIGHT, 0.0, 0.0, fov, false)
	else:
		cam_transitioning(TP_CAMERA_HEIGHT, offset, TP_CAMERA_DISTANCE, fov, true)

func cam_transitioning(height, offset, length, fov, mesh_visible):
	is_cam_transitioning = true
	
	var time = Time.get_ticks_msec()
	var orig_height = camera_pivot.position.y
	var orig_offset = spring_arm.position.x
	var orig_length = spring_arm.spring_length
	var orig_fov = camera.fov
	
	if mesh_visible:
		if disable_shadow_in_first_person:
			player_mesh.visible = true
		else:
			player_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	
	while is_cam_transitioning:
		var current_time = Time.get_ticks_msec()
		var lerp = (current_time - time)/(TRANSITION_SPEED * 1000.0)
		
		if lerp >= 1.0:
			camera_pivot.position.y = height
			spring_arm.position.x = offset
			spring_arm.spring_length = length
			camera.fov = fov
			if !mesh_visible:
				if disable_shadow_in_first_person:
					player_mesh.visible = false
				else:
					player_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			is_cam_transitioning = false
			break
		
		camera_pivot.position.y = lerp(orig_height, height, ease_in_out_sine(lerp))
		spring_arm.position.x = lerp(orig_offset, offset, ease_in_out_sine(lerp))
		# Adjusting spring_length is jittery. Likely only updates on physics process.
		spring_arm.spring_length = lerp(orig_length, length, lerp)
		# So if you're noticing jitter when switching cams, ^ this lerp is responsible.
		camera.fov = lerp(orig_fov, fov, ease_in_out_sine(lerp))
		
		await get_tree().process_frame

func process_dof(delta):
	if camera.attributes == null or !enable_depth_of_field:
		return
	
	var target_distance = DOF_MAX_RANGE
	if focus_ray.is_colliding():
		target_distance = camera.global_position.distance_to(focus_ray.get_collision_point())
	var blur_amount = DOF_INTENSITY
	if !cam_is_zoomed:
		blur_amount = 0.0
	var distance_multiplier = 0.75
	var coming_back_bonus_multiplier = 3.4
	if target_distance < dof_target_distance:
		distance_multiplier = distance_multiplier * coming_back_bonus_multiplier
	var distance_additional = abs(dof_target_distance - target_distance)
	distance_additional = distance_additional * distance_multiplier
	var adjusted_dof_move_speed = DOF_MOVE_SPEED + distance_additional
	
	dof_target_distance = move_toward(dof_target_distance, target_distance, adjusted_dof_move_speed * delta)
	dof_amount_to_apply = move_toward(dof_amount_to_apply, blur_amount, 0.45 * delta)
	
	camera.attributes.dof_blur_near_distance = dof_target_distance - (dof_target_distance * DOF_AREA_SIZE_MULTIPLIER)
	camera.attributes.dof_blur_near_transition = dof_target_distance * DOF_AREA_SOFTNESS
	camera.attributes.dof_blur_far_distance =  dof_target_distance + (dof_target_distance * DOF_AREA_SIZE_MULTIPLIER)
	camera.attributes.dof_blur_far_transition = dof_target_distance * DOF_AREA_SOFTNESS
	
	if dof_amount_to_apply < 0.001:
		camera.attributes.dof_blur_far_enabled = false
		camera.attributes.dof_blur_near_distance = 0.5
		camera.attributes.dof_blur_near_transition = 0.25
		camera.attributes.dof_blur_amount = 0.1
	else:
		camera.attributes.dof_blur_far_enabled = true
		camera.attributes.dof_blur_amount = dof_amount_to_apply

func hijack_camera_attributes():
	var cams_or_envs = []
	cams_or_envs += get_tree().current_scene.find_children("*", "Camera3D", true)
	cams_or_envs += get_tree().current_scene.find_children("*", "WorldEnvironment", true)
	var hijacked_attributes = null
	
	for node in cams_or_envs:
		if node is Camera3D:
			if node.attributes != null:
				hijacked_attributes = node.attributes
				break
		if node is WorldEnvironment:
			if node.camera_attributes != null:
				hijacked_attributes = node.camera_attributes
				break
	
	camera.attributes = assert_practical_attributes(hijacked_attributes)
	
	camera.attributes.dof_blur_near_enabled = true
	focus_ray.target_position.z = -DOF_MAX_RANGE

func assert_practical_attributes(attributes):
	var practical_attributes = CameraAttributesPractical.new()
	
	if attributes != null:
		if attributes is CameraAttributesPractical:
			practical_attributes = attributes
		else:
			push_warning("CameraAttributesPhysical not supported. Making a CameraAttributesPractical duplicate for Godot-Human-For-Scale's camera.")
			practical_attributes.auto_exposure_enabled = attributes.auto_exposure_enabled
			practical_attributes.auto_exposure_scale = attributes.auto_exposure_scale
			practical_attributes.auto_exposure_speed = attributes.auto_exposure_speed
			practical_attributes.exposure_multiplier = attributes.exposure_multiplier
			practical_attributes.exposure_sensitivity = attributes.exposure_sensitivity
	
	return practical_attributes

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		mouse_look = event.relative
	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				physics_gun_fire_isdown = event.pressed
			MOUSE_BUTTON_RIGHT:
				zoom_isdown = event.pressed
	
	if event is InputEventKey:
		match event.keycode:
			KEY_W:
				forward_isdown = event.pressed
			KEY_S:
				backward_isdown = event.pressed
			KEY_A:
				left_isdown = event.pressed
			KEY_D:
				right_isdown = event.pressed
			KEY_V:
				cam_toggle_isdown = event.pressed
			KEY_F:
				flashlight_isdown = event.pressed
			KEY_QUOTELEFT:
				noclip_isdown = event.pressed
			KEY_SHIFT:
				sprint_isdown = event.pressed
			KEY_SPACE:
				jump_isdown = event.pressed
			KEY_ESCAPE:
				mousecapture_isdown = event.pressed
			KEY_TAB:
				shoulder_isdown = event.pressed
	
	if event is InputEventJoypadMotion:
		match event.axis:
			JOY_AXIS_LEFT_X:
				if event.axis_value > 0.55 or event.axis_value < -0.55:
					joystick_move.x = event.axis_value
				else:
					joystick_move.x = 0.0
			JOY_AXIS_LEFT_Y:
				if event.axis_value > 0.55  or event.axis_value < -0.55:
					joystick_move.y = event.axis_value
				else:
					joystick_move.y = 0.0
			JOY_AXIS_RIGHT_X:
				joystick_look.x = event.axis_value
			JOY_AXIS_RIGHT_Y:
				joystick_look.y = event.axis_value
			JOY_AXIS_TRIGGER_LEFT:
				if event.axis_value > 0.55:
					zoom_isdown = true
				else:
					zoom_isdown = false
			JOY_AXIS_TRIGGER_RIGHT:
				if event.axis_value > 0.55:
					physics_gun_fire_isdown = true
				else:
					physics_gun_fire_isdown = false
	
	if event is InputEventJoypadButton:
		match event.button_index:
			JOY_BUTTON_BACK:
				cam_toggle_isdown = event.pressed
			JOY_BUTTON_DPAD_DOWN:
				flashlight_isdown = event.pressed
			JOY_BUTTON_DPAD_UP:
				noclip_isdown = event.pressed
			JOY_BUTTON_LEFT_STICK:
				sprint_isdown = event.pressed
			JOY_BUTTON_A:
				jump_isdown = event.pressed
			JOY_BUTTON_START:
				mousecapture_isdown = event.pressed
			JOY_BUTTON_LEFT_SHOULDER:
				shoulder_isdown = event.pressed

func switch_anim(anim, speed = 1.0):
	if anim_player.current_animation != anim:
		anim_player.play(anim, -1, speed)

# oh god oh math oh fuck: https://raw.org/article/how-to-map-a-square-to-a-circle/
func map_square_to_circle(square: Vector2) -> Vector2:
	var circle = square
	circle.x = circle.x * sqrt(1.0 - (square.y * square.y / 2.0));
	circle.y = circle.y * sqrt(1.0 - (square.x * square.x / 2.0));
	return circle

func quat_rotate_toward(from: Quaternion, to: Quaternion, delta: float) -> Quaternion:
	return from.slerp(to, clamp(delta / from.angle_to(to), 0.0, 1.0)).normalized()

func basis_rotate_toward(from: Basis, to: Basis, delta: float) -> Basis:
	return Basis(quat_rotate_toward(from.get_rotation_quaternion(), to.get_rotation_quaternion(), delta)).orthonormalized()

func ease_in_out_sine(lerp: float) -> float:
	return -(cos(PI * lerp) - 1.0) / 2.0

func ease_out_circ(lerp: float) -> float:
	return sqrt(1.0 - pow(lerp - 1.0, 2.0))
