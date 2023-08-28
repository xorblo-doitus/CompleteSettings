extends "input_mapper_entry.gd"


signal input_removed()


func _on_remove_button_pressed() -> void:
	remove()


func remove() -> void:
	InputMap.action_erase_event(
		action_name,
		InputIcon._get_input_event_from_idx(action_name, input_idx)
	)
	KeybindsSaver.set_action_as_modified(action_name)
	KeybindsSaver.save_keybinds()
	input_removed.emit()
