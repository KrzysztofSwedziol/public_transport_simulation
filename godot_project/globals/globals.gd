extends Node

const MIN_TICKSPEED = 1.0/6.0
const MAX_TICKSPEED = 30

# how many minutes pass every second
var TICKSPEED := 10.0:
	set(value) :
		TICKSPEED = clamp(value, MIN_TICKSPEED, MAX_TICKSPEED)

const MARGINS = [
	50,   # left margin
	50,   # top margin
	500,  # right margin
	50,   # bottom margin
]

var TICK: int:
	set(value):
		TICK = value % 1440

var _line_number = 0
var _line_colors = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func get_line_number() -> int:
	var value = _line_number
	_line_number += 1
	return value

func random_color() -> Color:
	return Color(
		_rng.randf(),
		_rng.randf(),
		_rng.randf(),
		1.0
	)

func get_line_color(line_number: int) -> Color:
	while line_number >= _line_colors.size():
		_line_colors.append(random_color())
	return _line_colors[line_number]
