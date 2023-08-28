extends ESL
class_name ESLLineEdit


## Automatically binds itself with the LineEdit given in [member line_edit]

## If true, settings will be changed only when submitting the value (with
## [code]Enter[/code]).
## If false each time value change, the setting will be changed.
@export var set_only_on_submit: bool = false:
	set(new_value):
		set_only_on_submit = new_value
		if line_edit:
			_disconnect(line_edit)
			_connect(line_edit)

## The LineEdit to wich this Listener is bound. Modifying this variable
## automatically connects/disconnects new/previous LineEdit.
@export var line_edit: LineEdit:
	set(new_value):
		if line_edit != null:
			# Disconnect to clean things up, seems to work even if
			# [method Callable.unbind] was called
			_disconnect(line_edit)
		if new_value != null:
			_connect(new_value)
		line_edit = new_value
		if start_synced:
			force_update()


func get_value() -> String:
	return line_edit.text


func update_value(new_value: Variant, old_value: Variant, forced: bool = false) -> void:
	if sync == Sync.ALWAYS or line_edit.text == str(old_value) or forced:
		line_edit.text = str(new_value)


func _connect(to_connect: LineEdit) -> void:
	if set_only_on_submit:
		to_connect.text_submitted.connect(set_value)
	else:
		to_connect.text_changed.connect(set_value)


func _disconnect(to_disconnect: LineEdit) -> void:
	if to_disconnect.text_changed.is_connected(set_value):
		to_disconnect.text_changed.disconnect(set_value)
	
	if to_disconnect.text_submitted.is_connected(set_value):
		to_disconnect.text_submitted.disconnect(set_value)



