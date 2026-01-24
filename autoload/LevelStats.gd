extends Node

var level_name: String = ""
var start_time_msec: int = 0
var end_time_msec: int = 0

var kills: int = 0
var total_kills: int = 0

var secrets: int = 0
var total_secrets: int = 0

var items: int = 0
var total_items: int = 0

func begin_level(name: String) -> void:
	level_name = name
	start_time_msec = Time.get_ticks_msec()
	end_time_msec = 0
	kills = 0
	total_kills = 0
	secrets = 0
	total_secrets = 0
	items = 0
	total_items = 0

func finish_level() -> void:
	end_time_msec = Time.get_ticks_msec()

func time_seconds() -> float:
	if end_time_msec == 0:
		return float(Time.get_ticks_msec() - start_time_msec) / 1000.0
	return float(end_time_msec - start_time_msec) / 1000.0

func time_str() -> String:
	var t := int(round(time_seconds()))
	return "%02d:%02d" % [t / 60, t % 60]
