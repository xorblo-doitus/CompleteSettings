extends ESL
class_name ESLOptionButton

## Automatically binds itself with the [OptionButton] given in [member option_button].


## The OptionButton to wich this Listener is bound. Modifying this variable
## automatically connects/disconnects new/previous OptionButton.
@export var option_button: OptionButton:
	set(new_value):
		if option_button != null:
			_disconnect(option_button)
		if new_value != null:
			_connect(new_value)
		option_button = new_value
		if start_synced and is_node_ready():
			force_update()
## If true, the value saved will be the index of the item instead of the id.
@export var save_index: bool = true


func get_value() -> int:
	if option_button == null:
		return false
	
	if save_index:
		return option_button.selected
	
	return option_button.get_selected_id()


func update_value(new_value: int, old_value, forced: bool = false) -> void:
	if (
			sync == Sync.ALWAYS
			or (_is_no_value(old_value) or option_button.selected == old_value)
			or forced
		) and option_button != null:
		if save_index:
			option_button.selected = new_value
		else:
			option_button.selected = option_button.get_item_index(new_value)


func _connect(to_connect: OptionButton) -> void:
	to_connect.item_selected.connect(set_value.unbind(1))


func _disconnect(to_disconnect: OptionButton) -> void:
	if to_disconnect.item_selected.is_connected(set_value): # Just in case
		to_disconnect.item_selected.disconnect(set_value)
