extends Node

@export var player_scene: PackedScene
@export var mob_scene: PackedScene
@export var tree_scene: PackedScene
@export var nb_mob: int = 100
@export var nb_player: int = 100
@export var nb_tree: int = 10




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
	var centre = $Ground/CollisionShape3D.position
	var width = $Ground/CollisionShape3D.shape.extents
	#$Player.initialize($Player.position, centre, width)
	#add_child($Player)
	for i in range(nb_player):
		var player = player_scene.instantiate()
		var spawn_location = Vector3(
			randf_range(centre.x-width.x,centre.x+width.x), 
			0, 
			randf_range(centre.z-width.z,centre.z+width.z)
			)
		player.reproduce_player.connect(_on_player_reproduce_player)
		add_child(player)
		player.initialize(spawn_location, centre, width)
		
	for i in range(nb_mob):
		var mob = mob_scene.instantiate()
		var spawn_location = Vector3(
			randf_range(centre.x-width.x,centre.x+width.x), 
			0, 
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
		0, 
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
