extends Node2D

@onready var map: Node2D = $Map
@onready var timer: Timer = $Timer

const MAX_NODES = 20
const NUM_LINES = 5

const MARGINS = [
	40, # left margin
	40, # top margin
	40, # right margin
	40, # bottom margin
]

var execute_tick = true
var elapsed_time = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Globals.TICK = 0
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	elapsed_time += delta
	if not execute_tick : return
	map.tick(elapsed_time)
	execute_tick = false
	timer.start(1.0 / Globals.TICKSPEED)
	elapsed_time = 0
	Globals.TICK += 1
	pass

func _on_timer_timeout() -> void:
	execute_tick = true
	pass # Replace with function body.
