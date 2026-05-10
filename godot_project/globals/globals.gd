extends Node

# how many minutes pass every second
const TICKSPEED = 2 

var TICK: int:
	set(value):
		TICK = value % 1440

var _line_number = 0
var _line_colors = []

func get_line_number() :
	var value =  _line_number
	_line_number += 1
	return value

func random_color() -> Color:
	var RNG = RandomNumberGenerator.new()
	RNG.randomize()
	return Color(
		RNG.randf(),
		RNG.randf(),
		RNG.randf(),
		1.0
	)

func get_line_color(line_number) :
	while line_number >= self._line_colors.size() :
		self._line_colors.append(random_color())
	return self._line_colors[line_number]
