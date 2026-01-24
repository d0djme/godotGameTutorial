extends Control

@onready var time_label: Label = $CenterContainer/VBoxContainer/Time
@onready var kills_label: Label = $CenterContainer/VBoxContainer/Kills

@onready var next_button: Button = $CenterContainer/VBoxContainer/Next
@onready var restart_button: Button = $CenterContainer/VBoxContainer/Restart
@onready var menu_button: Button = $CenterContainer/VBoxContainer/"Return to menu"

func _ready() -> void:
	# Важно для UI на паузе
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Вернуть курсор для кликов
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	_set_player_hud_visible(false)
	
func _set_player_hud_visible(visible: bool) -> void:
	for n in get_tree().get_nodes_in_group("player_hud"):
		if n is CanvasItem:
			n.visible = visible


	# Заполняем текст
	_update_labels()

	# Подключаем кнопки
	next_button.pressed.connect(_on_next_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _update_labels() -> void:
	time_label.text = "Time: %s" % LevelStats.time_str()
	kills_label.text = "Kills: %d" % LevelStats.kills

func _close_overlay_restore_game() -> void:
	# Снять паузу и вернуть “шутерный” режим мыши
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_set_player_hud_visible(true)



func _on_next_pressed() -> void:
	_close_overlay_restore_game()
	# Временно: просто перезапускаем уровень
	get_tree().reload_current_scene()

func _on_restart_pressed() -> void:
	_close_overlay_restore_game()
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	# Меню обычно хочет курсор, поэтому оставляем visible
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
