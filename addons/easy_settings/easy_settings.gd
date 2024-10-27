extends Object
class_name EasySettings


const _BUILTIN_FEATURE_TAGS: PackedStringArray = [
	"android",
	"bsd",
	"linux",
	"macos",
	"ios",
	"windows",
	"linuxbsd",
	"debug",
	"release",
	"editor",
	"template",
	"double",
	"single",
	"64",
	"32",
	"x86_64",
	"x86_32",
	"x86",
	"arm64",
	"arm32",
	"arm",
	"rv64",
	"riscv",
	"ppc64",
	"ppc32",
	"ppc",
	"wasm64",
	"wasm32",
	"wasm",
	"mobile",
	"pc",
	"web",
	"web_android",
	"web_ios",
	"web_linuxbsd",
	"web_macos",
	"web_windows",
	"etc",
	"etc2",
	"s3tc",
	"movie",
]

static var _current_features: PackedStringArray = []


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
static var _bulk_to_undo_overrides: Dictionary = {}



static func _static_init() -> void:
	detect_features()


## Calls [method ProjectSettings.set_setting] then update listeners bound to this setting.
## If [param save] is [code]true[/code] AND nothing disable auto saving, then it will save changement.
## [br][br] 
## In case an override is not provided and some are active for that setting, they will be removed.
static func set_setting(setting: String, value: Variant, save: bool = true, override: String = "") -> void:
	var old_value: Variant = null
	if ProjectSettings.has_setting(setting):
		old_value = ProjectSettings.get_setting_with_override(setting)
	elif "." in setting:
		old_value = ProjectSettings.get_setting(setting.split(".")[0])
	
	if override:
		setting += "." + override
	else:
		var template: String = setting + "."
		for feature in _current_features:
			var path: String = template + feature
			if ProjectSettings.has_setting(path):
				if _bulk_setting_change and not path in _bulk_to_undo_overrides:
					_bulk_to_undo_overrides[path] = BulkUndoStateForOverride.new(setting, feature, ProjectSettings.get_setting(path))
				ProjectSettings.set_setting(path, null)
	
	if _bulk_setting_change and not setting in _bulk_to_undo:
		_bulk_to_undo[setting] = old_value
	
	ProjectSettings.set_setting(setting, value)
	
	if save and _shall_save():
		save_settings()
	
	_update_listeners(setting, value, old_value)
	
	var split: PackedStringArray = setting.split(".", true, 1)
	if split.size() == 2:
		_update_listeners(split[0], value, old_value)


static func _update_listeners(setting: String, new_value: Variant, old_value: Variant) -> void:
	var listeners: Array[ESL] = all_listeners.get(setting, _get_empty_ESL_array())
	
	for listener in listeners:
		if is_instance_valid(listener):
			listener._update_value(new_value, old_value)
		else:
			# Defered because would modify the Array during iteration otherwise.
			unbind_listener.call_deferred(setting, listener)


## Returns [method ProjectSettings.get_setting_with_override] or [param default]
## if the provided setting does not exist.
static func get_setting(setting: StringName, default: Variant = null) -> Variant:
	if ProjectSettings.has_setting(setting):
		return ProjectSettings.get_setting_with_override(setting)
	
	return default


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


## Save settings to [code]res://override.cfg[/code] so it's loaded on next startup.
static  func save_settings() -> void:
	print("Saving settings")
	ProjectSettings.save_custom("res://override.cfg")


## Begin bulk setting change to prevent saving too much times settings.
## Use [method validate_bulk_setting_change] once you are done to save modifications.
## Use [method cancel_bulk_setting_change] to cancel modifications.
## Note that modifying a setting during bulk change will [i]apply[/i] the new setting,
## but it wont be [i]saved[/i].
static  func begin_bulk_setting_change() -> void:
	_bulk_setting_change = true
	_bulk_to_undo.clear()
	_bulk_to_undo_overrides.clear()


## Stop bulk setting change and saves the settings.
## See [method begin_bulk_setting_change].
static func validate_bulk_setting_change(save: bool = true) -> void:
	_bulk_setting_change = false
	_bulk_to_undo.clear()
	_bulk_to_undo_overrides.clear()
	if save:
		save_settings()

## @deprecated
## Alias for [method validate_bulk_setting_change]
static func end_bulk_setting_change() -> void:
	validate_bulk_setting_change()


## Restore settings as there were when starting bulk setting change.
## See [method begin_bulk_setting_change].
static func cancel_bulk_setting_change() -> void:
	for path in _bulk_to_undo_overrides:
		var state: BulkUndoStateForOverride = _bulk_to_undo_overrides[path]
		ProjectSettings.set_setting(state.get_full_path(), state.initial_value)
	_bulk_to_undo_overrides.clear()
	
	for setting in _bulk_to_undo:
		set_setting(setting, _bulk_to_undo[setting])
	_bulk_to_undo.clear()
	
	_bulk_setting_change = false


## Check which feature tags are currently active. (See [method OS.has_feature])
## Checked features are the builtin ones, the ones in
## [code]ProjectSettings.get_setting("addons/easy_settings/custom_features"[/code]
## and the ones given in [param custom_features].
## [b]Note:[/b] This is called automatically inside static init.
static func detect_features(custom_features: PackedStringArray = PackedStringArray()) -> void:
	_current_features.clear()
	_check_features(_BUILTIN_FEATURE_TAGS)
	_check_features(custom_features)
	_check_features(ProjectSettings.get_setting("addons/easy_settings/custom_features", PackedStringArray()))
	#_order_features()


static func _check_features(features: PackedStringArray) -> void:
	for feature in features:
		if OS.has_feature(feature):
			_current_features.append(feature)


## Hum, seems Godot just apply them in the order they get added...
#static func _order_features() -> void:
	#const _TEMP_ORDER_CHECKER_SETTING = "temporary/easy_settings/feature_override_order"
	#
	#ProjectSettings.set_setting(_TEMP_ORDER_CHECKER_SETTING, -1)
	##for i in len(_current_features):
	#var tmp: Array = _current_features
	#tmp.shuffle()
	#_current_features = tmp
	#for i in len(_current_features):
	##for i in range(len(_current_features)-1, -1, -1):
		#print(i, ": ", _current_features[i])
		#ProjectSettings.set_setting(
			#_TEMP_ORDER_CHECKER_SETTING + "." + _current_features[i],
			#i
		#)
	#print("=======")
	#var reordered: PackedStringArray = PackedStringArray()
	#var current_i: int = ProjectSettings.get_setting_with_override(_TEMP_ORDER_CHECKER_SETTING)
	#while current_i != -1:
		#var feature: String = _current_features[current_i]
		#print(current_i, ": ", feature)
		#reordered.append(feature)
		#ProjectSettings.set_setting(_TEMP_ORDER_CHECKER_SETTING + "." + feature, null)
		#current_i = ProjectSettings.get_setting_with_override(_TEMP_ORDER_CHECKER_SETTING)
	#
	#_current_features = reordered
	#print("ordered: ", reordered)


static func _shall_save() -> bool:
	return auto_saving and not _bulk_setting_change


static func _get_empty_ESL_array() -> Array[ESL]:
	return []


class BulkUndoStateForOverride:
	var setting: String
	var override: String
	var initial_value: Variant
	
	func _init(_setting: String, _override: String, _initial_value: Variant) -> void:
		setting = _setting
		override = _override
		initial_value = _initial_value
	
	func get_full_path() -> String:
		return setting + "." + override
