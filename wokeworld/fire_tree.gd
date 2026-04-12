extends AnimatableBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not is_in_group("burn"):
		for body in $fire_detector.get_overlapping_bodies():
			if body.is_in_group("burning"):
				set_on_fire()


func set_on_fire():
	add_to_group("burn")
	$fire.visible = true
	$BurnOtherTrees.start()

func stop_fire():
	$BurnOtherTrees.stop()
	$fire.visible = false
	remove_from_group("burn")
	if is_in_group("burning"):
		$Burned.stop()
		remove_from_group("burning")


func _on_burn_other_trees_timeout() -> void:
	$BurnOtherTrees.stop()
	$Burned.start()
	add_to_group("burning")


func _on_burned_timeout() -> void:
	queue_free()
