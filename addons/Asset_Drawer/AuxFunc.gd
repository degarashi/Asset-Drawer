extends Object

const FDInfo = preload("uid://cnhpfa51sruip")


# Actually, I should use navigate_to_path() of FileSystemDock,
# but if the file-browser is displayed at the bottom,
# an error message (ERROR: Cannot focus unknown dock --- ) will be displayed,
# so I need to do it manually.
static func navigate_to_path_manual(fd_info: FDInfo, path: String) -> void:
	var tree := fd_info.tree
	var root := tree.get_root()
	if not root:
		print("FileSystem tree root not found")
		return

	# Path segments after removing res://
	var parts := path.replace("res://", "").split("/")
	var last_part := parts[parts.size() - 1]
	if ":" in last_part:
		# Example: "MyScene.tscn:3" → keep only "MyScene.tscn"
		var base := last_part.split(":")[0]
		parts[parts.size() - 1] = base
		last_part = base

	var split_view := fd_info.is_split_view()
	if split_view:
		# Remove last part (file name) to keep only folder hierarchy
		parts.remove_at(parts.size() - 1)
	else:
		parts[parts.size() - 1] = last_part

	# Find "res://" node under root
	var cur := root.get_first_child()
	while cur:
		if cur.get_text(0) == "res://":
			break
		cur = cur.get_next()

	cur.set_collapsed_recursive(true)
	cur.set_collapsed(false)

	# Traverse parts
	for part in parts:
		var found := false
		var child := cur.get_first_child()

		while child:
			if child.get_text(0) == part:
				cur = child
				cur.set_collapsed(false)
				found = true
				break
			child = child.get_next()

		if not found:
			print("Path not found in FileSystem tree:", part)
			return

	tree.set_selected(cur, 0)
	if not split_view:
		tree.set_selected(cur, 0)
		tree.ensure_cursor_is_visible()
		tree.grab_focus()
	else:
		var target: ItemList = fd_info.container.get_child(1)
		for idx in target.item_count:
			if target.get_item_text(idx) == last_part:
				target.select(idx)
				target.ensure_current_is_visible()
				target.grab_focus()
				break
