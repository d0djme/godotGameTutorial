class_name Monster
extends CharacterBody3D

@onready var health_manager = $HealthManager
@onready var vision_manager = $VisionManager
@onready var ai_character_mover = $AICharacterMover
@onready var attack_emitter = $AttackEmitter
@onready var nearby_monsters_alert_area = $NearbyMonstersAlertArea
@onready var visual: EnemyVisual = $Graphics/Visual

@onready var player = get_tree().get_first_node_in_group("player")

enum STATES { IDLE, ATTACK, DEAD }
var cur_state := STATES.IDLE

@export var attack_range := 2.0
@export var damage := 15
@export var attack_speed_modifier := 1.0

var is_attacking := false

func _ready():
	if visual == null:
		push_error("EnemyVisual NOT FOUND: check Graphics/Visual")
		return

	var hitboxes = find_children("*", "HitBox")
	for hitbox in hitboxes:
		hitbox.on_hurt.connect(health_manager.hurt)

	health_manager.died.connect(set_state.bind(STATES.DEAD))
	health_manager.gibbed.connect(queue_free)

	hitboxes.append(self)
	attack_emitter.set_bodies_to_exclude(hitboxes)
	attack_emitter.set_damage(damage)

	set_state(STATES.IDLE)

func hurt(damage_data: DamageData):
	health_manager.hurt(damage_data)

func alert():
	if cur_state == STATES.IDLE:
		$AlertSound.play()
		set_state(STATES.ATTACK)
		alert_nearby_monsters()

func alert_nearby_monsters():
	for body in nearby_monsters_alert_area.get_overlapping_bodies():
		if body is Monster:
			body.alert()

func set_state(state: STATES):
	if visual:
		visual.play_idle()

	if cur_state == STATES.DEAD:
		return

	cur_state = state

	match cur_state:
		STATES.IDLE:
			is_attacking = false
			visual.play_idle()

		STATES.DEAD:
			visual.play_death()
			collision_layer = 0
			collision_mask = 1
			ai_character_mover.stop_moving()

func _process(delta):
	match cur_state:
		STATES.IDLE:
			process_idle_state(delta)
		STATES.ATTACK:
			process_attack_state(delta)

func process_idle_state(_delta):
	if vision_manager.can_see_target(player):
		alert()

func process_attack_state(_delta):
	var vec_to_player = player.global_position - global_position
	var dist = vec_to_player.length()

	if dist <= attack_range:
		ai_character_mover.stop_moving()

		if not is_attacking and vision_manager.is_facing_target(player):
			start_attack()
		elif not is_attacking:
			ai_character_mover.set_facing_dir(vec_to_player)
	else:
		if not is_attacking:
			ai_character_mover.set_facing_dir(ai_character_mover.move_dir)
			ai_character_mover.move_to_point(player.global_position)
			visual.play_walk()

func start_attack():
	is_attacking = true
	$AttackSound.play()
	visual.play_attack()

func do_attack(): # вызывается из анимации
	attack_emitter.fire()

func end_attack(): # вызвать из animation (в конце атаки)
	is_attacking = false
