extends Node3D

@export var interactable_resource: Interactable
@export var aura_mesh: MeshInstance3D

var _being_targeted := false :
	set(value):
		_being_targeted = value

func _process(_delta):
	var material = aura_mesh.get_active_material(0)
	if not material:
		return
	material.set("shader_parameter/BeingTargeted", 0 if _being_targeted else 1)
