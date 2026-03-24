extends Node

@export var player_scene: PackedScene
@export var mob_scene: PackedScene
@export var tree_scene: PackedScene
@export var nb_mob: int = 100
@export var nb_player: int = 100
@export var nb_tree: int = 10

@export var initial_infected_prey := 5 #permet de mettre en place le modèle SIR



func _on_mob_reproduce_mob(position):
	var centre = $Ground/CollisionShape3D.position
	var width = $Ground/CollisionShape3D.shape.extents
	var mob = mob_scene.instantiate()
	add_child(mob)

	var offset = Vector3(randf_range(-1,1), 0, randf_range(-1,1))
	mob.initialize(position + offset, centre, width)

	mob.reproduce_mob.connect(_on_mob_reproduce_mob)

func _on_player_reproduce_player(position):
	var centre = $Ground/CollisionShape3D.position
	var width = $Ground/CollisionShape3D.shape.extents
	var player = player_scene.instantiate()
	add_child(player)

	var offset = Vector3(randf_range(-1,1), 0, randf_range(-1,1))
	player.initialize(position + offset, centre, width)

	player.reproduce_player.connect(_on_player_reproduce_player)


func _ready() -> void:
	var centre = Vector3(0, 0, 0)
	var width = Vector3(250, 0, 250)

	#var centre = $Ground/CollisionShape3D.position
	#var width = $Ground/CollisionShape3D.shape.extents
	var start_pos = $GridMap.local_to_map(centre-width)
	var end_pos = $GridMap.local_to_map(centre+width)
	for x in range(start_pos.x, end_pos.x + 1):
		for z in range(start_pos.z, end_pos.z + 1):
			$GridMap.set_cell_item(Vector3i(x, 0, z), randi_range(0, 10))
	#$Player.initialize($Player.position, centre, width)
	#add_child($Player)
	var players = []
	for i in range(nb_player):
		var player = player_scene.instantiate()
		var spawn_location = Vector3(
			randf_range(centre.x-width.x,centre.x+width.x), 
			10, 
			randf_range(centre.z-width.z,centre.z+width.z)
			)
		#player.reproduce_player.connect(_on_player_reproduce_player)
		add_child(player)
		player.initialize(spawn_location, centre, width)
		players.append(player)
	players.shuffle()
	for i in range(min(initial_infected_prey, players.size())): #j'infecte 5 joueurs au hasard, foyer de contamination
		players[i].infected = true
		players[i].update_visual()
		
	
	for i in range(nb_mob):
		var mob = mob_scene.instantiate()
		var spawn_location = Vector3(
			randf_range(centre.x-width.x,centre.x+width.x), 
			10, 
			randf_range(centre.z-width.z,centre.z+width.z)
			)
		#mob.reproduce_mob.connect(_on_mob_reproduce_mob)
		add_child(mob)
		mob.initialize(spawn_location, centre, width)
		
	for i in range(nb_tree):
		var tree = tree_scene.instantiate()
		add_child(tree)
		tree.set_global_position(Vector3(
		randf_range(centre.x-width.x,centre.x+width.x), 
		10, 
		randf_range(centre.z-width.z,centre.z+width.z)
		))

#func _on_mob_timer_timeout() -> void:
	## Create a new instance of the Mob scene.
	#var mob = mob_scene.instantiate()
#
	## Choose a random location on the SpawnPath.
	## We store the reference to the SpawnLocation node.
	#var mob_spawn_location = get_node("SpawnPath/SpawnLocation")
	## And give it a random offset.
	#mob_spawn_location.progress_ratio = randf()
#
	#var player_position = $Player.position
	#mob.initialize(mob_spawn_location.position, player_position)
#
	## Spawn the mob by adding it to the Main scene.
	#add_child(mob)


func _on_player_hit() -> void:
	pass
	#$MobTimer.stop()
