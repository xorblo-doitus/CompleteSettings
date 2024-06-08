extends "input_mapper_entry.gd"


signal input_removed()



## Defaults to [member KeybindsSaver.shared]
var keybinds_saver: KeybindsSaver:
	get:
		if keybinds_saver:
			return keybinds_saver
		return KeybindsSaver.shared


func _on_remove_button_pressed() -> void:
	remove()


func remove() -> void:
	InputMap.action_erase_event(
		action_name,
		InputIcon._get_input_event_from_idx(action_name, input_idx)
	)
	keybinds_saver.set_action_as_modified(action_name)
	keybinds_saver.save_keybinds()
	input_removed.emit()
