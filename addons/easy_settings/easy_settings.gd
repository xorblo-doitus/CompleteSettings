extends Object
class_name EasySettings


static var all_listeners: Dictionary:
	get:
		# `all_listeners == null` somehow don't work...
		if typeof(all_listeners) == TYPE_NIL:
			all_listeners = {}
		return all_listeners


## If true, call [method save_settings] automatically when changing any setting.
## See [method begin_bulk_setting_change] if you want to save many settings.
static var auto_saving: bool = true
static var _bulk_setting_change: bool = false
## Key: Setting, Value: Setting's value when starting bulk modification.
## This doesn't store initial values for unmodified settings.
static var _bulk_to_undo: Dictionary = {}


## Does [method ProjectSettings.set_setting] then update listeners bound to this setting.
## If [param save] is [code]true[/code] AND nothing disable auto saving, then it will save changement.
static func set_setting(setting: String, value, save: bool = true) -> void:
	var old_value = ProjectSettings.get_setting(setting)
	
	if _bulk_setting_change and not setting in _bulk_to_undo:
		_bulk_to_undo[setting] = old_value
	
	ProjectSettings.set_setting(setting, value)
	
	if save and _shall_save():
		save_settings()
	
	var listeners: Array[ESL] = all_listeners.get(setting, _get_empty_ESL_array())
	for listener in listeners:
		if is_instance_valid(listener):
			listener._update_value(value, old_value)
		else:
			# Defered because would modify the Array during iteration otherwise.
			unbind_listener.call_deferred(setting, listener)


## Alias for [method ProjectSettings.get_setting]
static func get_setting(setting: String, default: Variant = null) -> Variant:
	return ProjectSettings.get_setting(setting, default)


## Bind a listener so he will be updated when setting's value is changed.
static func bind_listener(setting: String, listener: ESL) -> void:
	var listeners: Array[ESL] = all_listeners.get(setting, _get_empty_ESL_array())
	if listeners.is_empty():
		all_listeners[setting] = listeners
	
	listeners.append(listener)


## Unbind listener : he will no longer be updated when it's linked setting is changed.
## [br]Will raise an error if listener is not bound.
static func unbind_listener(setting: String, listener: ESL) -> void:
	var listeners: Array[ESL] = all_listeners.get(setting)
	listeners.erase(listener)
	
	if listeners.is_empty():
		all_listeners.erase(setting)


## Save settings to [code]override.cfg[/code] so it's loaded on next startup.
static  func save_settings() -> void:
	print("Saving settings")
	ProjectSettings.save_custom("override.cfg")


## Begin bulk setting change to prevent saving too much times settings.
## Use [method validate_bulk_setting_change] once you are done to save modifications.
## Use [method cancel_bulk_setting_change] to cancel modifications.
static  func begin_bulk_setting_change() -> void:
	_bulk_setting_change = true
	_bulk_to_undo.clear()


## Stop bulk setting change and saves the settings.
## See [method begin_bulk_setting_change].
static func validate_bulk_setting_change(save: bool = true) -> void:
	_bulk_setting_change = false
	_bulk_to_undo.clear()
	if save:
		save_settings()

## @deprecated
## Alias for [method validate_bulk_setting_change]
static func end_bulk_setting_change() -> void:
	validate_bulk_setting_change()


## Restore settings as there were when starting bulk setting change.
## See [method begin_bulk_setting_change].
static func cancel_bulk_setting_change() -> void:
	for setting in _bulk_to_undo:
		set_setting(setting, _bulk_to_undo[setting])
	_bulk_setting_change = false
	_bulk_to_undo.clear()


static func _shall_save() -> bool:
	return auto_saving and not _bulk_setting_change


static func _get_empty_ESL_array() -> Array[ESL]:
	return []
