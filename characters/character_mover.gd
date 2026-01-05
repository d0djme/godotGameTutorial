class_name CharacterMover
extends Node3D

# ===== БАЗОВОЕ ДВИЖЕНИЕ =====
@export var jump_force := 15.0
@export var gravity := 30.0

@export var max_speed := 15.0
@export var move_accel := 4.0
@export var stop_drag := 0.9

# ===== ДЭШ =====
@export var dash_speed := 30.0
@export var dash_duration := 0.2
@export var dash_cooldown := 1.0

# ===== СЛАЙД =====
@export var slide_speed := 20.0
@export var slide_duration := 1.0
@export var slide_cooldown := 2.0
@export var slide_height := 0.5

# ===== ССЫЛКИ =====
var character_body: CharacterBody3D
var collision_shape: CollisionShape3D
var original_height := 2.0

# ===== ДВИЖЕНИЕ =====
var move_dir := Vector3.ZERO
var move_drag := 0.0

# ===== СОСТОЯНИЯ =====
var is_dashing := false
var dash_timer := 0.0
var dash_cooldown_timer := 0.0

var is_sliding := false
var slide_timer := 0.0
var slide_cooldown_timer := 0.0

signal moved(velocity: Vector3, grounded: bool)
signal dashed()
signal slide_started()
signal slide_ended()

# ======================================================

func _ready():
	character_body = get_parent()
	collision_shape = character_body.get_node_or_null("CollisionShape3D")

	if collision_shape and collision_shape.shape is CapsuleShape3D:
		original_height = collision_shape.shape.height

	move_drag = float(move_accel) / max_speed

# ======================================================

func set_move_dir(new_move_dir: Vector3):
	move_dir = new_move_dir
	move_dir.y = 0.0
	move_dir = move_dir.normalized()

# ======================================================

func jump():
	if character_body.is_on_floor() or is_sliding:
		if has_node("JumpSound"):
			$JumpSound.play()

		character_body.velocity.y = jump_force

		if is_sliding:
			stop_slide()

# ======================================================

func dash():
	if is_dashing or dash_cooldown_timer > 0.0:
		return

	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown

	var dir := move_dir
	if dir.is_zero_approx():
		dir = -character_body.global_transform.basis.z

	character_body.velocity = Vector3(
		dir.x * dash_speed,
		0.0,
		dir.z * dash_speed
	)

	dashed.emit()

# ======================================================

func start_slide():
	if is_sliding or slide_cooldown_timer > 0.0:
		return
	if not character_body.is_on_floor():
		return

	is_sliding = true
	slide_timer = slide_duration
	slide_cooldown_timer = slide_cooldown

	if collision_shape and collision_shape.shape is CapsuleShape3D:
		var delta_h = original_height - slide_height
		collision_shape.shape.height = slide_height
		character_body.position.y -= delta_h * 0.5

	var dir := move_dir
	if dir.is_zero_approx():
		dir = -character_body.global_transform.basis.z

	character_body.velocity.x = dir.x * slide_speed
	character_body.velocity.z = dir.z * slide_speed


func stop_slide():
	if not is_sliding:
		return

	is_sliding = false

	if collision_shape and collision_shape.shape is CapsuleShape3D:
		collision_shape.shape.height = original_height

	slide_ended.emit()

# ======================================================

func _physics_process(delta):
	# --- Таймеры ---
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
	if slide_cooldown_timer > 0.0:
		slide_cooldown_timer -= delta

	# --- Дэш ---
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false

	# --- Слайд ---
	if is_sliding:
		slide_timer -= delta
		if slide_timer <= 0.0 or not character_body.is_on_floor():
			stop_slide()

	# --- Гравитация ---
	if not is_dashing:
		if character_body.velocity.y > 0.0 and character_body.is_on_ceiling():
			character_body.velocity.y = 0.0

		if not character_body.is_on_floor():
			character_body.velocity.y -= gravity * delta

	# --- Обычное движение ---
	if not is_dashing and not is_sliding:
		var drag := move_drag
		if move_dir.is_zero_approx():
			drag = stop_drag

		var flat_velo := character_body.velocity
		flat_velo.y = 0.0

		character_body.velocity += move_accel * move_dir - flat_velo * drag

	character_body.move_and_slide()
	moved.emit(character_body.velocity, character_body.is_on_floor())
