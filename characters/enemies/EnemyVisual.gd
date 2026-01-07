extends Node3D
class_name EnemyVisual

@export_category("Animation Names")
@export var idle_animation := "idle"
@export var walk_animation := "walk"
@export var attack_animation := "attack"
@export var death_animation := "die"

var _anim: AnimationPlayer
var _current: StringName

func _ready():
	# Ищем AnimationPlayer ТОЛЬКО внутри Visual
	_anim = find_child("AnimationPlayer", true, false)

	if _anim == null:
		push_error(
			"EnemyVisual: AnimationPlayer not found inside Visual. " +
			"Make sure model scene is a child of Visual."
		)

func _play(name: String):
	if _anim == null:
		return
	if name == _current:
		return
	if _anim.has_animation(name):
		_current = name
		_anim.play(name)

func play_idle():
	_play(idle_animation)

func play_walk():
	_play(walk_animation)

func play_attack():
	_play(attack_animation)

func play_death():
	_play(death_animation)
