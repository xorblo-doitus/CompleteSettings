class_name VBoxContainerWithLines
extends VBoxContainer



var line_margin: float:
	set(new):
		line_margin_x = new
		line_margin_y = new

var line_margin_x: float = 0
var line_margin_y: float = 0


func _ready() -> void:
	sort_children.connect(queue_redraw)



func _draw() -> void:
	var children: Array[Control] = []
	for child in get_children():
		if child is Control:
			children.push_back(child)
	
	if children.size() < 2:
		return
	
	var depth: float = 0
	for i in children.size() - 1:
		depth += children[i].size.y + get_theme_constant(&"separation") / 2.0
		draw_line(Vector2(line_margin_x, depth), Vector2(size.x - line_margin_y, depth), Color.WHITE)
