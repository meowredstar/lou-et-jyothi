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

# Hash lookup table as defined by Ken Perlin.  This is a randomly
# arranged array of all numbers from 0-255 inclusive.
const permutation = [151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,
140,36,103,30,69,142,8,99,37,240,21,10,23,190,6,148,247,120,234,75,0,26,197,62,
94,252,219,203,117,35,11,32,57,177,33,88,237,149,56,87,174,20,125,136,171,168,
68,175,74,165,71,134,139,48,27,166,77,146,158,231,83,111,229,122,60,211,133,230
,220,105,92,41,55,46,245,40,244,102,143,54,65,25,63,161,1,216,80,73,209,76,132,
187,208, 89,18,169,200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,
52,217,226,250,124,123,5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,
58,17,182,189,28,42,223,183,170,213,119,248,152,2,44,154,163, 70,221,153,101,
155,167,43,172,9,129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,218
,246,97,228,251,34,242,193,238,210,144,12,191,179,162,241,81,51,145,235,249,14,
239,107,49,192,214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,
254,138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,151 # repet ici
,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,
37,240,21,10,23,190,6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,
32,57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,74,165,71,134,139,
48,27,166,77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,
40,244,102,143,54,65,25,63,161,1,216,80,73,209,76,132,187,208, 89,18,169,200,
196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,52,217,226,250,124,123,
5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,223
,183,170,213,119,248,152,2,44,154,163, 70,221,153,101,155,167,43,172,9,129,22,
39,253,19,98,108,110,79,113,224,232,178,185,112,104,218,246,97,228,251,34,242,
193,238,210,144,12,191,179,162,241,81,51,145,235,249,14,239,107,49,192,214,31,
181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,254,138,236,205,93,222,
114,67,29,24,72,243,141,128,195,78,66,215,61,156,180]


# Fade function as defined by Ken Perlin. This eases coordinate values
# so that they will ease towards integral values. This ends up smoothing
# the final output.
func fade(t):
	return t * t * t * (t * (t * 6 - 15) + 10)   # 6t^5 - 15t^4 + 10t^3


func grad(hash_p, x, y, z):
	# Take the hashed value and take the first 4 bits of it (15 == 0b1111)
	var h = hash_p & 15
	# If the most significant bit (MSB) of the hash is 0 then set u = x.  Otherwise y.
	var u = x if h < 0b1000 else y
	
	# In Ken Perlin's original implementation this was another conditional operator (?:).  I
	# expanded it for readability.
	var v: float

	# If the first and second significant bits are 0 set v = y
	if h <  0b0100:
		v = y
	# If the first and second significant bits are 1 set v = x
	elif (h ==  0b1100 or h == 0b1110):
		v = x
	 # If the first and second significant bits are not equal (0/1, 1/0) set v = z
	else:
		v = z
	# Use the last 2 bits to decide if u and v are positive or negative.  Then return their addition.
	return (u if (h&1) == 0 else -u)+(v if (h&2) == 0 else -v)


# Calculate the "unit cube" that the point asked will be located in
# The left bound is ( |_x_|,|_y_|,|_z_| ) and the right bound is that
# plus 1.  Next we calculate the location (from 0.0 to 1.0) in that cube.
func perlin(x, y, z):
	var xi = int(x) % 256
	if xi < 0: xi += 256
	var yi = int(y) % 256
	if yi < 0: yi += 256
	var zi = int(z) % 256
	if zi < 0: zi += 256
	
	var xf = x-floor(x)
	var yf = y-floor(y)
	var zf = z-floor(z)
	
	var u = fade(xf)
	var v = fade(yf)
	var w = fade(zf)
	
	var coin_bas_gauche_arriere = permutation[permutation[permutation[xi]+yi]+
	zi]
	var coin_haut_gauche_arriere = permutation[permutation[permutation[xi]+yi+1
	]+zi]
	var coin_bas_gauche_avant = permutation[permutation[permutation[xi]+yi]+zi+
	1]
	var coin_haut_gauche_avant = permutation[permutation[permutation[xi]+yi+1]+
	zi+1]
	var coin_bas_droite_arriere = permutation[permutation[permutation[xi+1]+yi]
	+zi]
	var coin_haut_droite_arriere = permutation[permutation[permutation[xi+1]+
	yi+1]+zi]
	var coin_bas_droite_avant = permutation[permutation[permutation[xi+1]+yi]+
	zi+1]
	var coin_haut_droite_avant = permutation[permutation[permutation[xi+1]+yi+1
	]+zi+1]
	
	# The gradient function calculates the dot product between a pseudorandom
	# gradient vector and the vector from the input coordinate to the 8
	# surrounding points in its unit cube.
	# This is all then lerped together as a sort of weighted average based on the faded (u,v,w)
	# values we made earlier.
	var x1 = lerp(grad(coin_bas_gauche_arriere, xf, yf, zf), grad(
		coin_bas_droite_arriere, xf-1, yf, zf), u)
	var x2 = lerp(grad (coin_haut_gauche_arriere, xf, yf-1, zf), grad(
		coin_haut_droite_arriere, xf-1, yf-1, zf), u)
	var y1 = lerp(x1, x2, v)
	x1 = lerp(grad(coin_bas_gauche_avant, xf, yf, zf-1), grad(
		coin_bas_droite_avant, xf-1, yf, zf-1), u)
	x2 = lerp(grad(coin_haut_gauche_avant, xf, yf-1, zf-1), grad(
		coin_haut_droite_avant, xf-1, yf-1, zf-1), u)
	var y2 = lerp(x1, x2, v)
	
	return lerp(y1, y2, w)

func _on_mob_reproduce_mob(position, baby_mutated):
	var mob = mob_scene.instantiate()
	add_child(mob)

	var offset = Vector3(randf_range(-1,1), 0, randf_range(-1,1))
	mob.initialize(position + offset, centre, width)

	if baby_mutated:
		mob.health_state = mob.HealthState.MUTATED
		mob.current_speed = int(mob.current_speed * mob.mutation_speed_multiplier)
		mob.death_probability = mob.mutation_death_probability
		mob.infection_timer = mob.infection_duration
		mob.update_visual()

	mob.reproduce_mob.connect(_on_mob_reproduce_mob)

func _on_player_reproduce_player(position, baby_mutated):
	var player = player_scene.instantiate()
	add_child(player)

	var offset = Vector3(randf_range(-1,1), 0, randf_range(-1,1))

	if baby_mutated:
		player.mutated = true
		player.infected = true

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
	var noise_res = int(round((perlin(start_pos.x/10.0, 0.0, start_pos.z/10.0)+
	1)*1.99999999999999))
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
			#noise_res = int(round((noise.get_noise_3d(x, 0, z)+1.0)*2.125))
			noise_res = int(round((perlin(x/10.0, 0.0, z/10.0)+1)
			*2))
			if noise_res == 4: noise_res = 3
			if noise_res == 0: noise_res = 1
			#print(noise_res)
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
									$GridMap.set_cell_item(pos, randi_range(8,
									9))
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
