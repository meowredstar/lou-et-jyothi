extends CharacterBody3D

# Minimum speed of the mob in meters per second.
@export var min_speed = 10
# Maximum speed of the mob in meters per second.
@export var max_speed = 18

@export var min_turn_time = 1.0
@export var max_turn_time = 3.0

var turn_timer = 0.0
var area_center
var area_width
var current_speed


# Emitted when the player jumped on the mob.
signal squashed

func choose_random_direction():
	var target = Vector3(
		randf_range(area_center.x - area_width.x, area_center.x + area_width.x),
		global_position.y,
		randf_range(area_center.z - area_width.z, area_center.z + area_width.z)
	)

	look_at(target, Vector3.UP)
	velocity = Vector3.FORWARD * current_speed
	velocity = velocity.rotated(Vector3.UP, rotation.y)

	turn_timer = randf_range(min_turn_time, max_turn_time)

func _physics_process(_delta):
	
	turn_timer -= _delta

	if turn_timer <= 0:
		choose_random_direction()
	
	for body in $PreyDetector.get_overlapping_bodies():
		if body.is_in_group("prey") :
			velocity = velocity.rotated(Vector3.UP, -rotation.y)
			look_at(body.position)
			velocity = velocity.rotated(Vector3.UP, rotation.y)
			break
	move_and_slide()
	
	var min_x = area_center.x - area_width.x
	var max_x = area_center.x + area_width.x
	var min_z = area_center.z - area_width.z
	var max_z = area_center.z + area_width.z
	
	var touched_edge = false
	
	if global_position.x < min_x:
		global_position.x = min_x
		touched_edge = true
	elif global_position.x > max_x:
		global_position.x = max_x
		touched_edge = true
	
	if global_position.z < min_z:
		global_position.z = min_z
		touched_edge = true
	elif global_position.z > max_z:
		global_position.z = max_z
		touched_edge = true
	
	if touched_edge: 
		choose_random_direction()

	global_position.x = clamp(global_position.x, min_x, max_x)
	global_position.z = clamp(global_position.z, min_z, max_z)
	

# This function will be called from the Main scene.
func initialize(start_position, area_cente, area_widt):
	area_center = area_cente
	area_width = area_widt
	# We position the mob by placing it at start_position
	# and rotate it towards player_position, so it looks at the player.
	look_at_from_position(start_position, Vector3(
		Vector3(
			randf_range(area_center.x-area_width.x,area_center.x+area_width.x), 
			0, 
			randf_range(area_center.z-area_width.z,area_center.z+area_width.z)
			)
	), Vector3.UP)
	
	velocity = Vector3.FORWARD * velocity.length()
	velocity = velocity.rotated(Vector3.UP, rotation.y)
	# Rotate this mob randomly within range of -45 and +45 degrees,
	# so that it doesn't move directly towards the player.
	# rotate_y(randf_range(-PI / 4, PI / 4))

	# We calculate a random speed (integer)
	current_speed = randi_range(min_speed, max_speed)
	# We calculate a forward velocity that represents the speed.
	velocity = Vector3.FORWARD * current_speed
	#print("object : ", self, "avant : ", velocity)
	# We then rotate the velocity vector based on the mob's Y rotation
	# in order to move in the direction the mob is looking.
	velocity = velocity.rotated(Vector3.UP, rotation.y)
	#print("après : ", velocity)

func squash():
	squashed.emit()
	#queue_free()


func _on_life_expectancy_timeout() -> void:
	queue_free()
