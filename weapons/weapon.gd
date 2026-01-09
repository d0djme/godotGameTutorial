extends Node3D

class_name Weapon

# Ссылки на оба аниматора
@onready var animation_player : AnimationPlayer = $Graphics/AnimationPlayer_v1
@onready var old_animation_player : AnimationPlayer = $Graphics/AnimationPlayer # Старый аниматор

@onready var bullet_emitter : BulletEmitter = $BulletEmitter
@onready var fire_point : Node3D = %FirePoint

@export var automatic = false
@export var damage = 5
@export var ammo = 0
@export var attack_rate = 0.2
@export var mag_size: int = 30
@export var ammo_in_mag: int = 30
@export var ammo_reserve: int = 90
@export var reload_time: float = 1.9

var last_attack_time = -9999.9

@export var animation_controlled_attack = false
@export var silent_weapon = false
@export var uses_magazines: bool = false


signal fired
signal out_of_ammo
signal ammo_updated(ammo_amnt: int)
signal ammo_state_changed(ammo_in_mag: int, ammo_reserve: int)
signal reload_started
signal reload_finished

var is_reloading: bool = false

func _ready():
	bullet_emitter.set_damage(damage)

func _process(_delta):
	# Если оружие активно и ни один из аниматоров ничего не играет — запускаем idle
	if visible:
		if !is_any_animation_playing():
			_safe_play("idle")

## Универсальная функция проигрывания с приоритетом и защитой от null
func _safe_play(anim_name: String):
	# Проверка инициализации (защита от ошибки 'null value')
	if animation_player == null: animation_player = get_node_or_null("Graphics/AnimationPlayer2")
	if old_animation_player == null: old_animation_player = get_node_or_null("AnimationPlayer")

	# 1. Сначала пробуем новый аниматор
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	# 2. Если в новом нет такой анимации, пробуем старый
	elif old_animation_player and old_animation_player.has_animation(anim_name):
		old_animation_player.play(anim_name)
	# 3. Если анимации нет нигде — просто ничего не делаем (пропуск)

## Останавливаем оба аниматора перед важным действием (например, выстрелом)
func _stop_all_animations():
	if animation_player: animation_player.stop()
	if old_animation_player: old_animation_player.stop()

## Проверка: занят ли какой-то из аниматоров сейчас?
func is_any_animation_playing() -> bool:
	var new_playing = animation_player.is_playing() if animation_player else false
	var old_playing = old_animation_player.is_playing() if old_animation_player else false
	return new_playing or old_playing

func set_bodies_to_exclude(bodies: Array):
	bullet_emitter.set_bodies_to_exclude(bodies)

func attack(input_just_pressed: bool, input_held: bool):
	if !automatic and !input_just_pressed:
		return
	if automatic and !input_held:
		return
	if is_reloading:
		return

	# --- Проверка боезапаса ---
	if uses_magazines:
		if ammo_in_mag <= 0:
			if input_just_pressed:
				out_of_ammo.emit()
				if has_node("OutOfAmmoSound"):
					$OutOfAmmoSound.play()
			return
	else:
		if ammo <= 0:
			if input_just_pressed:
				out_of_ammo.emit()
				if has_node("OutOfAmmoSound"):
					$OutOfAmmoSound.play()
			return

	# --- Скорострельность ---
	var cur_time := Time.get_ticks_msec() / 1000.0
	if cur_time - last_attack_time < attack_rate:
		return
	last_attack_time = cur_time

	# --- Тратим патроны ---
	if uses_magazines:
		ammo_in_mag -= 1
		ammo_state_changed.emit(ammo_in_mag, ammo_reserve)
	else:
		ammo -= 1
		ammo_updated.emit(ammo)

	# --- Выстрел ---
	if !animation_controlled_attack:
		actually_attack()

	_stop_all_animations()
	_safe_play("fire")
	fired.emit()
	if has_node("AttackSounds"):
		$AttackSounds.play()

	if has_node("Graphics/MuzzleFlash"):
		$Graphics/MuzzleFlash.flash()


func actually_attack():
	bullet_emitter.global_transform = fire_point.global_transform
	bullet_emitter.fire()


func can_reload() -> bool:
	if !uses_magazines:
		return false
	return !is_reloading and ammo_in_mag < mag_size and ammo_reserve > 0

func reload() -> void:
	if !uses_magazines:
		return
	if !can_reload():
		return

	is_reloading = true
	reload_started.emit()

	_stop_all_animations()
	_safe_play("reload")

	if has_node("ReloadSound"):
		$ReloadSound.play()

	await get_tree().create_timer(reload_time).timeout

	var need := mag_size - ammo_in_mag
	var take: int = min(need, ammo_reserve)

	ammo_in_mag += take
	ammo_reserve -= take

	ammo_state_changed.emit(ammo_in_mag, ammo_reserve)

	is_reloading = false
	reload_finished.emit()


func set_active(a: bool):
	$Crosshairs.visible = a
	visible = a
	if !a:
		_stop_all_animations()
		_safe_play("RESET")
	else:
		if has_node("EquipSound"):
			$EquipSound.play()
		_safe_play("drawAction")

		# обновляем HUD
		if uses_magazines:
			ammo_state_changed.emit(ammo_in_mag, ammo_reserve)
		else:
			ammo_updated.emit(ammo)


func is_idle() -> bool:
	return !is_any_animation_playing()

func add_ammo(amnt: int) -> void:
	if uses_magazines:
		ammo_reserve += amnt
		ammo_state_changed.emit(ammo_in_mag, ammo_reserve)
	else:
		ammo += amnt
		ammo_updated.emit(ammo)
