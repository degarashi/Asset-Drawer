@tool
extends EditorPlugin

# ------------- [Constants] -------------
# Prevent continuous operation
const OPERATE_DELAY = 0.25
## The root scene
const ROOT: StringName = &"root"
## Padding from the bottom when popped out
const PADDING: int = 20
## Padding from the bottom when not popped out
const BOTTOM_PADDING: int = 60
## Minimum height of the dock
const MIN_HEIGHT: int = 50

# [FDInfo.gd]
const FDInfo = preload("uid://cnhpfa51sruip")
# [Inspector.gd]
const INSPECTOR = preload("uid://dbp3g3xta2t52")

# ------------- [Public Variable] -------------
var inspector: EditorInspectorPlugin
var fd_info: FDInfo
var asset_drawer_shortcut: InputEventKey = InputEventKey.new()

## Toggle for when the file system is moved to bottom
var is_in_bottom_panel: bool = false
var new_size: Vector2
var initial_load: bool = false
var showing: bool = false

# Unix-time
var last_operated: float


# ------------- [Callbacks] -------------
func _enter_tree() -> void:
	# Add tool button to toggle shelf location
	add_tool_menu_item("Toggle File System Location", toggle_dock_location)

	# Get our file system
	fd_info = FDInfo.new(EditorInterface.get_file_system_dock())

	await get_tree().create_timer(0.1).timeout
	toggle_dock_location()

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


func _exit_tree() -> void:
	remove_tool_menu_item("Toggle File System Location")
	toggle_dock_location()
	remove_inspector_plugin(inspector)


func _process(_delta: float) -> void:
	var window := fd_info.dock.get_window()
	new_size = window.size

	# Keeps the file system from being unusable in size
	if window.name == ROOT and not is_in_bottom_panel:
		fd_info.tree.size.y = new_size.y - PADDING
		fd_info.container.size.y = new_size.y - PADDING
		return

	# Adjust the size of the file system based on how far up
	# the drawer has been pulled
	if window.name == ROOT and is_in_bottom_panel:
		var dock_container := fd_info.dock.get_parent()
		new_size = dock_container.size
		var editorsettings := EditorInterface.get_editor_settings()
		var fontsize: int = editorsettings.get_setting("interface/editor/main_font_size")
		var editorscale := EditorInterface.get_editor_scale()

		var sz_y := new_size.y - (fontsize * 2) - (BOTTOM_PADDING * editorscale)

		# Apply offset for Godot 4.6+ as a workaround
		var version_info := Engine.get_version_info()
		if version_info.major >= 4 and version_info.minor >= 6:
			sz_y += 25

		fd_info.tree.size.y = sz_y
		fd_info.container.size.y = sz_y
		return

	# Keeps our systems sized when popped out
	if window.name != ROOT and not is_in_bottom_panel:
		window.min_size.y = MIN_HEIGHT
		fd_info.tree.size.y = new_size.y - PADDING
		fd_info.container.size.y = new_size.y - PADDING

		# Centers window on first pop
		if not initial_load:
			initial_load = true
			var screen_size := DisplayServer.screen_get_size()
			window.position = screen_size / 2


func _input(event: InputEvent) -> void:
	if not is_in_bottom_panel:
		return

	# Asset drawer toggle
	if asset_drawer_shortcut.is_match(event) and event.is_pressed() and not event.is_echo():
		if showing:
			hide_bottom_panel()
		else:
			make_bottom_panel_item_visible(fd_info.dock)

		showing = not showing


# ------------- [Private Method] -------------
# Check if OPERATE_DELAY has passed since last_operated & Update time
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

	if is_in_bottom_panel:
		make_bottom_panel_item_visible(fd_info.dock)
	EditorInterface.select_file(path)


func _is_operate_key_pressed() -> bool:
	return (
		Input.is_key_pressed(KEY_ALT)
		and not Input.is_key_pressed(KEY_SHIFT)
		and not Input.is_key_pressed(KEY_CTRL)
		and not (
			Input.is_key_pressed(KEY_0)
			or Input.is_key_pressed(KEY_1)
			or Input.is_key_pressed(KEY_2)
			or Input.is_key_pressed(KEY_3)
			or Input.is_key_pressed(KEY_4)
			or Input.is_key_pressed(KEY_5)
			or Input.is_key_pressed(KEY_6)
			or Input.is_key_pressed(KEY_7)
			or Input.is_key_pressed(KEY_8)
			or Input.is_key_pressed(KEY_9)
		)
	)


func _on_obj_changed() -> void:
	last_operated = Time.get_unix_time_from_system()
	# Open the .tscn associated with the node
	if _is_operate_key_pressed():
		var insp := EditorInterface.get_inspector()
		var obj := insp.get_edited_object()
		var node := obj as Node
		if node:
			var path := node.scene_file_path
			if path.ends_with(".tscn"):
				_open_path(path)


func _on_select_property(property: String) -> void:
	if _is_operate_key_pressed():
		var insp := EditorInterface.get_inspector()
		var obj := insp.get_edited_object()
		var res := obj.get(property) as Resource
		if res and not res.resource_path.is_empty():
			last_operated = Time.get_unix_time_from_system()
			_open_path(res.resource_path)


func _on_select_resource(path: String) -> void:
	await get_tree().create_timer(0.1).timeout
	if _is_operate_key_pressed():
		if _check_operate_interval():
			_open_path(path)


static func _remove_from_parent(node: Node) -> void:
	var p_node := node.get_parent()
	if p_node:
		p_node.remove_child(node)


# ------------- [Public Method] -------------
## Toggles the FileSystem dock between the bottom panel and the original dock slot
func toggle_dock_location() -> void:
	if is_in_bottom_panel:
		remove_control_from_bottom_panel(fd_info.dock)
		add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, fd_info.dock)
		is_in_bottom_panel = false
		return

	_remove_from_parent(fd_info.dock)
	add_control_to_bottom_panel(fd_info.dock, "File System")
	is_in_bottom_panel = true
