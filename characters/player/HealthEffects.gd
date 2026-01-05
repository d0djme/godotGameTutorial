extends Control

@onready var health_manager = %HealthManager

@onready var healed = $Healed
@onready var hurt = $Hurt
@onready var animation_player = $AnimationPlayer

func _ready():
	health_manager.healed.connect(on_heal)
	health_manager.damaged.connect(on_hurt)

func on_hurt():
	animation_player.play("flash")
	hurt.show()
	healed.hide()

func on_heal():
	animation_player.play("flash")
	healed.show()
	hurt.hide()
