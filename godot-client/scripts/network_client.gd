class_name NetworkClient
extends Node

## Cliente fino: faz login, garante o farm ativo e assina os snapshots via
## WebSocket. Nunca calcula dano, XP ou drop — isso é autoritativo no servidor.

signal snapshot_received(snapshot: Dictionary)
signal info_received(message: String)
signal error_received(message: String)

const RECONNECT_DELAY_SEC := 3.0

var base_url := "http://localhost:3000"
var ws_url := "ws://localhost:3000/ws"
var spot_id := "spot_1"

var token := ""
var character_id := ""

var _socket := WebSocketPeer.new()
var _subscribed := false


func _ready() -> void:
	set_process(false)


## Login → escolhe personagem → farm/start → conecta no WebSocket.
func start(email: String, password: String, preset_character_id := "") -> void:
	var login := await _request("/auth/login", HTTPClient.METHOD_POST, {"email": email, "password": password})
	if login.is_empty():
		return
	token = login.get("token", "")

	character_id = preset_character_id
	if character_id.is_empty():
		var list := await _request("/characters", HTTPClient.METHOD_GET)
		var characters: Array = list.get("characters", [])
		if characters.is_empty():
			error_received.emit("Conta sem personagens — crie um via POST /characters")
			return
		character_id = characters[0]["id"]

	# Garante que o personagem está farmando no servidor antes de assinar.
	await _request("/characters/%s/farm/start" % character_id, HTTPClient.METHOD_POST, {"spotId": spot_id})
	_connect_socket()


func _connect_socket() -> void:
	_subscribed = false
	var err := _socket.connect_to_url(ws_url)
	if err != OK:
		error_received.emit("Falha ao conectar no WebSocket (%s)" % error_string(err))
		_schedule_reconnect()
		return
	set_process(true)


func _process(_delta: float) -> void:
	_socket.poll()
	match _socket.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if not _subscribed:
				_socket.send_text(JSON.stringify({"type": "subscribe", "token": token, "characterId": character_id}))
				_subscribed = true
			while _socket.get_available_packet_count() > 0:
				_handle_message(_socket.get_packet().get_string_from_utf8())
		WebSocketPeer.STATE_CLOSED:
			set_process(false)
			error_received.emit("Conexão perdida (código %d) — reconectando..." % _socket.get_close_code())
			_schedule_reconnect()


func _schedule_reconnect() -> void:
	# O servidor continua farmando sem o cliente; só precisamos voltar a assinar.
	await get_tree().create_timer(RECONNECT_DELAY_SEC).timeout
	_connect_socket()


func _handle_message(raw: String) -> void:
	var msg = JSON.parse_string(raw)
	if not msg is Dictionary:
		return
	match msg.get("type", ""):
		"snapshot":
			if msg.get("snapshot") is Dictionary:
				snapshot_received.emit(msg["snapshot"])
		"info":
			info_received.emit(str(msg.get("message", "")))
		"error":
			error_received.emit(str(msg.get("error", "erro desconhecido")))


func _request(path: String, method: int, body = null) -> Dictionary:
	var http := HTTPRequest.new()
	add_child(http)

	var headers := PackedStringArray(["Content-Type: application/json"])
	if not token.is_empty():
		headers.append("Authorization: Bearer " + token)
	var payload := "" if body == null else JSON.stringify(body)

	var err := http.request(base_url + path, headers, method, payload)
	if err != OK:
		http.queue_free()
		error_received.emit("Falha ao chamar %s (%s)" % [path, error_string(err)])
		return {}

	var result: Array = await http.request_completed
	http.queue_free()

	var status: int = result[0]
	var code: int = result[1]
	var text: String = (result[3] as PackedByteArray).get_string_from_utf8()
	if status != HTTPRequest.RESULT_SUCCESS:
		error_received.emit("Servidor inacessível em %s (%s)" % [base_url, path])
		return {}
	if code >= 400:
		error_received.emit("%s respondeu %d: %s" % [path, code, text])
		return {}

	var parsed = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}
