extends InputDisplay
class_name InputMapper


## Simple way to remap an [InputEvent]
##
## Can hold it's own event or be linked to [InputMap] if [member Display.action_name]
## and [member Display.input_idx] are valid.
## Invoke [member input_chooser] when clicked to remap it's event.


## Use this static variable to globally override the default [InputChosser] used by all [InputMapper]s
static var _default_input_chooser: InputChooser


## The [InputChooser] node used by this. Use [member _default_input_chooser] if [code]null[/code]
@export var input_chooser: InputChooser:
	get:
		if input_chooser == null:
			return _get_default_input_chooser()
		
		return input_chooser
## If null, will fetch default input from [KeybindsSaver]
@export var default_input: InputEvent:
	get:
		if default_input != null:
			return default_input
		
		return KeybindsSaver.get_default_event(action_name, input_idx)
## RESET_KEYBIND for default translation, tough default text is empty to display only the icon
@export var reset_button_text: String:
	set(new):
		if reset_button: reset_button.text = new
		else: _ready_sets[&"reset_button_text"] = new


@onready var reset_button: Button = $Reset


func adapt_to(event: InputEvent) -> void:
	super(event)
	update_reset_button_visiblity()


func choose(event: InputEvent, is_default: bool = false) -> void:
	if event == null:
		return
	
	if input_icon.fetch_input_event() == null:
		input_event = event
	
	if Engine.is_editor_hint() or !InputMap.has_action(action_name):
		return
	
	var events: Array[InputEvent] = InputMap.action_get_events(action_name)
	if -len(events) > input_idx or input_idx >= len(events):
		return
	
	events[input_idx] = event
	
	InputMap.action_erase_events(action_name)
	for action_event in events:
		InputMap.action_add_event(action_name, action_event)
	
	if not is_default:
		KeybindsSaver.set_action_as_modified(action_name)
	
	if is_inside_tree():
		get_tree().call_group(&"action_icons", &"refresh")
	elif input_chooser.is_inside_tree():
		input_chooser.get_tree().call_group(&"action_icons", &"refresh")
	
	KeybindsSaver.save_keybinds()


func reset() -> void:
	KeybindsSaver.set_action_as_unmodified(action_name)
	
	if default_input != null:
		choose(default_input, true)


func update_reset_button_visiblity() -> void:
	reset_button.visible = default_input != null and not default_input.is_match(input_event)


static func instantiate_default_input_chooser() -> InputChooser:
	var instance: InputChooser = load("res://addons/keybind_remap/input_chooser/default_input_chooser.tscn").instantiate()
	instance.hide()
	return instance


var _pressed: bool = false
func _gui_input(event: InputEvent) -> void:
	if _is_click(event):
		if _pressed:
			if not event.pressed:
				_pressed = false
				if get_global_rect().has_point(event.global_position):
					if input_chooser.request_remap(input_event):
						input_chooser.choosed.connect(_on_choosed, CONNECT_ONE_SHOT)
				
		elif event.pressed:
			_pressed = true


func _is_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT


func _get_default_input_chooser() -> InputChooser:
	if _default_input_chooser == null or not is_instance_valid(_default_input_chooser):
		if is_inside_tree():
			_default_input_chooser = instantiate_default_input_chooser()
			get_tree().root.add_child(_default_input_chooser)
		else:
			push_error("Input chooser is not set, default one nor, and this node is not inside the tree, so it can't create one.")
	return _default_input_chooser


func _on_choosed(event: InputEvent) -> void:
	choose(event)
