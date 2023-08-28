extends SettingEntry


@onready var option_button: OptionButton = $OptionButton


func _on_option_button_item_selected(index: int) -> void:
	get_window().mode = option_button.get_item_id(index)
