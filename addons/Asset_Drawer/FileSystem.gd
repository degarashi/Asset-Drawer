@tool
extends EditorPlugin

# Prevent continuous operation
const OPERATE_DELAY = 0.25
const OPERATE_KEY = KEY_ALT
## The root scene
const ROOT: StringName = &"root"
## Padding from the bottom when popped out
const PADDING: int = 20
## Padding from the bottom when not popped out
const BOTTOM_PADDING: int = 60
## Minimum height of the dock
const MIN_HEIGHT: int = 50

const FDInfo = preload("uid://cnhpfa51sruip")
const INSPECTOR = preload("uid://dbp3g3xta2t52")

var inspector: EditorInspectorPlugin
var fd_info: FDInfo
var asset_drawer_shortcut: InputEventKey = InputEventKey.new()

## Toggle for when the file system is moved to bottom
var files_bottom: bool = false
var new_size: Vector2
var initial_load: bool = false
var showing: bool = false

# Unix-time
var last_operated: float


func _enter_tree() -> void:
	# Add tool button to move shelf to editor bottom
	add_tool_menu_item("Files to Bottom", files_to_bottom)

	# Get our file system
	fd_info = FDInfo.new(EditorInterface.get_file_system_dock())

	await get_tree().create_timer(0.1).timeout
	files_to_bottom()

	# Prevent file tree from being shrunk on load
	await get_tree().create_timer(0.1).timeout
	fd_info.split_container.split_offset = 175

	# Get shortcuts
	asset_drawer_shortcut = preload("res://addons/Asset_Drawer/AssetDrawerShortcut.tres")

	inspector = INSPECTOR.new()
	inspector.select_resource.connect(_on_select_resource)
	add_inspector_plugin(inspector)

	var insp := EditorInterface.get_inspector()
	insp.property_selected.connect(_on_select_property)
	insp.edited_object_changed.connect(_on_obj_changed)


# last_operatedからOPERATE_DELAY分の時間が経っているか & 時間の更新
func _check_operate_interval() -> bool:
	if Time.get_unix_time_from_system() - last_operated < OPERATE_DELAY:
		return false
	last_operated = Time.get_unix_time_from_system()
	return true


func _open_path(path: String) -> void:
	assert(not path.is_empty())
	var ar := path.split(":")
	if ar.size() > 2:
		return

	if files_bottom:
		make_bottom_panel_item_visible(fd_info.dock)
	EditorInterface.select_file(path)


func _on_obj_changed() -> void:
	last_operated = Time.get_unix_time_from_system()
	# Open the .tscn associated with the node
	if Input.is_key_pressed(OPERATE_KEY):
		var insp := EditorInterface.get_inspector()
		var obj := insp.get_edited_object()
		var node := obj as Node
		if node:
			var path := node.scene_file_path
			if path.ends_with(".tscn"):
				_open_path(path)


func _on_select_property(property: String) -> void:
	if Input.is_key_pressed(OPERATE_KEY):
		var insp := EditorInterface.get_inspector()
		var obj := insp.get_edited_object()
		var res := obj.get(property) as Resource
		if res and not res.resource_path.is_empty():
			last_operated = Time.get_unix_time_from_system()
			_open_path(res.resource_path)


func _on_select_resource(path: String) -> void:
	await get_tree().create_timer(0.1).timeout
	if Input.is_key_pressed(OPERATE_KEY):
		if _check_operate_interval():
			_open_path(path)


#region show hide filesystem
func _input(event: InputEvent) -> void:
	if not files_bottom:
		return

	# Asset drawer toggle
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
	remove_inspector_plugin(inspector)


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

	fd_info = FDInfo.new(EditorInterface.get_file_system_dock())
	remove_control_from_docks(fd_info.dock)
	add_control_to_bottom_panel(fd_info.dock, "File System")
	files_bottom = true
