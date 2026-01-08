extends RefCounted

var dock: FileSystemDock
var split_container: SplitContainer
var tree: Tree
var container: VBoxContainer


func _init(d: FileSystemDock) -> void:
	dock = d
	split_container = dock.get_child(3) as SplitContainer
	tree = split_container.get_child(0) as Tree
	container = split_container.get_child(1) as VBoxContainer
	assert(split_container)
	assert(tree)
	assert(container)


func is_split_view() -> bool:
	return container.visible
