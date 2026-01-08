extends EditorInspectorPlugin

signal select_resource(path: String)


func _can_handle(object: Object) -> bool:
	var res := object as Resource
	if res:
		select_resource.emit(res.resource_path)
	return false
