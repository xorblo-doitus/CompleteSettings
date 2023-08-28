extends ESL
class_name ESLRange


## Automatically binds itself with the [Range] given in [member range]
## 
## Many controls inherits from [Range] : [HSlider], [VSlider], [SpinBox] etc...
## [br]You can see them in the [Range]'s documentation.


## The Range to wich this Listener is bound. Modifying this variable
## automatically connects/disconnects new/previous Range.
@export var range: Range:
	set(new_value):
		if range != null:
			_disconnect(range)
		if new_value != null:
			_connect(new_value)
		range = new_value
		if start_synced and is_node_ready():
			force_update()


func get_value() -> float:
	if range == null:
		return 0
	return range.value


func update_value(new_value: float, old_value, forced: bool = false) -> void:
	if (
			sync == Sync.ALWAYS
			or (_is_no_value(old_value) or range.value == old_value)
			or forced
		) and range != null:
		range.set_value_no_signal(new_value)


func _connect(to_connect: Range) -> void:
	to_connect.value_changed.connect(set_value)


func _disconnect(to_disconnect: Range) -> void:
	if to_disconnect.value_changed.is_connected(set_value): # Just in case
		to_disconnect.value_changed.disconnect(set_value)
