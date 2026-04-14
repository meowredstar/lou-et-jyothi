extends CharacterBody3D

@export var fall_acceleration := 75.0

# Minimum speed of the predator in meters per second.
@export var min_speed = 10
# Maximum speed of the predator in meters per second.
@export var max_speed = 18

@onready var top = $StatusMarker/CSGCylinder3D
@onready var bottom = $StatusMarker/CSGCylinder3D2

@export var mutation_probability_on_recovery := 0.15
@export var mutation_probability_on_reproduction := 0.2

@export var step_height := 1
@export var max_step_levels := 3

var target_prey: Node3D = null
@export var eat_distance := 5.0

func is_prey_still_detected(prey: Node3D) -> bool:
	if prey == null or not is_instance_valid(prey):
		return false

	for body in $PreyDetector.get_overlapping_bodies():
		if body == prey:
			return true

	return false
	
func pick_prey_target() -> void:
	var closest_prey: Node3D = null
	var closest_dist := INF

	for body in $PreyDetector.get_overlapping_bodies():
		if body.is_in_group("prey"):
			var prey_pos = body.global_position
			var predator_pos = global_position
			prey_pos.y = 0
			predator_pos.y = 0

			var dist = predator_pos.distance_to(prey_pos)
			if dist < closest_dist:
				closest_dist = dist
				closest_prey = body

	target_prey = closest_prey
	
func chase_target_prey() -> void:
	if target_prey == null or not is_instance_valid(target_prey):
		return

	var target = target_prey.global_position
	target.y = global_position.y

	var chase_dir = target - global_position
	chase_dir.y = 0

	if chase_dir.length() > 0.001:
		chase_dir = chase_dir.normalized()
		look_at(global_position + chase_dir, Vector3.UP)
		velocity.x = chase_dir.x * current_speed
		velocity.z = chase_dir.z * current_speed

	var prey_pos = target_prey.global_position
	var predator_pos = global_position
	prey_pos.y = 0
	predator_pos.y = 0

	if predator_pos.distance_to(prey_pos) < eat_distance:
		eat_prey(target_prey)
		target_prey = null

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
	add_to_group("predator")

func set_color(color: Color):
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color

	top.material = mat
	bottom.material = mat
	
func update_visual():
	match health_state:
		HealthState.HEALTHY:
			set_color(Color(0.2, 1, 0.2)) # vert
		HealthState.INFECTED:
			set_color(Color(1, 0.2, 0.2)) # rouge
		HealthState.MUTATED:
			set_color(Color(0.2, 0.4, 1.0)) # bleu
		HealthState.RESISTANT:
			set_color(Color(0.5, 0.5, 0.5)) # gris

@export var min_turn_time = 1.0
@export var max_turn_time = 3.0

@onready var starvation_timer: Timer = $Starvation

@export var reproduction_chance := 0.1
@export var reproduction_interval := 5.0

var reproduction_timer := 0.0

var turn_timer = 0.0
var area_center
var area_width
var current_speed

@export var reproduction_min_age := 10.0
var age := 0.0

enum HealthState {
	HEALTHY,
	INFECTED,
	MUTATED,
	RESISTANT
}

@export var mutation_speed_multiplier := 1.2
@export var mutation_infection_radius := 6.0
@export var normal_infection_radius := 4.0
@export var mutation_death_probability := 0.005

var health_state = HealthState.HEALTHY
var infection_timer := 0.0
@export var infection_duration := 10
#@export var infection_chance := 1
@export var death_probability := 0.0025


# Emitted when the prey jumped on the predator.
#signal squashed


func infect(mutated := false):
	if health_state != HealthState.HEALTHY:
		return
	
	add_to_group("infected_predator")

	if mutated:
		health_state = HealthState.MUTATED
		infection_timer = infection_duration
		death_probability = mutation_death_probability
		current_speed = int(current_speed * mutation_speed_multiplier)
	else:
		health_state = HealthState.INFECTED
		infection_timer = infection_duration

	update_visual()

func update_infection(delta):
	if health_state != HealthState.INFECTED and health_state != HealthState.MUTATED:
		return

	infection_timer -= delta
	
	if randf() < death_probability:
			queue_free()
			return

	if infection_timer <= 0.0:
		if health_state == HealthState.INFECTED and randf() < mutation_probability_on_recovery:
			add_to_group("mutated_predator")
			health_state = HealthState.MUTATED
			current_speed = int(current_speed * mutation_speed_multiplier)
			death_probability = mutation_death_probability
		else:
			remove_from_group("infected_predator")
			add_to_group("healed_predator")
			health_state = HealthState.RESISTANT

			update_visual()
			
			
func infect_predators_on_contact():
	if health_state != HealthState.INFECTED and health_state != HealthState.MUTATED:
		return

	var radius = normal_infection_radius
	if health_state == HealthState.MUTATED:
		radius = mutation_infection_radius

	for body in get_tree().get_nodes_in_group("predator"):
		if body == self:
			continue
		if body.health_state != HealthState.HEALTHY:
			continue
		var other_pos = body.global_position
		var predator_pos = global_position
		other_pos.y = 0
		predator_pos.y = 0
		if predator_pos.distance_to(other_pos) < radius:
			body.infect(health_state == HealthState.MUTATED)

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

signal reproduce_predator(position, baby_mutated)



func _physics_process(_delta):
	
	age += _delta
	
	update_infection(_delta)
	infect_predators_on_contact()

	reproduction_timer -= _delta

	if reproduction_timer <= 0.0:
		reproduction_timer = reproduction_interval
		if randf() < reproduction_chance and age >= reproduction_min_age:
			var baby_mutated = false

			if health_state == HealthState.MUTATED or health_state == HealthState.INFECTED or health_state == HealthState.RESISTANT:
				if randf() < mutation_probability_on_reproduction:
					baby_mutated = true

			reproduce_predator.emit(global_position, baby_mutated)
	
	turn_timer -= _delta
	if target_prey == null:
		if turn_timer <= 0:
			choose_random_direction()
	
	if target_prey == null or not is_instance_valid(target_prey) or not is_prey_still_detected(target_prey):
		pick_prey_target()

	if target_prey != null:
		chase_target_prey()
			
	if not is_on_floor():
		velocity.y -= fall_acceleration * _delta
	else:
		velocity.y = 0

	var did_step_up = try_step_up(_delta)
	
	
	var previous_position = global_position
	move_and_slide()
	var moved_distance = global_position.distance_to(previous_position)

	if not did_step_up and moved_distance < 0.02:
		choose_random_direction()
	
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
	# We position the predator by placing it at start_position
	# and rotate it towards prey_position, so it looks at the prey.
	
	var target = Vector3(
		randf_range(area_center.x - area_width.x, area_center.x + area_width.x),
		start_position.y,
		randf_range(area_center.z - area_width.z, area_center.z + area_width.z)
	)

	look_at_from_position(start_position, target, Vector3.UP)
	#look_at_from_position(start_position, Vector3(
		#Vector3(
			#randf_range(area_center.x-area_width.x,area_center.x+area_width.x), 
			#0, 
			#randf_range(area_center.z-area_width.z,area_center.z+area_width.z)
			#)
	#), Vector3.UP)
	
	
	update_visual()
	# Rotate this predator randomly within range of -45 and +45 degrees,
	# so that it doesn't move directly towards the prey.
	# rotate_y(randf_range(-PI / 4, PI / 4))

	# We calculate a random speed (integer)
	current_speed = randi_range(min_speed, max_speed)
	safe_margin = 0.08
	floor_snap_length = 2.0
	up_direction = Vector3.UP
	# We calculate a forward velocity that represents the speed.
	velocity = Vector3.FORWARD * current_speed
	#print("object : ", self, "avant : ", velocity)
	# We then rotate the velocity vector based on the predator's Y rotation
	# in order to move in the direction the predator is looking.
	velocity = velocity.rotated(Vector3.UP, rotation.y)
	#print("après : ", velocity)

func eat_prey(prey):
	if prey != null:
		if prey == target_prey:
			target_prey = null
		if prey.has_method("is_infected_prey") and prey.is_infected_prey():
			if prey.has_method("is_mutated_prey") and prey.is_mutated_prey():
				infect(true)
			else:
				infect(false)

		prey.queue_free()

	starvation_timer.start()

func _on_starvation_timeout() -> void:
	queue_free()
	
#func squash():
	#squashed.emit()
	##queue_free()


func _on_life_expectancy_timeout() -> void:
	queue_free()
