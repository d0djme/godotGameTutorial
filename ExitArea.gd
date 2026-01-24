extends Area3D

@export var stats_screen_scene: PackedScene
var _triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _triggered:
		return
	if not body.is_in_group("player"):
		return

	_triggered = true

	print("Player touched ExitArea")

	LevelStats.finish_level()
	get_tree().paused = true

	if stats_screen_scene:
		var ui = stats_screen_scene.instantiate()
		get_tree().current_scene.add_child(ui)
	else:
		print("stats_screen_scene is NOT set in Inspector")
