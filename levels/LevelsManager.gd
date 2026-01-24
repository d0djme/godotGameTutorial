# LevelManager.gd
extends Node3D

@export var level_display_name: String = "WORLD LEVEL"
@export var stats_screen: PackedScene

func _ready() -> void:
	LevelStats.begin_level(level_display_name)
	
	# Найти ExitArea и подключить сигнал
	var exit_area = $ExitArea
	if exit_area:
		exit_area.body_entered.connect(_on_exit_trigger)

func _on_exit_trigger(body: Node) -> void:
	if body.is_in_group("player"):
		_finish_level()

func _finish_level() -> void:
	# фиксируем время
	LevelStats.finish_level()

	# ставим игру на паузу (UI ещё работает)
	get_tree().paused = true

	# Показываем экран статистики
	if stats_screen:
		var ui = stats_screen.instantiate()
		get_tree().current_scene.add_child(ui)
