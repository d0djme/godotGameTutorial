extends Control

@onready var resume_button := find_child("ResumeButton", true, false)

func open():
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if resume_button:
		resume_button.grab_focus()
	else:
		push_error("ResumeButton not found")
func close():
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume_button_pressed() -> void:
	close()


func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()
