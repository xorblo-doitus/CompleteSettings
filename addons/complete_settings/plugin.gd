@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_autoload_singleton("CompleteSettingsLoader", "res://addons/complete_settings/complete_settings_loader.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("CompleteSettingsLoader")
