extends AnimatableBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_on_fire():
	add_to_group("burn")
	$fire.visible = true
	$BurnOtherTrees.start()


func _on_burn_other_trees_timeout() -> void:
	$Burned.start()
	add_to_group("burning")


func _on_burned_timeout() -> void:
	queue_free()
