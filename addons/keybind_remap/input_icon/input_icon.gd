extends "res://addons/ActionIcon/ActionIcon.gd"
class_name InputIcon


## An icon that succinctly displays an [InputEvent]
##
## Just a bit modified from ["addons/ActionIcon/ActionIcon.gd"]


## Key texture without character on it, used as display in editor.
const blank = preload("res://addons/ActionIcon/Keyboard/Blank.png")


## Emitted when [method _refresh] has ended.
signal input_changed(input_event: InputEvent)


## The index of the input inside [member action_name] that this InputIcon displays.
@export var input_idx: int = 0:
	set(new):
		if new == input_idx:
			return
		input_idx = new
		refresh()
## If [code]null[/code], will be fetched trough [method fetch_input_event].
## Else, will display the given event.
@export var input_event: InputEvent:
	set(new):
		if new == input_event:
			return
		input_event = new
		refresh()
	get:
		if input_event == null:
			return fetch_input_event()
		
		return input_event

var _forced_refresh: bool = false


func _init() -> void:
	super()
	fit_mode = FitMode.CUSTOM
	InputIcon._default_size_setup(self)
	_base_path = "res://addons/ActionIcon/"


## Refresh, even if not visible in tree.
func force_refresh() -> void:
	_forced_refresh = true
	refresh()


## modified from [res://addons/ActionIcon/ActionIcon.gd] to let [member input_event] do it's job.
func _refresh() -> void:
	_pending_refresh = false
	
	if Engine.is_editor_hint() or (not _is_truely_visible_in_tree() and not _forced_refresh):
		return
	
	_forced_refresh = false
	
	var event = input_event # call getter
	if event == null:
		texture = blank
		return
		
	if event is InputEventKey:
		if event.keycode == 0:
			texture = get_keyboard(event.physical_keycode)
		else:
			texture = get_keyboard(event.keycode)
	elif event is InputEventMouseButton:
		texture = get_mouse(event.button_index)
	elif event is InputEventJoypadButton:
		texture = get_joypad(event.button_index, event.device)
	elif event is InputEventJoypadMotion:
		texture = get_joypad_axis(event.axis, event.axis_value, event.device)
	else:
		texture = blank

	if texture == null:
		texture = blank
		
	input_changed.emit(event)


func _is_truely_visible_in_tree() -> bool:
	if is_visible_in_tree():
		return true
	
	if get_parent() is InputDisplay:
		return get_parent().is_visible_in_tree()
	
	return false


## Get event from [InputMap] with [member "addons/ActionIcon/ActionIcon.gd".action_name] and [member input_idx].
## Returns [code]null[/code] if none is found.
func fetch_input_event() -> InputEvent:
	return _get_input_event_from_idx(action_name, input_idx)


## Get event from [InputMap] with given [param action_name] and [param input_idx].
## Returns [code]null[/code] if none is found.
static func _get_input_event_from_idx(action_name: StringName, input_idx: int) -> InputEvent:
	if action_name == &"":
		return null
	
	var events: Array[InputEvent] = InputMap.action_get_events(action_name)
	
	if -len(events) > input_idx or input_idx >= len(events):
#		push_error("Index {0} out of action's event input range.".format([input_idx]))
		return null
	
	return events[input_idx]


static func _default_size_setup(texture_rect: TextureRect) -> TextureRect:
	texture_rect.expand_mode = EXPAND_IGNORE_SIZE
	texture_rect.size_flags_horizontal = SIZE_SHRINK_CENTER
	texture_rect.size_flags_vertical = SIZE_SHRINK_CENTER
	texture_rect.custom_minimum_size = Vector2(48, 48)
	return texture_rect
