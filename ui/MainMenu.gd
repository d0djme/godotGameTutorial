extends Control

@export var first_level_scene: String = "res://world.tscn"

@onready var main_buttons = $CenterContainer/Panel/VBox
@onready var settings_panel = $CenterContainer/Panel/SettingsPanel
@onready var volume_slider = $CenterContainer/Panel/SettingsPanel/VBoxSettings/HBoxVolume/VolumeSlider
@onready var sensitivity_slider = $CenterContainer/Panel/SettingsPanel/VBoxSettings/HBoxSensitivity/SensitivitySlider


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	$CenterContainer/Panel/VBox/Start.grab_focus()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(first_level_scene)


func _on_settings_pressed() -> void:
	main_buttons.visible = false
	settings_panel.visible = true
	settings_panel.get_node("VBoxSettings/BackButton").grab_focus()


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_back_button_pressed() -> void:
	settings_panel.visible = false
	main_buttons.visible = true
	$CenterContainer/Panel/VBox/Start.grab_focus()


func _on_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(value)
	)
	
static var mouse_sensitivity := 1.0

func _on_sensitivity_slider_value_changed(value: float) -> void:
	mouse_sensitivity = value
