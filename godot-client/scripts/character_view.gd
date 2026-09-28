class_name CharacterView
extends Node3D

## Modelo rigado (rig KayKit) com slots de equipamento presos aos ossos.
## Arma, asa, capacete etc. são modelos separados encaixados via equip(), para
## que o item equipado no servidor decida o que aparece — sem modelo por combinação.

# Slot → osso do rig. Todos os personagens KayKit compartilham esse esqueleto,
# então qualquer item encaixa em qualquer classe.
const SLOT_BONES := {
	"weapon_r": "handslot.r",
	"weapon_l": "handslot.l",
	"helmet": "head",
	"wings": "chest",
}

# Ajuste fino de cada slot (vem das posições dos itens embutidos no rig original).
const SLOT_OFFSETS := {
	"weapon_r": Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0.033, 0)),
	"weapon_l": Transform3D(Basis.IDENTITY, Vector3(0, 0.017, 0)),
}

# Slots cujos itens são modelados no espaço do personagem (asa: +Y cima, +Z
# frente), não no do osso — o encaixe desfaz a rotação de repouso do osso.
const CHARACTER_SPACE_SLOTS := ["wings", "helmet"]

signal animation_done(anim_name: StringName)

var model: Node3D
var skeleton: Skeleton3D
var anim: AnimationPlayer
var idle_animation: StringName

var _return_to_idle := true
var _attachments := {} # slot -> BoneAttachment3D
var _equipped := {} # slot -> Node3D


func _init(scene: PackedScene, idle := &"Idle") -> void:
	model = scene.instantiate()
	add_child(model)
	skeleton = model.find_children("*", "Skeleton3D")[0]
	anim = model.find_children("*", "AnimationPlayer")[0]
	idle_animation = idle
	if anim.has_animation(idle):
		anim.get_animation(idle).loop_mode = Animation.LOOP_LINEAR
	anim.animation_finished.connect(_on_animation_finished)


func _ready() -> void:
	play_idle()


## Esconde as peças que já vêm no modelo (armas, escudos, capa...) pelo nome.
func set_parts_visible(part_names: Array, visible_flag: bool) -> void:
	for part_name in part_names:
		var part := model.find_child(part_name, true, false)
		if part is Node3D:
			part.visible = visible_flag


## Encaixa um item num slot, substituindo o que estava lá.
func equip(slot: String, item: Node3D) -> void:
	unequip(slot)
	var attachment := _attachment_for(slot)
	var offset: Transform3D = SLOT_OFFSETS.get(slot, Transform3D.IDENTITY)
	if slot in CHARACTER_SPACE_SLOTS:
		var bone := skeleton.find_bone(SLOT_BONES[slot])
		offset = Transform3D(skeleton.get_bone_global_rest(bone).basis.inverse(), Vector3.ZERO)
	item.transform = offset * item.transform
	attachment.add_child(item)
	_equipped[slot] = item


func unequip(slot: String) -> void:
	if _equipped.has(slot):
		_equipped[slot].queue_free()
		_equipped.erase(slot)


func play_idle() -> void:
	if anim.has_animation(idle_animation):
		anim.play(idle_animation, 0.2)


## Toca uma animação uma vez; por padrão volta para o idle ao terminar
## (morte, por exemplo, deve ficar parada no último frame).
func play_once(anim_name: StringName, speed := 1.0, return_to_idle := true) -> void:
	if not anim.has_animation(anim_name):
		return
	_return_to_idle = return_to_idle
	anim.play(anim_name, 0.1, speed)


func _on_animation_finished(anim_name: StringName) -> void:
	animation_done.emit(anim_name)
	if anim_name != idle_animation and _return_to_idle:
		play_idle()


func _attachment_for(slot: String) -> BoneAttachment3D:
	if _attachments.has(slot):
		return _attachments[slot]
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = SLOT_BONES[slot]
	skeleton.add_child(attachment)
	_attachments[slot] = attachment
	return attachment
