class_name WingsPlaceholder
extends Node3D

## Asa provisória feita de "penas" em leque, só para validar o slot de asas
## até termos modelos de verdade. Bate devagar enquanto o personagem está parado.

const FEATHERS := 7
const FLAP_SPEED := 2.0
const FLAP_DEGREES := 12.0

var _left := Node3D.new()
var _right := Node3D.new()
var _time := 0.0


func _init() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.45, 0.05, 0.08, 0.85)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(0.6, 0.05, 0.1)
	material.emission_energy_multiplier = 0.6
	material.cull_mode = BaseMaterial3D.CULL_DISABLED

	# Nas costas do personagem (o rig olha para +Z, então as costas são -Z).
	position = Vector3(0, 0.35, -0.35)
	for side in [[_left, 1.0], [_right, -1.0]]:
		var pivot: Node3D = side[0]
		var dir: float = side[1]
		pivot.position.x = 0.12 * dir
		add_child(pivot)
		for i in FEATHERS:
			var length := 1.9 - i * 0.16
			var feather := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(length, 0.22, 0.02)
			mesh.material = material
			feather.mesh = mesh
			var fan := Node3D.new()
			fan.rotation_degrees.z = dir * (45.0 - i * 12.0)
			feather.position.x = dir * length * 0.5
			fan.add_child(feather)
			pivot.add_child(fan)


func _process(delta: float) -> void:
	_time += delta
	var flap := deg_to_rad(5.0 + sin(_time * FLAP_SPEED) * FLAP_DEGREES)
	_left.rotation.y = -flap
	_right.rotation.y = flap
