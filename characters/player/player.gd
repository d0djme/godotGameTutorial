extends CharacterBody3D

@onready var camera_3d = $Camera3D 
@onready var character_mover = $CharacterMover
@onready var health_manager = $HealthManager
@onready var weapon_manager = $Camera3D/WeaponManager
@onready var death_screen = $PlayerUILayer/DeathScreen

@export var mouse_sensitivity_h := 0.15
@export var mouse_sensitivity_v := 0.15

const HOTKEYS = {
	KEY_1: 0,
	KEY_2: 1,
	KEY_3: 2,
	KEY_4: 3,
	KEY_5: 4,
	KEY_6: 5,
	KEY_7: 6,
	KEY_8: 7,
	KEY_9: 8,
	KEY_0: 9,
}

var dead := false

# =====================================================

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health_manager.died.connect(kill)

# =====================================================

func _input(event):
	if dead:
		return

	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * mouse_sensitivity_h
		camera_3d.rotation_degrees.x -= event.relative.y * mouse_sensitivity_v
		camera_3d.rotation_degrees.x = clamp(camera_3d.rotation_degrees.x, -90, 90)

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			weapon_manager.switch_to_previous_weapon()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			weapon_manager.switch_to_next_weapon()

	if event is InputEventKey and event.pressed and event.keycode in HOTKEYS:
		weapon_manager.switch_to_weapon_slot(HOTKEYS[event.keycode])

# =====================================================

func _process(_delta):
	# --- Системные хоткеи ---
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

	if Input.is_action_just_pressed("restart"):
		get_tree().call_group("instanced", "queue_free")
		get_tree().reload_current_scene()

	if Input.is_action_just_pressed("fullscreen"):
		var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if fs
			else DisplayServer.WINDOW_MODE_FULLSCREEN
		)

	if dead:
		return

	# --- Движение ---
	var input_dir := Input.get_vector(
		"move_left",
		"move_right",
		"move_forwards",
		"move_backwards"
	)

	var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	character_mover.set_move_dir(move_dir)

	# --- Прыжок ---
	if Input.is_action_just_pressed("jump"):
		character_mover.jump()

	# --- Дэш ---
	if Input.is_action_just_pressed("dash"):
		character_mover.dash()

	# --- Слайд ---
	if Input.is_action_just_pressed("slide"):
		if character_mover.is_sliding:
			character_mover.stop_slide()
		else:
			character_mover.start_slide()

	# --- Оружие ---
	weapon_manager.attack(
		Input.is_action_just_pressed("attack"),
		Input.is_action_pressed("attack")
	)

# =====================================================

func kill():
	dead = true
	character_mover.set_move_dir(Vector3.ZERO)
	death_screen.show_death_screen()

func hurt(damage_data: DamageData):
	health_manager.hurt(damage_data)
