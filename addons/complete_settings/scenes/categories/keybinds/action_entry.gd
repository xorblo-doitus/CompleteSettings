extends "input_mapper_entry.gd"


signal input_added()


@export var input_chooser: InputChooser:
	get:
		if input_chooser == null:
			return input_mapper.input_chooser
		
		return input_chooser


func _ready() -> void:
	super()
	if InputMap.action_get_events(action_name).is_empty():
		$InputMapper.hide()


func choose_new_event() -> void:
	if input_chooser.request_remap(null):
		input_chooser.choosed.connect(_on_choosed, CONNECT_ONE_SHOT)


func add_event(new_event: InputEvent) -> void:
	InputMap.action_add_event(action_name, new_event)
	KeybindsSaver.set_action_as_modified(action_name)
	KeybindsSaver.save_keybinds()
	input_added.emit()


func _on_add_button_pressed() -> void:
	choose_new_event()


func _on_choosed(new_event: InputEvent) -> void:
	if new_event == null:
		return
	
	add_event(new_event)
