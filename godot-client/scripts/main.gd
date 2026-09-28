extends Node3D

## Ponto de montagem: constrói a cena (chão, personagem, 6 spots de mob, câmera,
## HUD) e liga os sinais do NetworkClient às views.

const CONFIG_PATH := "res://dev_config.cfg"

# Arco na frente do personagem; índice = índice do slot no servidor (0-5).
const SLOT_POSITIONS: Array[Vector3] = [
	Vector3(0, 0, -2), Vector3(2, 0, -3), Vector3(4, 0, -2),
	Vector3(1, 0, 1), Vector3(3, 0, 1), Vector3(5, 0, 1),
]

var _network := NetworkClient.new()
var _hud := Hud.new()
var _slots: Array[MobSlotView] = []


func _ready() -> void:
	_build_world()
	add_child(_hud)
	add_child(_network)

	_network.snapshot_received.connect(_on_snapshot)
	_network.info_received.connect(func(msg: String): print("[servidor] ", msg); _hud.log_message(msg))
	_network.error_received.connect(func(msg: String): push_warning("[servidor] " + msg); _hud.log_message(msg))

	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		_hud.log_message("Crie dev_config.cfg a partir de dev_config.example.cfg")
		return
	_network.base_url = config.get_value("server", "base_url", _network.base_url)
	_network.ws_url = config.get_value("server", "ws_url", _network.ws_url)
	_network.spot_id = config.get_value("character", "spot_id", _network.spot_id)
	_network.start(
		config.get_value("account", "email", ""),
		config.get_value("account", "password", ""),
		config.get_value("character", "id", ""),
	)


func _on_snapshot(snapshot: Dictionary) -> void:
	_hud.apply(snapshot)
	var target = snapshot.get("currentTargetIndex")
	for slot in snapshot.get("mobSlots", []):
		var index := int(slot.get("index", -1))
		if index < 0 or index >= _slots.size():
			continue
		_slots[index].apply(slot, target != null and int(target) == index)


func _build_world() -> void:
	var camera := IsometricCamera.new()
	add_child(camera)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.shadow_enabled = true
	add_child(sun)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.07, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.6)
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 30)
	plane.material = _flat_material(Color(0.16, 0.17, 0.15))
	ground.mesh = plane
	add_child(ground)

	# Personagem fixo no spot: não anda, só "ataca" (o alvo muda de cor).
	var player := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.material = _flat_material(Color(0.23, 0.56, 0.56))
	player.mesh = capsule
	player.position = Vector3(-4, 1, 0)
	add_child(player)

	for i in SLOT_POSITIONS.size():
		var slot := MobSlotView.new()
		slot.name = "MobSlot_%d" % i
		slot.position = SLOT_POSITIONS[i]
		add_child(slot)
		_slots.append(slot)


static func _flat_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material
