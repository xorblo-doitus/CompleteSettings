extends SettingEntry
class_name VolumeSlider

## A slider setting and saving volume for [member bus]

## The start of the setting path.
const setting_path_prefix: String = "complete_settings/volumes/"
## The info of the setting created.
const property_info: Dictionary = {
	"name": setting_path_prefix + "dummy",
	"type": TYPE_FLOAT,
	"hint": PROPERTY_HINT_RANGE,
	"hint_string": "0, 2"
}

var bus: SettingAudioBus:
	set(new):
		bus = new
		setting_name = bus.name
		_path = setting_path_prefix + bus.name


var _path: String:
	set(new):
		_path = new
		if _path:
			var info: Dictionary = property_info.duplicate()
			info["name"] = _path
			if not ProjectSettings.has_setting(_path):
				EasySettings.set_setting(_path, 100)
				ProjectSettings.add_property_info(info)
		if esl:
			esl.setting = _path
			esl.force_update()


@onready var esl: ESLSliderSpinBox = $ESLSliderSpinBox


func _ready() -> void:
	esl.setting = _path
	esl.force_update()
	super()

func _on_slider_spin_box_value_changed(value) -> void:
	bus.set_volume_linear(value)
