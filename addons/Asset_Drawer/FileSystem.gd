@tool
extends EditorPlugin

## The root scene
const ROOT: StringName = &"root"
## Padding from the bottom when popped out
const PADDING: int = 20
## Padding from the bottom when not popped out
const BOTTOM_PADDING: int = 60
## Minimum height of the dock
const MIN_HEIGHT: int = 50


## The file system
class FileDockInfo:
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


var fd_info: FileDockInfo
var asset_drawer_shortcut: InputEventKey = InputEventKey.new()

## Toggle for when the file system is moved to bottom
var files_bottom: bool = false
var new_size: Vector2
var initial_load: bool = false
var showing: bool = false


func _enter_tree() -> void:
	# Add tool button to move shelf to editor bottom
	add_tool_menu_item("Files to Bottom", files_to_bottom)

	# Get our file system
	fd_info = FileDockInfo.new(EditorInterface.get_file_system_dock())

	await get_tree().create_timer(0.1).timeout
	files_to_bottom()

	# Prevent file tree from being shrunk on load
	await get_tree().create_timer(0.1).timeout
	fd_info.split_container.split_offset = 175

	# Get shortcut
	asset_drawer_shortcut = (
		preload("res://addons/Asset_Drawer/AssetDrawerShortcut.tres") as InputEventKey
	)


#region show hide filesystem
func _input(event: InputEvent) -> void:
	if not files_bottom:
		return

	if asset_drawer_shortcut.is_match(event) and event.is_pressed() and not event.is_echo():
		if showing:
			hide_bottom_panel()
		else:
			make_bottom_panel_item_visible(fd_info.dock)

		showing = not showing


#endregion


func _exit_tree() -> void:
	remove_tool_menu_item("Files to Bottom")
	files_to_bottom()


func _process(_delta: float) -> void:
	var window := fd_info.dock.get_window()
	new_size = window.size

	# Keeps the file system from being unusable in size
	if window.name == ROOT and not files_bottom:
		fd_info.tree.size.y = new_size.y - PADDING
		fd_info.container.size.y = new_size.y - PADDING
		return

	# Adjust the size of the file system based on how far up
	# the drawer has been pulled
	if window.name == ROOT and files_bottom:
		var dock_container := fd_info.dock.get_parent() as Control
		new_size = dock_container.size
		var editorsettings := EditorInterface.get_editor_settings()
		var fontsize: int = editorsettings.get_setting("interface/editor/main_font_size")
		var editorscale := EditorInterface.get_editor_scale()

		var sz_y := new_size.y - (fontsize * 2) - (BOTTOM_PADDING * editorscale)
		fd_info.tree.size.y = sz_y
		fd_info.container.size.y = sz_y
		return

	# Keeps our systems sized when popped out
	if window.name != ROOT and not files_bottom:
		window.min_size.y = MIN_HEIGHT
		fd_info.tree.size.y = new_size.y - PADDING
		fd_info.container.size.y = new_size.y - PADDING

		# Centers window on first pop
		if not initial_load:
			initial_load = true
			var screen_size: Vector2 = DisplayServer.screen_get_size()
			window.position = screen_size / 2


# Moves the files between the bottom panel and the original dock
func files_to_bottom() -> void:
	if files_bottom:
		remove_control_from_bottom_panel(fd_info.dock)
		add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, fd_info.dock)
		files_bottom = false
		return

	fd_info = FileDockInfo.new(EditorInterface.get_file_system_dock())
	remove_control_from_docks(fd_info.dock)
	add_control_to_bottom_panel(fd_info.dock, "File System")
	files_bottom = true
