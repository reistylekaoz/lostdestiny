class_name IsometricCamera
extends Camera3D

## Câmera ortogonal no ângulo isométrico clássico (estilo MU Online: vista de
## cima em diagonal, sem perspectiva).

@export var look_at_point := Vector3(0.5, 0, -1)
@export var distance := 20.0
@export var pitch_degrees := 35.0
@export var yaw_degrees := 45.0
@export var ortho_size := 10.0


func _ready() -> void:
	projection = PROJECTION_ORTHOGONAL
	size = ortho_size
	var pitch := deg_to_rad(pitch_degrees)
	var yaw := deg_to_rad(yaw_degrees)
	var offset := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * distance
	position = look_at_point + offset
	look_at(look_at_point)
