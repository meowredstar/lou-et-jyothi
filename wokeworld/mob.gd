extends CharacterBody3D

# Minimum speed of the mob in meters per second.
@export var min_speed = 10
# Maximum speed of the mob in meters per second.
@export var max_speed = 18

# Emitted when the player jumped on the mob.
signal squashed

func _physics_process(_delta):
	for body in $PreyDetector.get_overlapping_bodies():
		if body.is_in_group("prey") :
			velocity = velocity.rotated(Vector3.UP, -rotation.y)
			look_at(body.position)
			velocity = velocity.rotated(Vector3.UP, rotation.y)
	move_and_slide()

# This function will be called from the Main scene.
func initialize(start_position, area_center, area_width):
	# We position the mob by placing it at start_position
	# and rotate it towards player_position, so it looks at the player.
	look_at_from_position(start_position, Vector3(
		Vector3(
			randf_range(area_center.x-area_width.x,area_center.x+area_width.x), 
			0, 
			randf_range(area_center.z-area_width.z,area_center.z+area_width.z)
			)
	), Vector3.UP)
	# Rotate this mob randomly within range of -45 and +45 degrees,
	# so that it doesn't move directly towards the player.
	# rotate_y(randf_range(-PI / 4, PI / 4))

	# We calculate a random speed (integer)
	var random_speed = randi_range(min_speed, max_speed)
	# We calculate a forward velocity that represents the speed.
	velocity = Vector3.FORWARD * random_speed
	print("object : ", self, "avant : ", velocity)
	# We then rotate the velocity vector based on the mob's Y rotation
	# in order to move in the direction the mob is looking.
	velocity = velocity.rotated(Vector3.UP, rotation.y)
	print("après : ", velocity)

func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	pass
	#queue_free()

func squash():
	squashed.emit()
	#queue_free()
