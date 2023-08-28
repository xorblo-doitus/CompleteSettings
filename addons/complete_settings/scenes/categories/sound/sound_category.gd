extends SettingCategory

## A setting category wich automatically build volume sliders for current audio bus setup.

## Emitted when all volume sliders are build.
signal tree_created()


@export var packed_volume_slider: PackedScene = preload("res://addons/complete_settings/scenes/categories/sound/volume_slider.tscn")
@export var packed_setting_group: PackedScene = preload("res://addons/complete_settings/scenes/setting_group/setting_group.tscn")


var buses: Dictionary = {}


func _ready() -> void:
	fetch_buses()


func fetch_buses() -> void:
	buses.clear()
	
	for idx in AudioServer.bus_count:
		buses[AudioServer.get_bus_name(idx)] = SettingAudioBus.from_idx(idx)
	
	for bus in buses.values():
		var send: SettingAudioBus = buses.get(bus.send)
		if send != null:
			send.children.append(bus)
	
	create_tree()


func create_tree() -> void:
	clear_setting_list()
	
	var to_create: Array[SettingAudioBus] = [buses["Master"]]
	buses["Master"].input_parent = setting_list
	while to_create:
		var current: SettingAudioBus = to_create.pop_back()
		var new_input: VolumeSlider = packed_volume_slider.instantiate()
		current.input = new_input
		
		if not current.children.is_empty():
			var group: SettingGroup = packed_setting_group.instantiate()
			
			for child in current.children:
				to_create.append(child)
				child.input_parent = group
			
			current.input_parent.add_child(group)
			current.input_parent = group
		
		new_input.bus = current
		current.input_parent.add_child(new_input)
			
	tree_created.emit()
