@tool
extends HBoxContainer
class_name SettingEntry


@export var setting_name: String = "_SETTING_NAME":
	set(new):
		setting_name = new
		if label == null: _ready_sets[&"setting_name"] = new
		else: label.text = setting_name


@onready var label: Label = $Label

### The setting this SettingEntry is bound to.
#@export_multiline var setting = ""
### The node in charge of taking the input. If not specified, one is automatically creadted
### according to the setting type.
#@export var custom_input: Node


#var _input: Node:
#	get:
#		if custom_input != null:
#			return _input
#		if _input == null:
#			_generate_input()
#		return _input


var _ready_sets: Dictionary = {}
func _ready() -> void:
	for property_name in _ready_sets:
		set(property_name, _ready_sets[property_name])
	_ready_sets.clear()


#func _generate_input() -> void:
#	match typeof(EasySettings.get_setting(setting)):
#		TYPE_STRING:
#			pass
#
#		null:
#			return
#
#	add_child(_input)


func sort() -> void:
	if get_child_count(true) >= 2 and get_child(1, true) is SettingGroupIcon:
		move_child(get_child(1, true), 0)


func _on_pre_sort_children() -> void:
	sort()
