#@tool
extends VBoxContainerWithLines
class_name SettingGroup


## A Node grouping multiple [SettingEntry]s together, with collapse/expand capabilities.
## 
## Group multiple [SettingEntry]s and other [SettingGroup]s together, like a
## folder of a file system.

# Possible optimizations: 
# - Don't call sort on sub groups if they where already sorted at least one time

@export_group("Icons")
## The texture of the button that let expand the group.
@export var expand_texture: Texture2D:
	set(new):
		expand_texture = new
		_update_open_button_textures()
## The texture of the button that let collapse the group.
@export var collapse_texture: Texture2D:
	set(new):
		collapse_texture = new
		_update_open_button_textures()
## The texture displayed in front of child entries.
@export var tree_branch_texture: Texture2D:
	set(new):
		tree_branch_texture = new
		_update_tree_textures()

## The [member CanvasItem.modulate] applied to all previous textures.
@export var icon_modulate: Color = Color.WHITE:
	set(new_icon_modulate):
		icon_modulate = new_icon_modulate
		for icon in _icons:
			icon.modulate = icon_modulate
@export_group("")

## Wether this group is expanded or collapsed.
@export var open: bool = true:
	set(new_open):
		open = new_open
		_open_button.set_pressed_no_signal(open)
		_update_sub_entry_visibility()

@export_group("Tabulation", "tab_")
## The minimum width of tabulation created when entering a group
## Real width is the biggest between this and collapse button width.
@export var tab_minimum_width: float = 5
@export var tab_bonus_width: float = 14

@export_group("Guide", 'guide_')
## Set to 0 to disable
@export var guide_width: float = -1.0
@export_subgroup("Ticks", "guide_tick_")
## Set to 0 to disable
@export var guide_tick_width: float = -1.0
@export var guide_tick_offset_y: float = 0.0
@export var guide_tick_right_extend: float = 0.0
@export var guide_offset_x: float = 0
@export var guide_upper_retract: float = 4
## Set to (0, 0, 0, 0) to use [member icon_modulate]
@export var guide_color: Color = Color(0, 0, 0, 0):
	set(new):
		if new == Color(0, 0, 0, 0):
			guide_color = icon_modulate
		else:
			guide_color = new


# How much wide must the tree icon be to align entries.
var _spacing: int = 0:
	set(new):
		_spacing = new
		_update_spacings()
		
# First entry is always shown
var _entries: Array[Control] = []

## Warning: First entry is the open button, aka a [TextureRect] istead of a [SettingGroupIcon]
var _icons: Array[Control] = []

var _primary_entry: Control:
	get:
		return null if _entries.is_empty() else _entries[0]
		
# The first icon
var _open_button: TextureButton:
	get:
		return null if _icons.is_empty() else _icons[0]

# When search mode is true, entry detection will be disabled so it can be reloaded.
var _search_mode: bool = false:
	set(new):
		if new == _search_mode:
			return
		
		_search_mode = new
		
		if _search_mode:
			for icon in _icons:
				icon.get_parent().remove_child(icon)
		else:
			for entry in _entries:
				if entry.get_parent() != null:
					entry.get_parent().remove_child(entry)
				add_child(entry)


func _init() -> void:
	# Create the open button.
	var open_button: TextureButton = TextureButton.new()
	open_button.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
	open_button.toggle_mode = true
	open_button.toggled.connect(_on_open_button_toggled)
	open_button.set_pressed_no_signal(open)
	_icons.push_front(open_button)


func _ready() -> void:
	super()
	# trigger setters
	guide_color = guide_color


func _draw() -> void:
	if open and len(_icons) >= 2:
		line_margin_start = _icons[1].get_global_rect().end.x - get_global_rect().position.x
		super()
	
	if open and len(_icons) >= 2 and (guide_width or guide_tick_width):
		var line_start: Vector2 = (
			_get_control_center(_open_button)
			+ Vector2(guide_offset_x, 0)
		)
		if guide_width:
			draw_line(
				line_start + Vector2(0, guide_upper_retract),
				Vector2(line_start.x, _get_icon_texture_center(_icons[-1]).y),
				guide_color,
				guide_width,
				true # anti-aliased
			)
	
		if guide_tick_width:
			for i in range(1, len(_icons)):
				var center: Vector2 = (
					_get_icon_texture_center(_icons[i])
					+ Vector2(0, guide_tick_offset_y)
				)
				draw_line(
					Vector2(line_start.x, center.y),
					center + Vector2(guide_tick_right_extend, 0),
					guide_color,
					guide_tick_width,
					true # anti-aliased
				)


## Automatically called when sort_children is emitted. Make the magic of the
## tree happen.
func sort() -> void:
	if _search_mode:
		return
	
	_clear_data()
	
	# Fetch entries
	for child in get_children():
		if child is SettingEntry or child is SettingGroup:
			_entries.append(child)
	
	# Empty [SettingGroup] is bad.
	if len(_entries) == 0:
		_create_dummy_entry("_EMPTY")
		sort()
		return
	
	# When first entry is a [SettingGroup], it woulds display two open buttons.
	# One should add an empty entry as a group name
	if _primary_entry is SettingGroup:
		_create_dummy_entry("_SUB_GROUP")
	
	# Subgroups needs to be sorted before being able to compute spacing.
	for entry in _entries:
		if entry is SettingGroup:
			entry.sort()
	
	# Setup icons
	for idx in len(_entries):
		_append_icon(idx)
	
	# Clear unused icons
	for __ in len(_icons) - len(_entries):
		_icons.pop_back().queue_free()
	
	_update_sub_entry_visibility()
	_update_spacings()
	_open_button.visible = len(_entries) > 1 # Just in case somebody make an empty [SettingGroup]
	queue_redraw()
	

# Clear entries
func _clear_data() -> void:
	_entries.clear()


# Creates an icon and adds it to _icons
func _create_icon() -> Control:
	var icon: SettingGroupIcon = preload("res://addons/complete_settings/scenes/icon/icon.tscn").instantiate()
	icon.texture = tree_branch_texture
	icon.modulate = icon_modulate
	return icon


# Create an entry serving as a label
func _create_dummy_entry(text: String = "_DUMMY") -> SettingEntry:
	var new_entry: SettingEntry = preload("res://addons/complete_settings/scenes/setting_entry/setting_entry.tscn").instantiate()
	new_entry.setting_name = text
	add_child(new_entry)
	move_child(new_entry, 0)
	_entries.push_front(new_entry)
	return new_entry


# Literraly collapse or expand according to open
func _update_sub_entry_visibility() -> void:
	for entry in _entries.slice(1):
		entry.visible = open


func _update_open_button_textures() -> void:
	_open_button.texture_normal = expand_texture
	_open_button.texture_pressed = collapse_texture


func _update_tree_textures() -> void:
	for icon in _icons.slice(1):
		icon.texture = tree_branch_texture


func _update_spacings() -> void:
	# Find spacing
	_open_button.custom_minimum_size.x = 0
	_open_button.size.x = 0
	var tab_width: float = maxf(tab_minimum_width, _open_button.size.x)
	if tree_branch_texture:
		var possible_delta: int = tree_branch_texture.get_width() - collapse_texture.get_width()
		if possible_delta > 0:
			tab_width = maxf(tab_width, _open_button.size.x + possible_delta)
	var new_sub_spacing = _spacing + tab_width + tab_bonus_width
	
	if _spacing: # Don't add separation when not in a group
		new_sub_spacing += _primary_entry.get_theme_constant("separation")
	
	for idx in len(_entries): # not range(1, len), just in case of empty _entries
		if idx == 0:
			continue # Do not space open button
		
		_icons[idx].custom_minimum_size.x = new_sub_spacing
		
		# Update subgroups spacings
		var entry: Control = _entries[idx]
		if entry is SettingGroup:
			entry._spacing = new_sub_spacing


# Handle icon of entry number [param idx]
func _append_icon(idx: int) -> void:
	var entry: Control = _entries[idx]
	
	# Get existing icon or create one
	var icon: Control
	if idx < len(_icons):
		icon = _icons[idx]
		if not is_instance_valid(icon):
			icon = _create_icon()
			_icons[idx] = icon
	else:
		icon = _create_icon()
		_icons.append(icon)
	
		
	# Find the deepest _primary_entry, thus there should never be a SettingGroup
	# primary entry
	var new_parent: Control = entry
	while new_parent is SettingGroup:
		new_parent = new_parent._primary_entry
	
	#### Complicated stuff to prevent infinite _on_sort_children() loop ####
	# Unparent if was parented to something else
	var old_parent: Control = icon.get_parent()
	if old_parent and old_parent != new_parent:
		old_parent.remove_child(icon)
	
	# Reparent if new_parent exists and is different from previous one
	if new_parent and old_parent != new_parent:
		new_parent.add_child(icon, false, INTERNAL_MODE_FRONT)


func _on_sort_children() -> void:
	sort()


func _on_open_button_toggled(state: bool) -> void:
	open = state


func _get_icon_texture_center(icon: SettingGroupIcon) -> Vector2:
	return _get_control_center(icon.get_texture_rect())

## Return the center of the control in local coordinates
func _get_control_center(control: Control) -> Vector2:
	return control.get_global_rect().get_center() - global_position
