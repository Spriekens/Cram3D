extends ColorRect

onready var width_box = $MainMenuCenterContainer/VBoxContainer/WidthHBox/WidthBox
onready var length_box = $MainMenuCenterContainer/VBoxContainer/LengthHBox/LengthBox
onready var height_box = $MainMenuCenterContainer/VBoxContainer/HeightHBox/HeightBox
onready var AI_turn_button = $MainMenuCenterContainer/VBoxContainer/AIHBox/AITurn
onready var board = get_parent().get_node("Board")
onready var gui = get_parent().get_node("GUI")

var AI_first = true

func hide() -> void:
	visible = false

func show() -> void:
	visible = true

func toggle_AI_turn() -> void:
	AI_first = not AI_first
	if AI_first:
		AI_turn_button.text = "AI: 1st"
	else:
		AI_turn_button.text = "AI: 2nd"

func _on_VersusHuman_pressed() -> void:
	board.ai_play = false
	gui.show()
	gui.show_nimber_label()
	board.initialize_board(width_box.value, length_box.value, height_box.value)
	hide()

func _on_VersusAI_pressed() -> void:
	board.ai_play = true
	board.ai_turn = AI_first
	gui.show()
	gui.hide_nimber_label()
	board.initialize_board(width_box.value, length_box.value, height_box.value)
	hide()

func _on_AITurn_toggled(_button_pressed: bool) -> void:
	toggle_AI_turn()

func _on_ExitButton_pressed() -> void:
	get_tree().quit()
