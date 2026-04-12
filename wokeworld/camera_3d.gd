extends Camera3D

var speed = 2
var rotational_speed = 0.05

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_pressed("move_forward"):
		position.z -= speed
	if Input.is_action_pressed("move_back"):
		position.z += speed
	if Input.is_action_pressed("move_left"):
		position.x -= speed
	if Input.is_action_pressed("move_right"):
		position.x += speed
	if Input.is_action_pressed("move_down"):   
		position.y -= speed
		return
	if Input.is_action_pressed("move_up"):
		position.y += speed
	if Input.is_action_pressed("rotate_up"):
		# TODO regarder si pas moyen de faire un truc avec look_at
		rotate_x(rotational_speed)
	if Input.is_action_pressed("rotate_down"):
		rotate_x(-rotational_speed)
	if Input.is_action_pressed("rotate_left"):
		rotate_y(rotational_speed)
	if Input.is_action_pressed("rotate_right"):
		rotate_y(-rotational_speed)
	if Input.is_action_pressed("zoom_in"):
		position += -transform.basis.z
	if Input.is_action_pressed("zoom_out"):
		position -= -transform.basis.z
		
