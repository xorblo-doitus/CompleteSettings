extends ESL
class_name ESLBaseButton

## Automatically binds itself with the [BaseButton] given in [member base_button].
## 
## Many controls inherits from [BaseButton] : [CheckBox], [CheckButton] etc...
## But this ESL is meant to work with the ones wich have their
## [member BaseButton.toggle_mode] set to true.


## The BaseButton to wich this Listener is bound. Modifying this variable
## automatically connects/disconnects new/previous BaseButton.
@export var base_button: BaseButton:
	set(new_value):
		if base_button != null:
			_disconnect(base_button)
		if new_value != null:
			_connect(new_value)
		base_button = new_value
		if start_synced and is_node_ready():
			force_update()


func get_value() -> bool:
	if base_button == null:
		return false
	return base_button.button_pressed


func update_value(new_value: bool, old_value, forced: bool = false) -> void:
	if (
			sync == Sync.ALWAYS
			or (_is_no_value(old_value) or base_button.button_pressed == old_value)
			or forced
		) and base_button != null:
		base_button.set_pressed_no_signal(new_value)


func _connect(to_connect: BaseButton) -> void:
	to_connect.toggled.connect(set_value)


func _disconnect(to_disconnect: BaseButton) -> void:
	if to_disconnect.toggled.is_connected(set_value): # Just in case
		to_disconnect.toggled.disconnect(set_value)
