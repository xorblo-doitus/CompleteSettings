extends HBoxContainer


signal canceled()
signal applied()
signal validated()


@export var cancel_button: Button:
	set(new):
		if cancel_button and cancel_button.pressed.is_connected(cancel):
			cancel_button.pressed.disconnect(cancel)
		cancel_button = new
		if new:
			cancel_button.pressed.connect(cancel)

@export var apply_button: Button:
	set(new):
		if apply_button and apply_button.pressed.is_connected(apply):
			apply_button.pressed.disconnect(apply)
		apply_button = new
		if new:
			apply_button.pressed.connect(apply)

@export var validate_button: Button:
	set(new):
		if validate_button and validate_button.pressed.is_connected(validate):
			validate_button.pressed.disconnect(validate)
		validate_button = new
		if new:
			validate_button.pressed.connect(validate)



func _ready() -> void:
	if cancel_button == null and has_node("Cancel"):
		cancel_button = $Cancel
	if apply_button == null and has_node("Apply"):
		apply_button = $Apply
	if validate_button == null and has_node("Validate"):
		validate_button = $Validate



func cancel():
	canceled.emit()

func apply():
	applied.emit()

func validate():
	validated.emit()
