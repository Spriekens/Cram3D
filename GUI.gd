extends MarginContainer

export(NodePath) onready var turn_label = get_node(turn_label) as Label
export(NodePath) onready var nimber_label = get_node(nimber_label) as Label

export(Color) var BLUE_COLOR = Color(0, 0, 1)
export(Color) var RED_COLOR = Color(1, 0, 0)

func _ready():
	hide()

func show() -> void:
	visible = true

func hide() -> void:
	visible = false

func show_nimber_label() -> void:
	nimber_label.visible = true

func hide_nimber_label() -> void:
	nimber_label.visible = false

func update_turn_label(new_text: String) -> void:
	turn_label.text = new_text
	new_text = new_text.to_lower()
	if "blue" in new_text and "red" in new_text:
		turn_label.set("custom_colors/font_color", Color.white)
	elif "blue" in new_text:
		turn_label.set("custom_colors/font_color", BLUE_COLOR)
	elif "red" in new_text:
		turn_label.set("custom_colors/font_color", RED_COLOR)

func update_nimber_label(nimber: int) -> void:
	var new_text = "Value: "
	match nimber:
		-1:
			new_text += "[N]"
		-2:
			new_text += "Calculating..."
		0:
			new_text += "0"
		1:
			new_text += "*"
		_:
			new_text += "*" + str(nimber)
	nimber_label.text = new_text
