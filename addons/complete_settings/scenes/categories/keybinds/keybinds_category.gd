@tool
extends SettingCategory


const InputMapperEntry = preload("input_mapper_entry.gd")


## A setting category wich automatically build keybind remappers.

## Emitted when all keybind remappers are build.
signal tree_created()


@export var packed_setting_group: PackedScene = preload("res://addons/complete_settings/scenes/setting_group/setting_group.tscn")
@export var packed_action_entry: PackedScene = preload("res://addons/complete_settings/scenes/categories/keybinds/action_entry.tscn")
@export var packed_keybind_mapper: PackedScene = preload("res://addons/complete_settings/scenes/categories/keybinds/keybind_entry.tscn")

## If true, will collapse all on ready
@export var collapsed_by_default: bool = true

@export var alternative_event_names: Array[String] = [
	"PRIMARY_KEYBIND",
	"SECONDARY_KEYBIND",
	"TERTIARY_KEYBIND",
	"QUATERNARY_KEYBIND",
	"QUINARY_KEYBIND",
	"SENARY_KEYBIND",
	"SEPTENARY_KEYBIND",
	"OCTONARY_KEYBIND",
	"NONARY_KEYBIND",
	"DENARY_KEYBIND",
]
@export var action_name_prefix: String = "ACTION_"
## Don't show keybind mapper for these actions.
## If empty array, [member KeybindsSaver.default_ignored_actions] is used.
## To ignore nothing, just add a StringName that is not the name of an action.
@export var ignored_actions: Array[StringName]


func _ready() -> void:
	super()
	
	if Engine.is_editor_hint():
		return
	
	create_tree()
	
	if collapsed_by_default:
		collapse_all()


var _setting_groups: Dictionary = {}
func create_tree() -> void:
	for action in _setting_groups:
		if not InputMap.has_action(action):
			var setting_group: SettingGroup = _setting_groups[action]
			_setting_groups.erase(action)
			setting_list.remove_child(setting_group)
			setting_group.queue_free()
	
	for action in InputMap.get_actions():
		if action in get_ignored_actions():
			continue
		
		var setting_group: SettingGroup
		
		if action in _setting_groups:
			setting_group = _setting_groups[action]
			for setting_entry in setting_group._entries:
				setting_group.remove_child(setting_entry)
				setting_entry.queue_free()
		else:
			setting_group = packed_setting_group.instantiate()
			_setting_groups[action] = setting_group
			setting_list.add_child(setting_group)
		
		var current_input_mapper_entry: InputMapperEntry = packed_action_entry.instantiate()
		current_input_mapper_entry.setup(
			action,
			0,
			action_name_prefix + action.to_upper()
		)
		current_input_mapper_entry.input_added.connect(create_tree)
		setting_group.add_child(current_input_mapper_entry)
		
		for event_idx in len(InputMap.action_get_events(action)):
			current_input_mapper_entry = packed_keybind_mapper.instantiate()
			current_input_mapper_entry.setup(
				action,
				event_idx,
				alternative_event_names[event_idx]
			)
			current_input_mapper_entry.input_removed.connect(create_tree)
			setting_group.add_child(current_input_mapper_entry)


func get_ignored_actions() -> Array[StringName]:
	if ignored_actions.is_empty():
		return KeybindsSaver.shared.ignored_actions
	
	return ignored_actions
