@tool
@icon("icon.svg")
extends BoxContainer
class_name SliderSpinBox


signal value_changed(value: float)


## The mix of a [Slider] and a [SpinBox]
## 
## It uses it's [Slider] instance as a reference for porperties, and links
## it with it's [SpinBox] instance.
## [br][br]
## All [Range]'s properties can be used directly on this class, even if
## it does not inherit from it. This is because it interfaces with it's [Slider]
## (wich inherit from [Range]) trough [method Object._set], [method Object._get]
## and [method Object._get_property_list]


@export var slider_custom_minimum_size: Vector2 = Vector2(150, 0):
	set(new):
		slider_custom_minimum_size = new
		if slider:
			slider.custom_minimum_size = slider_custom_minimum_size


## The [Slider] instance used by SliderSpinBox.
@onready var slider: HSlider = %Slider
## The [SpinBox] instance used by SliderSpinBox.
@onready var spin_box: SpinBox = %SpinBox


func _ready() -> void:
	if _property_list.is_empty():
		_get_property_list()
	
	slider.share(spin_box)
	slider.custom_minimum_size = slider_custom_minimum_size


func _set(property: StringName, value: Variant) -> bool:
	if property in _bound_properties:
		slider.set(property, value)
		return true
	return false


func _get(property: StringName) -> Variant:
	if property in _bound_properties:
		return slider.get(property)
	return null


# A list of properties taken from the range
static var _bound_properties: Array[StringName] = []
# Store properties added to prevent rescanning for them
static var _property_list: Array[Dictionary] = []
# Bind Range's properties of the slider and spin box.
func _get_property_list() -> Array[Dictionary]:
	if slider and _property_list.is_empty():
		var take: bool = false
		
		for property in slider.get_property_list():
			if take:
				if property["usage"] == PROPERTY_USAGE_CATEGORY and property["name"] == "Slider":
					break
				else:
					if property["usage"] == 6:
						property["usage"] = 4
					_property_list.append(property)
					_bound_properties.append(property["name"])
			elif property["usage"] == PROPERTY_USAGE_CATEGORY and property["name"] == "Range":
				take = true
				_property_list.append(property)
	
	return _property_list


func set_value_no_signal(value: float) -> void:
	slider.set_value_no_signal(value)


func _on_slider_value_changed(value: float) -> void:
	value_changed.emit(value)
