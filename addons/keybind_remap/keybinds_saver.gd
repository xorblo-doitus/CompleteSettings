extends Object
class_name KeybindsSaver


## This static class let save keybinds trough JSON
##
## You should call [method set_current_mapping_as_default] before loading or modifying
## any keybind.
## [br][br]
## Why JSON?
## [br][br]
## This is using JSON over Godot's serialization to let players share their keybinds
## without risking a script injection. (Godot's serialized objects can contain script)


const built_in_actions: Array[StringName] = [
	&"ui_accept",
	&"ui_select",
	&"ui_cancel",
	&"ui_focus_next",
	&"ui_focus_prev",
	&"ui_left",
	&"ui_right",
	&"ui_up",
	&"ui_down",
	&"ui_page_up",
	&"ui_page_down",
	&"ui_home",
	&"ui_end",
	&"ui_cut",
	&"ui_copy",
	&"ui_paste",
	&"ui_undo",
	&"ui_redo",
	&"ui_text_completion_query",
	&"ui_text_completion_accept",
	&"ui_text_completion_replace",
	&"ui_text_newline",
	&"ui_text_newline_blank",
	&"ui_text_newline_above",
	&"ui_text_indent",
	&"ui_text_dedent",
	&"ui_text_backspace",
	&"ui_text_backspace_word",
	&"ui_text_backspace_word.macos",
	&"ui_text_backspace_all_to_left",
	&"ui_text_backspace_all_to_left.macos",
	&"ui_text_delete",
	&"ui_text_delete_word",
	&"ui_text_delete_word.macos",
	&"ui_text_delete_all_to_right",
	&"ui_text_delete_all_to_right.macos",
	&"ui_text_caret_left",
	&"ui_text_caret_word_left",
	&"ui_text_caret_word_left.macos",
	&"ui_text_caret_right",
	&"ui_text_caret_word_right",
	&"ui_text_caret_word_right.macos",
	&"ui_text_caret_up",
	&"ui_text_caret_down",
	&"ui_text_caret_line_start",
	&"ui_text_caret_line_start.macos",
	&"ui_text_caret_line_end",
	&"ui_text_caret_line_end.macos",
	&"ui_text_caret_page_up",
	&"ui_text_caret_page_down",
	&"ui_text_caret_document_start",
	&"ui_text_caret_document_start.macos",
	&"ui_text_caret_document_end",
	&"ui_text_caret_document_end.macos",
	&"ui_text_caret_add_below",
	&"ui_text_caret_add_below.macos",
	&"ui_text_caret_add_above",
	&"ui_text_caret_add_above.macos",
	&"ui_text_scroll_up",
	&"ui_text_scroll_up.macos",
	&"ui_text_scroll_down",
	&"ui_text_scroll_down.macos",
	&"ui_text_select_all",
	&"ui_text_select_word_under_caret",
	&"ui_text_select_word_under_caret.macos",
	&"ui_text_add_selection_for_next_occurrence",
	&"ui_text_clear_carets_and_selection",
	&"ui_text_toggle_insert_mode",
	&"ui_menu",
	&"ui_text_submit",
	&"ui_graph_duplicate",
	&"ui_graph_delete",
	&"ui_filedialog_up_one_level",
	&"ui_filedialog_refresh",
	&"ui_filedialog_show_hidden",
	&"ui_swap_input_direction",
]


## Default ignored action when calling [method save_keybinds].
static var default_ignored_actions: Array[StringName] = built_in_actions
## Default save file path when calling [method save_keybinds].
static var default_path: String = "user://keybinds/custom.json"

## If true, only actions that where modified will be saved. Make sure to call
## [method set_action_as_modified] when modifying an action.
static var only_save_modified_actions: bool = true
## Actions that where marked as modified.
static var modified_actions: Array[StringName] = []


static var _default_actions: Dictionary = {}


## Set an action as modified, so it will be saved in case [member only_save_modified_actions] is true.
static func set_action_as_modified(action: StringName) -> void:
	if action not in modified_actions:
		modified_actions.push_back(action)


## Remove [param action] from modified actions, usefull if you reseted it back to default.
static func set_action_as_unmodified(action: StringName) -> void:
	modified_actions.erase(action)


## The current [InputMap]'s keybinds will be set as the default ones.
## Call [method reset] or [method reset_all] to load default actions.
## [br][br]
## It's a good idea to call this before loading any keybinds file.
static func set_current_mapping_as_default() -> void:
	_default_actions.clear()
	
	for action in InputMap.get_actions():
		var events: Array[InputEvent] = []
		
		for event in InputMap.action_get_events(action):
			events.push_back(event.duplicate())
		
		_default_actions[action] = events


## Reset an action back to it's orginal keybinds. See [method set_current_mapping_as_default]
static func reset(action: StringName) -> void:
	if action not in _default_actions:
		return
	
	set_action_as_unmodified(action)
	
	InputMap.action_erase_events(action)
	for event in _default_actions[action]:
		InputMap.action_add_event(action, event.duplicate())


## Call [method reset] for all actions that have defaults. See [method set_current_mapping_as_default]
static func reset_all() -> void:
	for action in _default_actions:
		reset(action)


static func get_default_event(action: StringName, idx: int) -> InputEvent:
	var events: Array[InputEvent] = []
	events = _default_actions.get(action, events) # Workaround for typed event creation
	
	if -len(events) > idx or idx >= len(events):
		return null
	
	return events[idx]


## Save all keybinds that where modified to a file. Make sur to call [method set_action_as_modified]
## or to set
static func save_keybinds(path: String = default_path, ignored_actions: Array[StringName] = default_ignored_actions) -> void:
	var data: Dictionary = {}
	
	for action in InputMap.get_actions():
		if (
			not only_save_modified_actions or action in modified_actions
		) and action not in ignored_actions:
			data[action] = _save_action(action)
	
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	
	if file == null:
		_print_file_error(path)
		return
	
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


static func _save_action(action: StringName) -> Array[Dictionary]:
	var saved_action: Array[Dictionary]
	
	
	if InputMap.action_get_deadzone(action) != 0.5:
		var action_properties: Dictionary = {
			&"class": &"action_properties",
			&"dead_zone": InputMap.action_get_deadzone(action)
		}
		saved_action.append(action_properties)
	
	for event in InputMap.action_get_events(action):
		saved_action.append(_save_event(event))
	
	return saved_action


static  func _save_event(event: InputEvent) -> Dictionary:
	var saved_event: Dictionary = {}
	
	_save_property(saved_event, event, &"device", 0)
	
	if event is InputEventWithModifiers:
		_save_property(saved_event, event, &"ctrl_pressed", false)
		_save_property(saved_event, event, &"alt_pressed", false)
		_save_property(saved_event, event, &"shift_pressed", false)
		_save_property(saved_event, event, &"meta_pressed", false)
		_save_property(saved_event, event, &"command_or_control_autoremap", false)
		
		if event is InputEventKey:
			saved_event[&"class"] = &"InputEventKey"
			_save_property(saved_event, event, &"keycode", 0)
			_save_property(saved_event, event, &"physical_keycode", 0)
			_save_property(saved_event, event, &"unicode", 0)
		
		if event is InputEventMouseButton:
			saved_event[&"class"] = &"InputEventMouseButton"
			_save_property(saved_event, event, &"button_index", 0)
			
	elif event is InputEventJoypadButton:
		saved_event[&"class"] = &"InputEventJoypadButton"
		_save_property(saved_event, event, &"button_index", 0)
		
	elif event is InputEventJoypadMotion:
		saved_event[&"class"] = &"InputEventJoypadMotion"
		_save_property(saved_event, event, &"axis", 0)
		
		
	return saved_event


static func _save_property(save: Dictionary, _object: Object, property: StringName, default: Variant) -> void:
	if _object.get(property) != default:
		save[property] = _object.get(property)


## Load keybinds from a file.
static func load_keybinds(path: String = default_path) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if FileAccess.get_open_error():
		_print_file_error(path)
		return
	
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	if data == null:
		push_error("Failed parsing {0} keybinds due to JSON error.".format([
			path,
		]))
		return
	
	InputMap.load_from_project_settings()
	for action in data:
		_load_action(action, data[action])


static func _load_action(action: StringName, data: Array) -> void:
	if InputMap.has_action(action):
		InputMap.action_erase_events(action)
	else:
		InputMap.add_action(action)
	
	for event in data:
		if event[&"class"] == &"action_properties":
			InputMap.action_set_deadzone(action, event.get(&"dead_zone", 0.5))
		else:
			InputMap.action_add_event(action, _load_event(event))
	
	if action not in modified_actions:
		modified_actions.push_back(action)


static func _load_event(event: Dictionary) -> InputEvent:
	var new_event: InputEvent
	
	match event["class"]:
		&"InputEventKey": new_event = InputEventKey.new()
		&"InputEventMouseButton": new_event = InputEventMouseButton.new()
		&"InputEventJoypadButton": new_event = InputEventJoypadButton.new()
		&"InputEventJoypadMotion": new_event = InputEventJoypadMotion.new()
	
	if new_event is InputEventWithModifiers:
		_load_property(event, new_event, &"ctrl_pressed")
		_load_property(event, new_event, &"alt_pressed")
		_load_property(event, new_event, &"shift_pressed")
		_load_property(event, new_event, &"meta_pressed")
		
		if new_event is InputEventKey:
			_load_property(event, new_event, &"keycode")
			_load_property(event, new_event, &"physical_keycode")
			_load_property(event, new_event, &"unicode")
		
		if new_event is InputEventMouseButton:
			_load_property(event, new_event, &"button_index")
	
	elif new_event is InputEventJoypadButton:
		_load_property(event, new_event, &"button_index")
	
	elif new_event is InputEventJoypadMotion:
		_load_property(event, new_event, &"axis")
	
	return new_event


static func _load_property(save: Dictionary, _object: Object, property: StringName) -> void:
	if save.has(property): # Could not be included if default
		_object.set(property, save[property])


static func _print_file_error(path: String) -> void:
	push_error("Error saving keybinds at {2} due to file opening error n°{0}: {1}".format([
		FileAccess.get_open_error(),
		error_string(FileAccess.get_open_error()),
		path,
	]))

