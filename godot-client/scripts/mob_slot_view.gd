class_name MobSlotView
extends Node3D

## Um dos 6 spots de mob. Puramente cosmético: anima o mob (surgir, levar golpe,
## morrer), ajusta a barra de HP e solta números de dano quando o HP cai.

const MOB_SCENE := preload("res://assets/kaykit_skeletons/Skeleton_Minion.glb")
const MOB_SCALE := 0.65
const BAR_HEIGHT := 1.75

var _character: CharacterView
var _overhead: Node3D
var _hp_pivot: Node3D
var _name_label: Label3D
var _target_ring: MeshInstance3D
var _respawn_indicator: MeshInstance3D
var _last_hp := -1


func _init() -> void:
	_character = CharacterView.new(MOB_SCENE, &"Idle")
	_character.scale = Vector3.ONE * MOB_SCALE
	_character.animation_done.connect(_on_animation_done)
	add_child(_character)

	# Barra de HP e nome ficam fora do modelo, pra não girar junto com ele. A
	# barra fica em pé e girada no yaw da câmera isométrica, de frente pra ela.
	# O pivô fica na ponta esquerda: escalar X esvazia da direita.
	_overhead = Node3D.new()
	add_child(_overhead)

	var hp_bar := Node3D.new()
	hp_bar.position.y = BAR_HEIGHT
	hp_bar.rotation_degrees.y = 45
	_overhead.add_child(hp_bar)
	hp_bar.add_child(_make_bar(Color(0.1, 0.1, 0.1)))

	_hp_pivot = Node3D.new()
	_hp_pivot.position = Vector3(-0.5, 0, 0.01)
	hp_bar.add_child(_hp_pivot)
	var hp_fill := _make_bar(Color(0.85, 0.15, 0.15))
	hp_fill.position.x = 0.5
	_hp_pivot.add_child(hp_fill)

	_name_label = Label3D.new()
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.position.y = BAR_HEIGHT + 0.25
	_name_label.font_size = 28
	_name_label.outline_size = 6
	_overhead.add_child(_name_label)

	_target_ring = _make_disc(0.55, Color(0.95, 0.8, 0.25, 0.6))
	add_child(_target_ring)

	_respawn_indicator = _make_disc(0.45, Color(0.6, 0.6, 0.6, 0.3))
	add_child(_respawn_indicator)

	_set_alive(false)


## Faz o mob olhar para um ponto (o personagem). O rig KayKit olha para +Z.
func face(point: Vector3) -> void:
	_character.look_at(Vector3(point.x, _character.global_position.y, point.z), Vector3.UP, true)


## Aplica o estado do servidor. Retorna o dano sofrido desde o último snapshot.
func apply(slot: Dictionary, is_target: bool) -> int:
	var mob = slot.get("mob")
	var alive: bool = mob is Dictionary and int(mob.get("hp", 0)) > 0
	var was_alive := _last_hp > 0

	if not alive:
		var final_blow := 0
		_target_ring.visible = false
		if was_alive:
			# Golpe final: o servidor já removeu o mob, mostramos o que restava de HP.
			final_blow = _last_hp
			_spawn_damage_number(final_blow)
			_overhead.visible = false
			_character.play_once(&"Death_A", 1.5, false)
		elif _character.anim.current_animation != "Death_A":
			_set_alive(false)
		_last_hp = -1
		return final_blow

	var hp := int(mob["hp"])
	var hp_max := int(mob.get("hpMax", 0))
	_hp_pivot.scale.x = clampf(float(hp) / hp_max, 0.0, 1.0) if hp_max > 0 else 0.0
	_name_label.text = str(mob.get("name", ""))
	_target_ring.visible = is_target

	var damage := 0
	if not was_alive:
		_set_alive(true)
		_character.play_once(&"Spawn_Ground", 1.5)
	elif _last_hp > hp:
		damage = _last_hp - hp
		_spawn_damage_number(damage)
		_character.play_once(&"Hit_A", 1.5)
	_last_hp = hp
	return damage


func _on_animation_done(anim_name: StringName) -> void:
	if anim_name == &"Death_A" and _last_hp < 0:
		_set_alive(false)


func _set_alive(alive: bool) -> void:
	_character.visible = alive
	_overhead.visible = alive
	_respawn_indicator.visible = not alive
	if not alive:
		_target_ring.visible = false


func _spawn_damage_number(amount: int) -> void:
	var label := Label3D.new()
	label.text = str(amount)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 72
	label.outline_size = 12
	label.modulate = Color(1, 0.9, 0.4)
	label.position = Vector3(randf_range(-0.3, 0.3), BAR_HEIGHT + 0.3, 0)
	add_child(label)

	var tween := create_tween().set_parallel()
	tween.tween_property(label, "position:y", BAR_HEIGHT + 1.1, 0.8)
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


static func _make_disc(radius: float, color: Color) -> MeshInstance3D:
	var disc := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.02
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = material
	disc.mesh = mesh
	disc.position.y = 0.01
	return disc
