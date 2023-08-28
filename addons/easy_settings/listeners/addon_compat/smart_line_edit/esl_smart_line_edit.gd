extends ESL
class_name ESLSmartLineEdit


## Automatically binds itself with the SmartLineEdit given in [member smart_line_edit]

## If true, settings will be changed only when submitting the value (with
## [code]Enter[/code] or Submit button).
## If false each time value change, the setting will be changed.
@export var set_only_on_submit: bool = false:
	set(new_value):
		set_only_on_submit = new_value
		if smart_line_edit:
			_disconnect(smart_line_edit)
			_connect(smart_line_edit)

## The SmartLineEdit to wich this Listener is bound. Modifying this variable
## automatically connects/disconnects new/previous SmartLineEdit.
@export var smart_line_edit: SmartLineEdit:
	set(new_value):
		if smart_line_edit != null:
			# Disconnect to clean things up, seems to work even if
			# [method Callable.unbind] was called
			_disconnect(smart_line_edit)
		if new_value != null:
			_connect(new_value)
		smart_line_edit = new_value
		if start_synced and is_node_ready():
			force_update()


func get_value() -> Variant:
	if smart_line_edit == null:
		return
	return smart_line_edit.get_value()


func update_value(new_value: Variant, old_value: Variant, forced: bool = false) -> void:
	if smart_line_edit == null:
		return
	while not smart_line_edit.is_node_ready():
		await get_tree().process_frame
	if (
			sync == Sync.ALWAYS
			or smart_line_edit.last_valid_text == str(old_value)
			or forced
		):
		smart_line_edit.set_valid_text_without_update(str(new_value))


func _connect(to_connect: SmartLineEdit) -> void:
	if set_only_on_submit:
		to_connect.submitted.connect(set_value)
	else:
		to_connect.value_changed.connect(
			set_value.unbind(1) # Discard `old_value`
		)


func _disconnect(to_disconnect: SmartLineEdit) -> void:
	if to_disconnect.value_changed.is_connected(set_value):
		to_disconnect.value_changed.disconnect(set_value)
	
	if to_disconnect.submitted.is_connected(set_value):
		to_disconnect.submitted.disconnect(set_value)



