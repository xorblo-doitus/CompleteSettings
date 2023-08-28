extends ESL
class_name ESLSliderSpinBox


## Automatically binds itself with the SliderSpinBox given in [member slider_spin_box]

## The SliderSpinBox to wich this Listener is bound. Modifying this variable
## automatically connects/disconnects new/previous SliderSpinBox.
@export var slider_spin_box: SliderSpinBox:
	set(new_value):
		if slider_spin_box != null:
			_disconnect(slider_spin_box)
		if new_value != null:
			_connect(new_value)
		slider_spin_box = new_value
		if start_synced and is_node_ready():
			force_update()


func get_value() -> float:
	if slider_spin_box == null:
		return 0
	return slider_spin_box.value


func update_value(new_value: float, old_value: Variant, forced: bool = false) -> void:
	if slider_spin_box == null:
		return
	while not slider_spin_box.is_node_ready():
		await get_tree().process_frame
	if (
			sync == Sync.ALWAYS
			or (_is_no_value(old_value) or slider_spin_box.value == old_value)
			or forced
		):
		slider_spin_box.set_value_no_signal(new_value)


func _connect(to_connect: SliderSpinBox) -> void:
	to_connect.value_changed.connect(set_value)


func _disconnect(to_disconnect: SliderSpinBox) -> void:
	if to_disconnect.value_changed.is_connected(set_value): # Just in case
		to_disconnect.value_changed.disconnect(set_value)
