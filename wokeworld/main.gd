extends Node

@export var player_scene: PackedScene
@export var mob_scene: PackedScene
@export var tree_scene: PackedScene
@export var nb_mob: int = 100
@export var nb_player: int = 100
@export var nb_tree: int = 10
@export var initial_infected_prey := 5 #permet de mettre en place le modèle SIR

# terrain dimension
var centre = Vector3(0, 0, 0)
var width = Vector3(250, 0, 250)


func _on_mob_reproduce_mob(position):
	var mob = mob_scene.instantiate()
	add_child(mob)

	var offset = Vector3(randf_range(-1,1), 0, randf_range(-1,1))
	mob.initialize(position + offset, centre, width)

	mob.reproduce_mob.connect(_on_mob_reproduce_mob)

func _on_player_reproduce_player(position):
	var player = player_scene.instantiate()
	add_child(player)

	var offset = Vector3(randf_range(-1,1), 0, randf_range(-1,1))
	player.initialize(position + offset, centre, width)

	player.reproduce_player.connect(_on_player_reproduce_player)

func type_of_cell(x: int, z: int):
	match $GridMap.get_cell_item(Vector3i(x, 0, z)):
		0, 1, 20, 21, 22, 23, 28, 29:
			return 1
		2, 3, 10, 11, 14, 15, 24, 27, 30, 31:
			return 2
		4, 5, 6, 7, 8, 9, 12, 13, 16, 17, 18, 19, 25, 26:
			return 3
		_:
			return $GridMap.INVALID_CELL_ITEM


func type_neighbours(x, z):
	var types = []
	for x_n in range(x-1, x+2):
		for z_n in range(z-1, z+2):
			if x != x_n or z != z_n:
				types.append([type_of_cell(x_n, z_n), x_n-x, z_n-z])

	return types


func _ready() -> void:
	var noise = FastNoiseLite.new()
	noise.seed = randi_range(10, 99999)
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	var start_pos = $GridMap.local_to_map(centre-width)
	var end_pos = $GridMap.local_to_map(centre+width)
	var pos = Vector3i(start_pos.x, 0, start_pos.z)
	var noise_res = int(round((noise.get_noise_3d(start_pos.x, 0, start_pos.z)+
	1.0)*2.125))
	match noise_res:
		1:
			$GridMap.set_cell_item(pos, randi_range(0, 1))
		2:
			$GridMap.set_cell_item(pos, randi_range(14, 15), 16)
		3:
			$GridMap.set_cell_item(pos, randi_range(16, 19), 16)
		_:
			printerr("valeur non prévue : ", noise_res)
	for x in range(start_pos.x, end_pos.x + 1):
		for z in range(start_pos.z, end_pos.z + 1):
			if x == start_pos.x and z == start_pos.z:
				continue
			pos = Vector3i(x, 0, z)
			noise_res = int(round((noise.get_noise_3d(x, 0, z)+1.0)*2.125))
			print(noise_res)
			var n_type = type_neighbours(x, z)
			var neighbour = [$GridMap.INVALID_CELL_ITEM]
			while (neighbour[0] == $GridMap.INVALID_CELL_ITEM):
				neighbour = n_type[randi_range(0, 7)]
			match noise_res:
				1:
					match neighbour[0]:
						2:
							match neighbour.slice(1, 2):
								[-1, 0]:
									if type_of_cell(x, z-1) == 2:
										$GridMap.set_cell_item(pos, 
										randi_range(26, 27), 22)
									elif type_of_cell(x, z+1) == 2:
										$GridMap.set_cell_item(pos,
										randi_range(26, 27), 22)
									else:
										$GridMap.set_cell_item(pos,
										randi_range(20, 21), 22)
								[0, -1]:
									if type_of_cell(x-1, z) == 2:
										$GridMap.set_cell_item(pos,
										randi_range(26, 27), 22)
									elif type_of_cell(x+1, z) == 2:
										$GridMap.set_cell_item(pos,
										randi_range(26, 27), 16)
									else:
										$GridMap.set_cell_item(pos,
										randi_range(20, 21), 22)
								[0, 1]:
									if type_of_cell(x-1, z) == 2:
										$GridMap.set_cell_item(pos,
										randi_range(26, 27), 22)
									elif type_of_cell(x+1, z) == 2:
										$GridMap.set_cell_item(pos,
										randi_range(26, 27), 16)
									else:
										$GridMap.set_cell_item(pos,
										randi_range(20, 21), 16)
								[1, 0]:
									if type_of_cell(x, z-1) == 2:
										$GridMap.set_cell_item(pos,
										randi_range(26, 27), 16)
									elif type_of_cell(x, z+1) == 2:
										$GridMap.set_cell_item(pos,
										randi_range(26, 27), 16)
									else:
										$GridMap.set_cell_item(pos,
										randi_range(20, 21), 16)
								_:
									$GridMap.set_cell_item(pos, 
									randi_range(0, 1))
						3:
							match neighbour.slice(1, 2):
								[-1, 0]:
									if type_of_cell(x, z-1) == 3:
										$GridMap.set_cell_item(pos, 
										randi_range(28, 29), 22)
									elif type_of_cell(x, z+1) == 3:
										$GridMap.set_cell_item(pos,
										randi_range(28, 29), 22)
									else:
										$GridMap.set_cell_item(pos,
										randi_range(22, 23), 22)
								[0, -1]:
									if type_of_cell(x-1, z) == 3:
										$GridMap.set_cell_item(pos,
										randi_range(28, 29), 22)
									elif type_of_cell(x+1, z) == 3:
										$GridMap.set_cell_item(pos,
										randi_range(28, 29), 16)
									else:
										$GridMap.set_cell_item(pos,
										randi_range(22, 23), 22)
								[0, 1]:
									if type_of_cell(x-1, z) == 3:
										$GridMap.set_cell_item(pos,
										randi_range(28, 29), 22)
									elif type_of_cell(x+1, z) == 3:
										$GridMap.set_cell_item(pos,
										randi_range(28, 29), 16)
									else:
										$GridMap.set_cell_item(pos,
										randi_range(22, 23), 16)
								[1, 0]:
									if type_of_cell(x, z-1) == 3:
										$GridMap.set_cell_item(pos,
										randi_range(28, 29), 16)
									elif type_of_cell(x, z+1) == 3:
										$GridMap.set_cell_item(pos,
										randi_range(28, 29), 16)
									else:
										$GridMap.set_cell_item(pos,
										randi_range(22, 23), 16)
								_:
									$GridMap.set_cell_item(pos,
									randi_range(0, 1))
						_:
							$GridMap.set_cell_item(pos, randi_range(0, 1))
				2:
					match neighbour[0]:
						3:
							match neighbour.slice(1, 2):
								[-1, 0]:
									if type_of_cell(x, z-1) == 3:
										$GridMap.set_cell_item(pos, 
										randi_range(30, 31), 22)
									elif type_of_cell(x, z+1) == 3:
										$GridMap.set_cell_item(pos,
										randi_range(30, 31), 22)
									else:
										$GridMap.set_cell_item(pos,
										randi_range(24, 25), 22)
								[0, -1]:
									if type_of_cell(x-1, z) == 3:
										$GridMap.set_cell_item(pos,
										randi_range(30, 31), 22)
									elif type_of_cell(x+1, z) == 3:
										$GridMap.set_cell_item(pos,
										randi_range(30, 31), 16)
									else:
										$GridMap.set_cell_item(pos,
										randi_range(24, 25), 22)
								[0, 1]:
									if type_of_cell(x-1, z) == 3:
										$GridMap.set_cell_item(pos,
										randi_range(30, 31), 22)
									elif type_of_cell(x+1, z) == 3:
										$GridMap.set_cell_item(pos,
										randi_range(30, 31), 16)
									else:
										$GridMap.set_cell_item(pos,
										randi_range(24, 25), 16)
								[1, 0]:
									if type_of_cell(x, z-1) == 3:
										$GridMap.set_cell_item(pos,
										randi_range(30, 31), 16)
									elif type_of_cell(x, z+1) == 3:
										$GridMap.set_cell_item(pos,
										randi_range(30, 31), 16)
									else:
										$GridMap.set_cell_item(pos,
										randi_range(24, 25), 16)
								_:
									$GridMap.set_cell_item(pos,
									randi_range(2, 3))
						_:
							match x:
								start_pos.x:
									match z:
										#start_pos.z:
											#$GridMap.set_cell_item(pos, randi_range(14, 15), 16)
										end_pos.z:
											$GridMap.set_cell_item(pos,
											randi_range(14, 15), 10)
										_:
											$GridMap.set_cell_item(pos,
											randi_range(10, 11), 16)
								end_pos.x:
									match z:
										start_pos.z:
											#$GridMap.set_cell_item(pos,
											#randi_range(14, 15), 16)
											$GridMap.set_cell_item(pos,
											randi_range(14, 15), 0)
										end_pos.z:
											$GridMap.set_cell_item(pos,
											randi_range(14, 15), 22)
										_:
											$GridMap.set_cell_item(pos,
											randi_range(10, 11), 22)
								_:
									match z:
										start_pos.z:
											#$GridMap.set_cell_item(pos,
											#randi_range(10, 11), 16)
											$GridMap.set_cell_item(pos,
											randi_range(10, 11), 0)
										end_pos.z:
											$GridMap.set_cell_item(pos,
											randi_range(10, 11), 10)
										_:
											$GridMap.set_cell_item(pos,
											randi_range(2, 3))
				3:
					match x:
						start_pos.x:
							match z:
								#start_pos.z:
									#$GridMap.set_cell_item(pos, randi_range(14, 15), 16)
								end_pos.z:
									$GridMap.set_cell_item(pos, randi_range(16,
									 19), 10)
								_:
									$GridMap.set_cell_item(pos, [randi_range(4,
									7), randi_range(12, 13)][randi_range(0, 1)]
									, 16)
						end_pos.x:
							match z:
								start_pos.z:
									$GridMap.set_cell_item(pos, randi_range(16,
									19), 0)
								end_pos.z:
									$GridMap.set_cell_item(pos, randi_range(16,
									19), 22)
								_:
									$GridMap.set_cell_item(pos, [randi_range(4,
									7), randi_range(12, 13)][randi_range(0, 1)]
									, 22)
						_:
							match z:
								start_pos.z:
									$GridMap.set_cell_item(pos, [randi_range(4,
									7), randi_range(12, 13)][randi_range(0, 1)]
									, 0)
								end_pos.z:
									$GridMap.set_cell_item(pos, [randi_range(4,
									7), randi_range(12, 13)][randi_range(0, 1)]
									, 10)
								_:
									$GridMap.set_cell_item(pos, randi_range(2,
									3))
				_:
					printerr("Hauteur non prise en charge")
	
	#var centre = $Ground/CollisionShape3D.position
	#var width = $Ground/CollisionShape3D.shape.extents
	#start_pos = $GridMap.local_to_map(centre-width)
	#end_pos = $GridMap.local_to_map(centre+width)
	#for x in range(start_pos.x, end_pos.x + 1):
		#for z in range(start_pos.z, end_pos.z + 1):
			#$GridMap.set_cell_item(Vector3i(x, 0, z), randi_range(0, 22))
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
		player.reproduce_player.connect(_on_player_reproduce_player)
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
		mob.reproduce_mob.connect(_on_mob_reproduce_mob)
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
