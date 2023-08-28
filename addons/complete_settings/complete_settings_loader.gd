extends Node
class_name CompleteSettingLoader



func _init() -> void:
	# Load volumes
	for bus_idx in AudioServer.bus_count:
		AudioServer.set_bus_volume_db(
			bus_idx,
			linear_to_db(
				EasySettings.get_setting(
					VolumeSlider.setting_path_prefix + AudioServer.get_bus_name(bus_idx),
					0.0
				)
			)
		)
	
	# Load keybinds
	KeybindsSaver.set_current_mapping_as_default()
	KeybindsSaver.load_keybinds()
