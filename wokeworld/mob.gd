extends CharacterBody3D

@export var fall_acceleration := 75.0

# Minimum speed of the mob in meters per second.
@export var min_speed = 10
# Maximum speed of the mob in meters per second.
@export var max_speed = 18

@onready var top = $StatusMarker/CSGCylinder3D
@onready var bottom = $StatusMarker/CSGCylinder3D2

@export var mutation_probability_on_recovery := 0.15
@export var mutation_probability_on_reproduction := 0.2

func _ready():
	add_to_group("mob")

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
@export var mutation_death_probability := 0.5

var health_state = HealthState.HEALTHY
var infection_timer := 0.0
@export var infection_duration := 10
#@export var infection_chance := 1
@export var death_probability := 0.3


# Emitted when the player jumped on the mob.
#signal squashed


func infect(mutated := false):
	if health_state != HealthState.HEALTHY:
		return

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

	if infection_timer <= 0.0:
		if randf() < death_probability:
			queue_free()
		else:
			if health_state == HealthState.INFECTED and randf() < mutation_probability_on_recovery:
				health_state = HealthState.MUTATED
			else:
				health_state = HealthState.RESISTANT

			update_visual()
			
			
func infect_predators_on_contact():
	if health_state != HealthState.INFECTED and health_state != HealthState.MUTATED:
		return

	var radius = normal_infection_radius
	if health_state == HealthState.MUTATED:
		radius = mutation_infection_radius

	for body in get_tree().get_nodes_in_group("mob"):
		if body == self:
			continue
		if body.health_state != HealthState.HEALTHY:
			continue

		if global_position.distance_to(body.global_position) < radius:
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

signal reproduce_mob(position, baby_mutated)



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

			reproduce_mob.emit(global_position, baby_mutated)
	
	turn_timer -= _delta

	if turn_timer <= 0:
		choose_random_direction()
	
	for body in $PreyDetector.get_overlapping_bodies():
		if body.is_in_group("prey") :
			velocity = velocity.rotated(Vector3.UP, -rotation.y)
			var target = body.global_position
			target.y = global_position.y
			look_at(target, Vector3.UP)
			velocity = velocity.rotated(Vector3.UP, rotation.y)
			
			var prey_pos = body.global_position
			var mob_pos = global_position

			prey_pos.y = 0
			mob_pos.y = 0

			if mob_pos.distance_to(prey_pos) < 4:
				eat_prey(body)
			
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
	
	velocity = Vector3.FORWARD * velocity.length()
	velocity = velocity.rotated(Vector3.UP, rotation.y)
	
	update_visual()
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

func eat_prey(prey):
	if prey != null:
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
