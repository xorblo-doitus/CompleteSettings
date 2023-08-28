extends RefCounted
class_name SettingAudioBus



var idx: int = 0
var children: Array[SettingAudioBus]

var input: VolumeSlider
var input_parent: Control

var name: String:
	get: return AudioServer.get_bus_name(idx)
var send: String:
	get: return AudioServer.get_bus_send(idx)


static func from_idx(desired_idx: int) -> SettingAudioBus:
	return SettingAudioBus.new().read_idx(desired_idx)
	

func read_idx(desired_idx: int) -> SettingAudioBus:
	idx = desired_idx
	return self


func set_volume_linear(volume: float) -> void:
	set_volume_db(linear_to_db(volume))


func set_volume_db(volume: float) -> void:
	AudioServer.set_bus_volume_db(idx, volume)
