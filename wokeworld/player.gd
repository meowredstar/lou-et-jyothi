extends CharacterBody3D

#j'ajoute un état infecté (pas mortel) aux proies
@export var infected := false

#récupérer le petit losange SIMS
@onready var top = $StatusMarker/CSGCylinder3D
@onready var bottom = $StatusMarker/CSGCylinder3D2

@export var mutated := false
@export var mutation_speed_multiplier := 1.2
@export var mutation_reproduction_multiplier := 1.25
@export var mutation_probability_on_reproduction := 0.2
@export var mutation_probability_over_time := 0.001


@export var step_height := 1
@export var max_step_levels := 3

func try_step_up(delta: float) -> bool:
	var horizontal_motion = Vector3(velocity.x, 0.0, velocity.z) * delta

	if horizontal_motion.length() < 0.001:
		return false

	# On ne teste que si le déplacement horizontal est bloqué
	if not test_move(global_transform, horizontal_motion):
		return false

	for level in range(1, max_step_levels + 1):
		var step_offset = step_height * level
		var raised_transform = global_transform.translated(Vector3.UP * step_offset)

		# Si en étant plus haut on peut avancer, on monte
		if not test_move(raised_transform, horizontal_motion):
			global_position.y += step_offset
			return true

	return false

func _ready():
	add_to_group("prey")

#changer sa couleur
func set_color(color: Color):
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color

	top.material = mat
	bottom.material = mat
	
func update_visual():
	if mutated:
		set_color(Color(0.2, 0.4, 1.0)) # bleu
	elif infected:
		set_color(Color(1, 0.2, 0.2)) # rouge
	else:
		set_color(Color(0.2, 1, 0.2)) # vert

func mutate_prey():
	if mutated:
		return

	if not infected:
		infected = true

	mutated = true
	current_speed = int(current_speed * mutation_speed_multiplier)
	reproduction_chance *= mutation_reproduction_multiplier
	update_visual()

func is_infected_prey() -> bool:
	return infected
	
# Emitted when the player was hit by a mob.
signal hit
@export var min_speed = 10
# Maximum speed of the mob in meters per second.
@export var max_speed = 18
# How fast the player moves in meters per second.
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75
# Vertical impulse applied to the character upon jumping in meters per second.
@export var min_turn_time = 0.4
@export var max_turn_time = 1.2

@export var reproduction_chance := 0.12
@export var reproduction_interval := 10

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

signal reproduce_player(position, baby_mutated)
	
func _physics_process(delta):
	
	age += delta
	
	
	reproduction_timer -= delta
	
	if not mutated:
		if randf() < mutation_probability_over_time:
			mutate_prey()
	
	if reproduction_timer <= 0.0:
		reproduction_timer = reproduction_interval
		if randf() <= reproduction_chance and age >= reproduction_min_age:
			var baby_mutated = false
			if mutated :
				baby_mutated = true
			elif infected and randf() < mutation_probability_on_reproduction:
				baby_mutated = true
			

			reproduce_player.emit(global_position, baby_mutated)
			
	turn_timer -= delta

	if turn_timer <= 0:
		choose_random_direction(global_position, area_center, area_width)



	
	for body in $MobDetector.get_overlapping_bodies():
		if body.is_in_group("mob"):
			var flee_direction = global_position - body.global_position
			flee_direction.y = 0
			flee_direction = flee_direction.normalized()

			if flee_direction.length() > 0.001:
				look_at(global_position + flee_direction, Vector3.UP)
				velocity.x = flee_direction.x * current_speed
				velocity.z = flee_direction.z * current_speed

			break
			
	if not is_on_floor():
		velocity.y -= fall_acceleration * delta
	else:
		velocity.y = 0

	var did_step_up = try_step_up(delta)

	var previous_position = global_position
	move_and_slide()
	var moved_distance = global_position.distance_to(previous_position)

	if not did_step_up and moved_distance < 0.02:
		choose_random_direction(global_position, area_center, area_width)
	
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

func is_mutated_prey() -> bool:
	return mutated
	
	
	
func initialize(start_position, ground_center, ground_half_size):
	update_visual()
	global_position = start_position
	area_center = ground_center
	area_width = ground_half_size
	counter += 1
	current_speed = randi_range(min_speed, max_speed)
	
	safe_margin = 0.08
	floor_snap_length = 1.5
	up_direction = Vector3.UP

	if mutated:
		current_speed = int(current_speed * mutation_speed_multiplier)
		reproduction_chance *= mutation_reproduction_multiplier
	choose_random_direction(start_position, ground_center, ground_half_size)

func die():
	hit.emit()
	# queue_free()

#func _on_mob_detector_body_entered(body: Node3D) -> void:
#	die()


func _on_life_expectancy_timeout() -> void:
	queue_free()
