class_name Hud
extends CanvasLayer

## HUD simples: nível, HP, XP, ouro e uma linha de log (level up, erros).

var _level_label := Label.new()
var _hp_label := Label.new()
var _xp_label := Label.new()
var _gold_label := Label.new()
var _log_label := Label.new()
var _last_level := -1


func _ready() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(16, 16)
	add_child(box)
	for label in [_level_label, _hp_label, _xp_label, _gold_label, _log_label]:
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_constant_override("outline_size", 6)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		box.add_child(label)
	_log_label.modulate = Color(0.85, 0.85, 0.85)
	log_message("Conectando...")


func apply(snapshot: Dictionary) -> void:
	var s: Dictionary = snapshot.get("stats", {})
	if s.is_empty():
		return
	var level := int(s.get("level", 0))
	_level_label.text = "Nv. %d" % level
	_hp_label.text = "HP %d / %d" % [int(s.get("hp", 0)), int(s.get("hpMax", 0))]
	_xp_label.text = "XP %d / %d" % [int(s.get("xp", 0)), int(s.get("xpMax", 0))]
	_gold_label.text = "Ouro %d" % int(s.get("gold", 0))

	if _last_level >= 0 and level > _last_level:
		log_message("Level up! Nível %d" % level)
	elif _last_level < 0:
		log_message("")
	_last_level = level


func log_message(message: String) -> void:
	_log_label.text = message
