extends PanelContainer


## A simple example of a setting editor GUI.


func open() -> void:
	CompleteSettings.start_setting_edition()
	show()


func _on_validation_bar_canceled() -> void:
	CompleteSettings.cancel()
	hide()


func _on_validation_bar_applied() -> void:
	CompleteSettings.apply()


func _on_validation_bar_validated() -> void:
	CompleteSettings.validate()
	hide()
