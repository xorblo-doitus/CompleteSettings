extends SettingEntry


@onready var input_mapper: HBoxContainer = $InputMapper


@export var action_name: StringName:
	set(new):
		if input_mapper: input_mapper.action_name = new
		else: _ready_sets[&"action_name"] = new
	get:
		if input_mapper: return input_mapper.action_name
		else: return &""
@export var input_idx: int:
	set(new):
		if input_mapper: input_mapper.input_idx = new
		else: _ready_sets[&"input_idx"] = new
	get:
		if input_mapper: return input_mapper.input_idx
		else: return 0


func _ready() -> void:
	super()
	input_mapper.input_icon.force_refresh()


func setup(action: StringName, idx: int, _setting_name: String) -> void:
	setting_name = _setting_name
	action_name = action
	input_idx = idx
