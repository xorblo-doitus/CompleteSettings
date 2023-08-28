@tool
extends ESL
class_name ESLPrinter


## Print when a setting changes
##
## A little debugging Node wich print when a setting is changed via EasySettings


## If false, will stop printing
@export var enabled: bool = true
## If true, will say both new value and value the settings was before the change
@export var print_old_value: bool = true
## Inserted at the begining of the print
@export var prefix: String = "Changed setting "


func _ready() -> void:
	## When in editor, static variable is not initialized for some reason
	if _no_value == null:
		_no_value = RefCounted.new()
	super()


func get_value() -> Variant:
	return EasySettings.get_value(setting)


## [b][Virtual][/b] Method called when the setting is modified by an external source,
## except if [member sync] is [enum Sync].NEVER.
func update_value(new_value: Variant, old_value: Variant, forced: bool = false) -> void:
	if not enabled:
		return
	
	if _is_no_value(old_value):
		print("Initial setting ", setting, ": ", new_value)
	else:
		if print_old_value:
			print(prefix, setting, ": ", new_value, " (was: ", old_value, ")")
		else:
			print(prefix, setting, ": ", new_value)
