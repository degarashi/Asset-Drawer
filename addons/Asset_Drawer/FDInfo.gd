extends RefCounted

var dock: FileSystemDock
var split_container: SplitContainer
var tree: Tree
var container: VBoxContainer


func _init(d: FileSystemDock) -> void:
	dock = d

	split_container = _find_split_container_recursive(dock)
	tree = _find_tree_recursive(split_container)

	for child in split_container.get_children():
		if child is VBoxContainer:
			container = child as VBoxContainer
			break

	assert(split_container)
	assert(tree)
	assert(container)


func is_split_view() -> bool:
	return container.visible


func _find_split_container_recursive(node: Node) -> SplitContainer:
	if node is SplitContainer:
		return node as SplitContainer

	for child in node.get_children():
		var found := _find_split_container_recursive(child)
		if found:
			return found

	return null


func _find_tree_recursive(node: Node) -> Tree:
	if node is Tree:
		return node as Tree

	for child in node.get_children():
		var found := _find_tree_recursive(child)
		if found:
			return found

	return null
