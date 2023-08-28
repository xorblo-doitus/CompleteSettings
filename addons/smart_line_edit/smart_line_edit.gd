@tool
@icon("SmartLineEdit.svg")
@static_unload
extends HBoxContainer
class_name SmartLineEdit
## A LineEdit wich can perform string validation

signal valid_text_changed(new_text: String, old_text: String)
signal value_changed(new_value, old_value)
signal status_changed(new_status: Status, old_status: Status)
signal submited(value)

enum Types {
	DIRECTORY, ## Must be a path to a directory. It will be made canonical on submit.
	FILE, ## Must be a path to a file. It will be made canonical on submit.
	INT, ## Must be an integer (ex: 2, -65, 999...)
	FLOAT, ## Must be a floating point number (ex: 1.5, -6.7, 0.789...)
	CUSTOM, ## Use only [member checks]
}

const default_valid_texts = [
	"res://",
	"res://example_file.txt", ## still invalid if requires must be valid
	"1",
	"1",
	"please enter a starting valid text",
]

enum Status {
	OK, ## The text input is valid
	CORRECTED, ## The text input was modified to be valid
	WRONG, ## The text input is wrong
}

## The file dialog used by all SmartLineEdit by default.
## Use [member own_file_dialog] to change the file dialog of one instance.
## [b]When changing this value, make sure to free the old file dialog if you don't need it anymore.[/b]
## If the FileDialog is not inside the tree, he will be parented to the first SmartLineEdit wich need it.
static var file_dialog: FileDialog:
	get:
		if not file_dialog or not is_instance_valid(file_dialog):
			file_dialog = FileDialog.new()
			
		return file_dialog

## The type the value will be restricted to
@export var type: Types = Types.INT:
	set(new):
		type = new
		_adapt_to_type()

@export_group("Modifiers")
## String compiled into a Regex. If Regex don't match anything, string will be wrong.
## This check is performed after [member checks] and befor built-in checks.
@export_multiline var regex: String = "":
	set(new):
		if regex:
			_regex.compile(new)
		else:
			_regex = RegEx.create_from_string(new)
		regex = new
@export_subgroup("Int and Float")
## Only applies if [member type] is set to a number type (int, float...)
@export var minimum: float = -1.79769e308
## Only applies if [member type] is set to a number type (int, float...)
@export var maximum: float = 1.79769e308
## Only applies if [member type] is set to a number type (int, float...)
@export var step: float = 0.0
## See [method Expression.parse] parameter called [code]input_names[/code]
@export var expression_input_names: PackedStringArray = PackedStringArray()
## See [method Expression.execute] parameter called [code]inputs[/code]
@export var expression_inputs: Array = []
## See [method Expression.execute] parameter called [code]base_instance[/code]
var expression_base_instance: Object
## See [method Expression.execute] parameter called [code]const_calls_only[/code]
@export var expression_const_calls_only: bool = false
@export_subgroup("File and Directory")
## If true, only path to existing file/directory will be valid
@export var must_exist: bool = true
## The file dialog used by this SmartLineEdit.
## Use [member file_dialog] to change the file dialog of all instances.
## [b]When changing this value, make sure to free the old file dialog if you don't need it anymore.[/b]
## If the FileDialog is not inside the tree, he will be parented to the first SmartLineEdit wich need it.
@export var own_file_dialog: FileDialog
@export_subgroup("File")
## Works like [member FileDialog.filters].
## [br]- [code]*[/code] match any characters 0 or more times.
## [br]- [code]?[/code] matches any character 1 time
@export var file_patterns: PackedStringArray:
	set(new):
		file_patterns = new
		get_file_dialog().filters = file_patterns
		_build_file_regexes()

@export_group("Tool Tip", "tooltip_")
## Base tooltip for the LineEdit.
## Translation automatically handled via [method Object.tr].
@export var tooltip_base: String = "Enter your input.\n"
## Base tooltip for the LineEdit.
## Translation automatically handled via [method Object.tr].
@export var tooltip_ok: String = "Input is valid."
## Tooltip appended to the LineEdit when it's content was interpreted differently.
## Translation automatically handled via [method Object.tr].
@export var tooltip_corrected: String = "Interpreted as {corrected} instead of what was inputed."
## Tooltip appended to the LineEdit when it's content is wrong.
## Translation automatically handled via [method Object.tr].
@export var tooltip_wrong: String = "Input is invalid, last valid text is \"{corrected}\"."
@export_subgroup("Submit button tooltips", "tooltip_submit_")
@export var tooltip_submit_ok: String = "Submit your input."
@export var tooltip_submit_accept_corrected: String = "Accept corrected input: {corrected}"
@export var tooltip_submit_wrong: String = "Restore last valid text: {corrected}"
@export_group("")

## The last valid text inputed. Please enter a valid text in the editor so it has one on start.
@export var last_valid_text: String = default_valid_texts[type]

## Allow the addition of more checking functions to decide if it's a correct string.
## They are run [b]before[/b] [member regex] and built-in checks.
## These functions should return :
## [br][code]false[/code] : the string is wrong.
## [br][code]true[/code] : the string is correct.
## [br][code]string[/code] : the string is wrong, but the function found a way to fix it
## and returned this corrected string.
@export var checks: Array[Callable] = []

@export var keep_ratio: Array[Control]:
	set(new_value):
		keep_ratio = new_value
		for control in keep_ratio:
			control.resized.connect(shrink)


## The LineEdit used by this SmartLineEdit
@onready var line_edit: LineEdit = $LineEdit
@onready var submit_button: Button = $Submit
@onready var open_file_dialog_button: Button = $OpenFileDialog


var status: Status = Status.OK
var _file_regexes: Array[RegEx] = []
var _regex: RegEx
var _expression: Expression


func _init() -> void:
	_setup_expression()


func _ready() -> void:
	set_line_edit_text(last_valid_text)
	
	if not Engine.is_editor_hint() and status == Status.WRONG:
		push_warning("Starting valid text is invalid on SmartLineEdit at" + str(get_path()))
	
	update_tooltip()
	update_submit_button_tooltip()
	
	shrink()


## Reduce the size to the minimum
func shrink() -> void:
	for control in keep_ratio:
		control.custom_minimum_size.x = control.size.y
		
	size = Vector2.ZERO


func _on_line_edit_text_changed(new_text: String) -> void:
	adapt(new_text)


## Returns :
## [br][code]false[/code] : [param text] is wrong.
## [br][code]true[/code] : [param text] is correct.
## [br][code]string[/code] : [param text] is wrong, but the function found a way to fix it
## and returned this corrected string.
func is_ok(text: String):
	var was_modified: bool = false
	var wrong: bool = false
	
	# Custom checks
	for check in checks:
		var result = check.call(text)
		match result:
			true:
				continue
			false:
				wrong = true
			_:
				text = result
				was_modified = true
				wrong = false
	
	# Built-in checks
	if _regex and _regex.search(text) == null:
		wrong = true
	
	match type:
		Types.DIRECTORY:
			var new_text: String = text.simplify_path()
			if not must_exist or DirAccess.dir_exists_absolute(text):
				if new_text != text:
					text = new_text
					was_modified = true
			else:
				wrong = true
		Types.FILE:
			var new_text: String = text.simplify_path()
			
			if not wrong and _file_regexes:
				var file_name: String = new_text.get_file()
				wrong = true
				for regex in _file_regexes:
					if regex.search(file_name) != null:
						wrong = false
			
			if not wrong and (not must_exist or FileAccess.file_exists(text)):
				if new_text != text:
					text = new_text
					was_modified = true
			else:
				wrong = true
		Types.INT:
			var number: float = 0.0
			var parsed: bool = false
			
			if _expression.parse(text, expression_input_names) == Error.OK:
				var attempt = _expression.execute(expression_inputs, expression_base_instance, false, expression_const_calls_only)
				if not _expression.has_execute_failed():
					number = attempt
					parsed = true
					
			if not parsed and text.is_valid_float():
				number = float(text)
				parsed = true
					
			if parsed:
				var new_text: String = str(snappedi(
					clamp(number, minimum, maximum),
					step if step else 1 # step = 0 disturbs rounding (3.7 → 3 instead of 4)
				))
				if new_text != text:
					text = new_text
					was_modified = true
			else:
				wrong = true
			
		Types.FLOAT:
			var number: float = 0.0
			var parsed: bool = false
			
			if _expression.parse(text, expression_input_names) == Error.OK:
				var attempt = _expression.execute(expression_inputs, expression_base_instance, false, expression_const_calls_only)
				if not _expression.has_execute_failed():
					number = attempt
					parsed = true
			
			if not parsed and text.is_valid_float():
				number = float(text)
				parsed = true
					
			if parsed:
				var new_text: String = str(snappedf(clampf(number, minimum, maximum), step))
				if new_text != text:
					text = new_text
					was_modified = true
			else:
				wrong = true
	
	if wrong:
		return false
	elif was_modified:
		return text
	
	return true


## Evaluate [param string] according to [member type] :
## [br]INT → int
## [br]FLOAT → float
## [br]Any other type will result in an unchanged string.
func eval(string: String):
	match type:
		Types.INT:
			return string.to_int()
		Types.FLOAT:
			return string.to_float()
		
	## String as default
	return string


func adapt(wanted_text: String) -> void:
	var checks_result = is_ok(wanted_text)
	var initial_status: Status = status
	var initial_valid_text: String = last_valid_text
	
	match checks_result:
		false:
			status = Status.WRONG
		true:
			last_valid_text = wanted_text
			status = Status.OK
		_:
			last_valid_text = checks_result
			status = Status.CORRECTED
	
	if status != initial_status:
		status_changed.emit(status, initial_status)
	if last_valid_text != initial_valid_text:
		valid_text_changed.emit(last_valid_text, initial_valid_text)


## Choose the right FileDialog and parent it if he is not inside tree.
func get_file_dialog() -> FileDialog:
	var current_file_dialog: FileDialog
	if own_file_dialog:
		current_file_dialog = own_file_dialog
	else:
		current_file_dialog = file_dialog
	
	if not current_file_dialog.is_inside_tree():
		if current_file_dialog.get_parent() == null:
			add_child(current_file_dialog)
		else:
			current_file_dialog.reparent(self)
	
	return current_file_dialog


## Utility to format tooltips easily
func format(string: String) -> String:
	return string.format({
		"corrected": last_valid_text,
	})


func get_tooltip_with_status() -> String:
	match status:
		Status.OK:
			return tooltip_ok
		Status.CORRECTED:
			return tooltip_corrected
		Status.WRONG:
			return tooltip_wrong
	return "Error finding tooltip: Status unknown."


func update_tooltip() -> void:
	line_edit.tooltip_text = format(tr(tooltip_base) + tr(get_tooltip_with_status()))


func _get_raw_submit_button_tooltip() -> String:
	match status:
		Status.OK:
			return tooltip_submit_ok
		Status.CORRECTED:
			return tooltip_submit_accept_corrected
		Status.WRONG:
			return tooltip_submit_wrong
	return "Error finding tooltip: Status unknown."


func update_submit_button_tooltip() -> void:
	submit_button.tooltip_text = format(tr(_get_raw_submit_button_tooltip()))


func _on_status_changed(new_status: Status, old_status: Status) -> void:
	line_edit.theme_type_variation = "LineEdit_" + Status.keys()[new_status]
	
	update_submit_button_tooltip()
	update_tooltip()


## Emit [signal LineEdit.text_changed]
func set_line_edit_text(new_text: String) -> void:
	line_edit.text = new_text
	line_edit.text_changed.emit(new_text)


## Modify [member last_valid_text] without triggering [signal valid_text_changed]
## and [signal value_changed]. Still triggers [signal status_changed].
func set_valid_text_without_update(new_valid_text: String) -> void:
	last_valid_text = new_valid_text
	match status:
		Status.OK, Status.CORRECTED:
			line_edit.text = new_valid_text
	
			if status == Status.CORRECTED:
				status = Status.OK
				status_changed.emit(status, Status.CORRECTED)


func open_file_dialog() -> void:
	var current_file_dialog: FileDialog = get_file_dialog()
	if current_file_dialog.visible:
		# Already in use
		return
	
	current_file_dialog.filters = file_patterns
	current_file_dialog.current_path = last_valid_text
	match type:
		Types.FILE:
			if must_exist:
				current_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
			else:
				current_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
			current_file_dialog.file_selected.connect(set_line_edit_text, CONNECT_ONE_SHOT)
		Types.DIRECTORY:
			current_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
			current_file_dialog.dir_selected.connect(set_line_edit_text, CONNECT_ONE_SHOT)
	
	current_file_dialog.popup_centered_ratio()


func _on_valid_text_changed(new_text: String, old_text: String) -> void:
	update_submit_button_tooltip()
	update_tooltip()
	value_changed.emit(eval(new_text), eval(old_text))


func accept_corrected() -> void:
	line_edit.text = last_valid_text
	status = Status.OK
	status_changed.emit(status, Status.CORRECTED)
	update_submit_button_tooltip()


func submit() -> void:
	# Match every case because `accept_corrected` modifies status
	match status:
		Status.WRONG:
			accept_corrected()
		Status.CORRECTED:
			accept_corrected()
			submited.emit(eval(last_valid_text))
		Status.OK:
			submited.emit(eval(last_valid_text))


## Create regexes matching the same strings as [member file_patterns]
func _build_file_regexes() -> void:
	_file_regexes.clear()
	
	for line in file_patterns:
		for pattern in line.split(";", false)[0].split(","):
			## Build Regex from file pattern
			_file_regexes.push_back(
				RegEx.create_from_string(
					"^%s$" % (
						pattern.strip_edges().replace(
							".", "\\." # Escape dot
						).replace(
							"*", ".*" # * matches any character 0 or more times
						).replace(
							"?", "." # ? matches any character 1 time
						)
					)
				)
			)


## Perform modifications to enable/disable functionnalities according to [member type]
func _adapt_to_type() -> void:
	# Show or not the file dialog button
	if open_file_dialog_button:
		open_file_dialog_button.visible = type == Types.DIRECTORY or type == Types.FILE
		shrink()
	
	# Update last_valid_text if it was left to default
	if last_valid_text in default_valid_texts:
		last_valid_text = default_valid_texts[type]
	
	_setup_expression()


func _setup_expression() -> void:
	if type == Types.INT or type == Types.FLOAT:
		_expression = Expression.new()
	else:
		_expression = null


func _on_line_edit_text_submitted(new_text: String) -> void:
	submit()
func _on_submit_pressed() -> void:
	submit()


func update_locale() -> void:
	update_tooltip()
	update_submit_button_tooltip()


# DO NOT EDIT THIS FUNCTION HERE, see res://addons/smart_line_edit/config.tool.gd
# REGEX_FUNC_A
## Call [code]get_tree().call_group("locale_changed_listeners", "on_locale_changed")[/code]
## when changing locale to update strings that are using locale.
func on_locale_changed() -> void:
	update_locale()
# REGEX_FUNC_B

# DO NOT EDIT THIS FUNCTION HERE, see res://addons/smart_line_edit/config.tool.gd
# REGEX_NOTIF_A
func _notification(what: int) -> void:
	if not Engine.is_editor_hint():
		match what:
			NOTIFICATION_TRANSLATION_CHANGED:
				on_locale_changed()
# REGEX_NOTIF_B
