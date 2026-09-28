class_name MobSlotView
extends Node3D

## Um dos 6 spots de mob. Puramente cosmético: mostra/esconde o mob, ajusta a
## barra de HP e solta números de dano quando o HP cai entre snapshots.

const COLOR_NORMAL := Color(0.63, 0.22, 0.22)
const COLOR_TARGET := Color(0.87, 0.76, 0.29)

var _model: MeshInstance3D
var _material := StandardMaterial3D.new()
var _hp_pivot: Node3D
var _name_label: Label3D
var _respawn_indicator: MeshInstance3D
var _last_hp := -1


func _init() -> void:
	_material.albedo_color = COLOR_NORMAL

	_model = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.material = _material
	_model.mesh = box
	_model.position.y = 0.5
	add_child(_model)

	# Barra de HP em pé e girada no mesmo yaw da câmera isométrica, pra ficar
	# de frente pra ela. O pivô fica na ponta esquerda: escalar X esvazia da direita.
	var hp_bar := Node3D.new()
	hp_bar.position.y = 0.85
	hp_bar.rotation_degrees.y = 45
	_model.add_child(hp_bar)

	var hp_background := _make_bar(Color(0.1, 0.1, 0.1))
	hp_bar.add_child(hp_background)

	_hp_pivot = Node3D.new()
	_hp_pivot.position = Vector3(-0.5, 0, 0.01)
	hp_bar.add_child(_hp_pivot)
	var hp_fill := _make_bar(Color(0.9, 0.8, 0.2))
	hp_fill.position.x = 0.5
	_hp_pivot.add_child(hp_fill)

	_name_label = Label3D.new()
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.position.y = 1.1
	_name_label.font_size = 28
	_name_label.outline_size = 6
	_model.add_child(_name_label)

	_respawn_indicator = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.5
	disc.bottom_radius = 0.5
	disc.height = 0.02
	var ghost := StandardMaterial3D.new()
	ghost.albedo_color = Color(0.6, 0.6, 0.6, 0.35)
	ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disc.material = ghost
	_respawn_indicator.mesh = disc
	add_child(_respawn_indicator)


func apply(slot: Dictionary, is_target: bool) -> void:
	var mob = slot.get("mob")
	var alive: bool = mob is Dictionary and int(mob.get("hp", 0)) > 0

	_model.visible = alive
	_respawn_indicator.visible = not alive
	if not alive:
		_last_hp = -1
		return

	var hp := int(mob["hp"])
	var hp_max := int(mob.get("hpMax", 0))
	_hp_pivot.scale.x = clampf(float(hp) / hp_max, 0.0, 1.0) if hp_max > 0 else 0.0
	_material.albedo_color = COLOR_TARGET if is_target else COLOR_NORMAL
	_name_label.text = str(mob.get("name", ""))

	if _last_hp > hp:
		_spawn_damage_number(_last_hp - hp)
	_last_hp = hp


func _spawn_damage_number(amount: int) -> void:
	var label := Label3D.new()
	label.text = str(amount)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 72
	label.outline_size = 12
	label.modulate = Color(1, 0.9, 0.4)
	label.position = Vector3(randf_range(-0.3, 0.3), 1.4, 0)
	add_child(label)

	var tween := create_tween().set_parallel()
	tween.tween_property(label, "position:y", 2.2, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(label.queue_free)


static func _make_bar(color: Color) -> MeshInstance3D:
	var bar := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1, 0.1, 0.01)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = material
	bar.mesh = mesh
	return bar
