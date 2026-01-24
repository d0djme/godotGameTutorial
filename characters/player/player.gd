extends CharacterBody3D

@onready var camera_3d = $Camera3D 
@onready var character_mover = $CharacterMover
@onready var health_manager = $HealthManager
@onready var weapon_manager = $Camera3D/WeaponManager
@onready var death_screen = $PlayerUILayer/DeathScreen
@onready var pause_menu = $PlayerUILayer/PauseMenu


@export var recoil_up_deg := 1.1
@export var recoil_side_deg := 0.35
@export var recoil_return_speed := 18.0

var look_yaw_deg: float = 0.0
var look_pitch_deg: float = 0.0

var recoil_pitch_deg: float = 0.0
var recoil_yaw_deg: float = 0.0


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
	weapon_manager.weapon_fired.connect(_on_weapon_fired)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health_manager.died.connect(kill)

	look_yaw_deg = rotation_degrees.y
	look_pitch_deg = camera_3d.rotation_degrees.x
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health_manager.died.connect(kill)

# =====================================================

func _input(event):
	if dead:
		return

	if event is InputEventMouseMotion:
		look_yaw_deg -= event.relative.x * mouse_sensitivity_h
		look_pitch_deg -= event.relative.y * mouse_sensitivity_v
		look_pitch_deg = clamp(look_pitch_deg, -90.0, 90.0)

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			weapon_manager.switch_to_previous_weapon()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			weapon_manager.switch_to_next_weapon()

	if event is InputEventKey and event.pressed and event.keycode in HOTKEYS:
		weapon_manager.switch_to_weapon_slot(HOTKEYS[event.keycode])

# =====================================================

func _process(_delta):
	if Input.is_action_pressed("pause"):
		if pause_menu.visible:
			pause_menu.close()
		else:
			pause_menu.open()
	# --- Системные хоткеи ---

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
	if Input.is_action_just_pressed("reload"):
		weapon_manager.reload_current()

	
	# применяем итоговый прицел
	rotation_degrees.y = look_yaw_deg + recoil_yaw_deg
	camera_3d.rotation_degrees.x = clamp(look_pitch_deg - recoil_pitch_deg, -90.0, 90.0)

	# плавный возврат отдачи к 0
	var k := 1.0 - exp(-recoil_return_speed * _delta)
	recoil_pitch_deg = lerpf(recoil_pitch_deg, 0.0, k)
	recoil_yaw_deg = lerpf(recoil_yaw_deg, 0.0, k)
# =====================================================

func kill():
	dead = true
	character_mover.set_move_dir(Vector3.ZERO)
	death_screen.show_death_screen()

func hurt(damage_data: DamageData):
	health_manager.hurt(damage_data)
	
func _on_weapon_fired():
	recoil_pitch_deg += recoil_up_deg
	recoil_yaw_deg += randf_range(-recoil_side_deg, recoil_side_deg)
