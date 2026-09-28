class_name ItemVisuals
extends RefCounted

## Catálogo visual: id do item → modelo 3D. Quando o equipamento vier do
## servidor, o templateId do item resolve aqui o que encaixar em cada slot.

const SCENES := {
	"sword_1h": "res://assets/kaykit_adventurers/items/sword_1handed.gltf",
}


static func make(item_id: String) -> Node3D:
	if item_id == "wings_placeholder":
		return WingsPlaceholder.new()
	if SCENES.has(item_id):
		return (load(SCENES[item_id]) as PackedScene).instantiate()
	push_warning("[ItemVisuals] item sem modelo: " + item_id)
	return Node3D.new()
