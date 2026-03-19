extends CharacterBody3D

# Emitted when the player was hit by a mob.
signal hit
@export var min_speed = 10
# Maximum speed of the mob in meters per second.
@export var max_speed = 18
# How fast the player moves in meters per second.
@export var speed = 14
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75
# Vertical impulse applied to the character upon jumping in meters per second.
@export var min_turn_time = 1.0
@export var max_turn_time = 3.0

@export var reproduction_chance := 0.1
@export var reproduction_interval := 5.0

var reproduction_timer := 0.0

var current_speed: int
var area_center: Vector3
var area_width: Vector3
var turn_timer = 0.0
static var counter = 0

@export var reproduction_min_age := 20.0 

var age := 0.0


func choose_random_direction(start_position, ground_center, ground_half_size):
	var target = Vector3(
		randf_range(ground_center.x - ground_half_size.x, ground_center.x + ground_half_size.x),
		start_position.y,
		randf_range(ground_center.z - ground_half_size.z, ground_center.z + ground_half_size.z)
	)
	
	#look_at_from_position(start_position, target, Vector3.UP)
	look_at(target, Vector3.UP)
	velocity = Vector3.FORWARD * current_speed
	velocity = velocity.rotated(Vector3.UP, rotation.y)

	turn_timer = randf_range(min_turn_time, max_turn_time)

signal reproduce_player(position)
	
func _physics_process(delta):
	
	age += delta
	
	
	reproduction_timer -= delta
	
	if reproduction_timer <= 0.0 :
		reproduction_timer = reproduction_interval
		if randf() <= reproduction_chance and age < reproduction_min_age:
			reproduce_player.emit(global_position)
			
	turn_timer -= delta

	if turn_timer <= 0:
		choose_random_direction(global_position, area_center, area_width)

	var fleeing = false

	
	for body in $MobDetector.get_overlapping_bodies():
		if body.is_in_group("mob"):
			fleeing = true
			velocity = velocity.rotated(Vector3.UP, -rotation.y)

			var flee_direction = global_position - body.global_position
			flee_direction.y = 0

			look_at(global_position + flee_direction, Vector3.UP)

			velocity = velocity.rotated(Vector3.UP, rotation.y)
			break
			
	if not fleeing:
		pass
	if not is_on_floor():
		velocity.y -= fall_acceleration * delta
	else:
		velocity.y = 0
	
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
		choose_random_direction(global_position, area_center, area_width)

	global_position.x = clamp(global_position.x, min_x, max_x)
	global_position.z = clamp(global_position.z, min_z, max_z)
	
	
	# We check for each move input and update the direction accordingly.
	
	
	
	
func initialize(start_position, ground_center, ground_half_size):
	global_position = start_position
	area_center = ground_center
	area_width = ground_half_size
	counter += 1
	current_speed = randi_range(min_speed, max_speed)
	choose_random_direction(start_position, ground_center, ground_half_size)

func die():
	hit.emit()
	# queue_free()

#func _on_mob_detector_body_entered(body: Node3D) -> void:
#	die()


func _on_life_expectancy_timeout() -> void:
	queue_free()
