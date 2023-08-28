@icon("ESL_Icon.svg")
extends Node
class_name ESL

## Base class for EasySetting's Listeners
## 
## Implements virtual methods


## The way to sync this ESL when the setting is modified by an external source
enum Sync {
	ALWAYS, ## The value must always be the same as the setting
	WHEN_WAS_SYNCED, ## The value is updated only if it was already up to date
	NEVER, ## The value will never be updated
}


## Default value of [method set_value] parameter meaning the method
## will get the value with [method get_value], allowing passing null
## as an argument.
static var _no_value: RefCounted = RefCounted.new()

## The full path of the setting this EasySetting's Listener will be bind.
## [br]To find the path of a setting, find it in [code]Project → Project's Settings → General[/code]
## then click on it to see it's path under the search bar. You can right click
## the setting too then [code]copy property path[/code] or press [code]ctrl + shift + C[/code]
@export_placeholder("application/config/name") var setting: String = "":
	set(new_setting):
		if setting != "":
			EasySettings.unbind_listener(setting, self)
		if new_setting != "":
			EasySettings.bind_listener(new_setting, self)
		setting = new_setting
@export var sync: Sync = Sync.WHEN_WAS_SYNCED
## If true, when ready or target changed, the value will be synced.
@export var start_synced: bool = true
## Prevent saving setting more than this per second. If 0, there is no debounce.
## [br][b]Will not work when outside tree.[/b]
@export var save_debounce_time_sec: float = 0.0

var _save_debounce_timer: SceneTreeTimer
var _setting_changed_while_save_debouncing: bool = false


func _ready() -> void:
	if start_synced:
		force_update()


## [b][Virtual][/b] Method called to get the value. It should return the right type of value.
func get_value():
	return null


## [b][Virtual][/b] Method called when the setting is modified by an external source,
## except if [member sync] is [enum Sync].NEVER.
func update_value(new_value, old_value: Variant, forced: bool = false) -> void:
	pass


## Method to call when value is changed. If connected to a signal with more
## than 1 value emitted, remember to discard them.
## [br]If no [param new_value] is passed, it uses [method get_value] to find it.
func set_value(new_value: Variant = _no_value) -> void:
	_ignore_update = true
	
	EasySettings.set_setting(
		setting,
		get_value() if _is_no_value(new_value) else new_value,
		_save_debounce_timer == null
	)
	
	if _save_debounce_timer == null:
		_create_save_debounce_timer()
	else:
		_setting_changed_while_save_debouncing = true
	
	_ignore_update = false


## Fetch the setting value and update the bound object.
func force_update() -> void:
	update_value(EasySettings.get_setting(setting), _no_value, true)


## Workaround for `==` raising an error instead of returning false when
## Comparing two things that it don't know how to compare
func _is_no_value(to_test: Variant) -> bool:
	return typeof(to_test) == TYPE_OBJECT and to_test == _no_value


var _ignore_update: bool = false
func _update_value(new_value, old_value: Variant) -> void:
	if _ignore_update or sync == Sync.NEVER:
		return
	update_value(new_value, old_value)


func _create_save_debounce_timer() -> void:
	if save_debounce_time_sec and is_inside_tree():
		_save_debounce_timer = get_tree().create_timer(
			save_debounce_time_sec,
			true, # default
			false, # default
			true # ignore time_scale
		)
		_setting_changed_while_save_debouncing = false
		_save_debounce_timer.timeout.connect(_on_debounce_save_timer_timeout)


func _on_debounce_save_timer_timeout() -> void:
	if _setting_changed_while_save_debouncing:
		EasySettings.save_settings()
		_create_save_debounce_timer()
	else:
		_save_debounce_timer = null
