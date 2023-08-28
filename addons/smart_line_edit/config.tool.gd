@tool
extends EditorScript

## Change SmartLineEdit config
## 
## To change SmartLineEdit config, modify variables in this script
## (exept those prefixed with an underscore) then run it from editor
## with [code]File → Run[/code] or [code]ctrl + shift + x[/code] (default)
## [br][br]
## [b]Warning :[/b] This EditorScript updates smart_line_edit.gd and smart_line_edit.tscn directly,
## make sure to save and close these file before running this script.

## If true, the SmartLineEdit automatically update it's translations
## (such as [member SmartLineEdit.tooltip_base]) when
## NOTIFICATION_TRANSLATION_CHANGED is received.
var use_notification: bool = true
## If true, the SmartLineEdit update it's translations
## (such as [member SmartLineEdit.tooltip_base]) when
## [member locale_function] is called to [member locale_group]
var use_group: bool = false
## The group added to SmartLineEdits
var locale_group: String = "locale_changed_listeners"
## The name of the function on SmartLineEdits to be called to update translations
var locale_function: String = "on_locale_changed"

# Don't modify these variables
const _func_script: String = """## Call [code]get_tree().call_group("locale_changed_listeners", "on_locale_changed")[/code]
## when changing locale to update strings that are using locale.
func {func_name}() -> void:
	update_locale()"""
const _notif_script: String = """func _notification(what: int) -> void:
	if not Engine.is_editor_hint():
		match what:
			NOTIFICATION_TRANSLATION_CHANGED:
				{func_name}()"""


func _run() -> void:
	# SCRIPT
	var script_text: String = FileAccess.open(
		"res://addons/smart_line_edit/smart_line_edit.gd",
		FileAccess.READ
	).get_as_text()
	
	# Function
	var func_regex: RegExMatch = RegEx.create_from_string(
		"""REGEX_FUNC_A.*\\n\\K[\\w\\W]*(?=\\n.*REGEX_FUNC_B)"""
	).search(script_text)
	
	script_text = script_text.replace(
		func_regex.get_string(),
		_get_script(_func_script, true)
	)
	
	# Notif
	var notif_regex: RegExMatch = RegEx.create_from_string(
		"""REGEX_NOTIF_A.*\\n\\K[\\w\\W]*(?=\\n.*REGEX_NOTIF_B)"""
	).search(script_text)
	
	script_text = script_text.replace(
		notif_regex.get_string(),
		_get_script(_notif_script, use_notification)
	)
	
	FileAccess.open(
		"res://addons/smart_line_edit/smart_line_edit.gd",
		FileAccess.WRITE
	).store_string(script_text)
	
	# SCENE
	var scene_text: String = FileAccess.open(
		"res://addons/smart_line_edit/smart_line_edit.tscn",
		FileAccess.READ
	).get_as_text()
	
	# Group
	var group_regex: RegExMatch = RegEx.create_from_string(
		"""\\[node name="SmartLineEdit" type="HBoxContainer".*]"""
	).search(scene_text)
	
	scene_text = scene_text.replace(
		group_regex.get_string(),
		"""[node name="SmartLineEdit" type="HBoxContainer" groups=["%s"]]""" % locale_group
		if use_group else """[node name="SmartLineEdit" type="HBoxContainer"]"""
	)
	
	FileAccess.open(
		"res://addons/smart_line_edit/smart_line_edit.tscn",
		FileAccess.WRITE
	).store_string(scene_text)

func _get_script(base_script: String, enabled: bool) -> String:
	if not enabled:
		return "# Functionality need to be enabled in res://addons/smart_line_edit/config.tool.gd"
	
	return base_script.format({
			"func_name": locale_function,
		})






