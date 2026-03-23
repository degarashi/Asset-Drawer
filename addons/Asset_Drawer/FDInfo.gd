extends RefCounted

# ------------- [Public Variable] -------------
var dock: FileSystemDock
var split_container: SplitContainer
var tree: Tree
var container: VBoxContainer


# ------------- [Callbacks] -------------
func _init(filesys_dock: FileSystemDock) -> void:
	dock = filesys_dock

	split_container = _find_split_container_recursive(dock)
	tree = _find_tree_recursive(split_container)

	# Find the main container for the file list
	for child in split_container.get_children():
		if child is VBoxContainer:
			container = child as VBoxContainer
			break

	# Validate essential nodes are found
	assert(split_container != null, "Fail: SplitContainer not found in FileSystemDock.")
	assert(tree != null, "Fail: Tree not found in FileSystemDock.")
	assert(container != null, "Fail: VBoxContainer not found in FileSystemDock.")


# ------------- [Private Method] -------------
# Helper to find SplitContainer within the node hierarchy
func _find_split_container_recursive(node: Node) -> SplitContainer:
	if node is SplitContainer:
		return node as SplitContainer

	for child in node.get_children():
		var found := _find_split_container_recursive(child)
		if found:
			return found

	return null


# Helper to find Tree within the node hierarchy
func _find_tree_recursive(node: Node) -> Tree:
	if node is Tree:
		return node as Tree

	for child in node.get_children():
		var found := _find_tree_recursive(child)
		if found:
			return found

	return null


# ------------- [Public Method] -------------
# Returns whether the FileSystemDock is currently in split view mode
func is_split_view() -> bool:
	return container.visible
