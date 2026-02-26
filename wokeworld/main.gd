extends Node

@export var mob_scene: PackedScene
@export var nb_mob: int = 100

func _ready() -> void:
	var centre = $Ground/CollisionShape3D.position
	var width = $Ground/CollisionShape3D.shape.extents
	for i in range(nb_mob):
		var mob = mob_scene.instantiate()
		var spawn_location = Vector3(
			randf_range(centre.x-width.x,centre.x+width.x), 
			0, 
			randf_range(centre.z-width.z,centre.z+width.z)
			)
		var player_position = $Player.position
		mob.initialize(spawn_location, centre, width)
		add_child(mob)

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
