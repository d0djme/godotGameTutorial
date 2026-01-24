extends Area3D

func _ready() -> void:
	# подключаем сигнал
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	# проверка, что это игрок
	if body.is_in_group("player"):
		print("⚡ Player exited level!")
		# временно можно запустить меню:
		get_tree().change_scene_to_file("res://ui/main_menu.tscn")
