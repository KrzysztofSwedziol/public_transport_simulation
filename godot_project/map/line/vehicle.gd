extends Node2D
@onready var area_2d: Area2D = $Area2D

var COLOR
var path
var stops
var speed
var capacity
var stop_duration

var path_position := 0
var next_position: Vector2

var moving = true

var go_time = -1

func _ready() -> void:
	z_index = 2
	self.area_2d.hide()

	if path.is_empty():
		queue_free()
		return

	position = path[0].position
	path_position = 1

	if path_position >= path.size():
		queue_free()
		return

	next_position = path[path_position].position


func _process(delta: float) -> void:
	if self.moving : 
		var step = speed * delta * Globals.TICKSPEED

		position = position.move_toward(next_position, step)

		if position == next_position:
			path_position += 1

			if path_position >= path.size():
				queue_free()
				return

			next_position = path[path_position].position
			
			for stop in self.stops :
				if stop.position == self.position :
					self.go_time = (Globals.TICK + self.stop_duration) % 1440
					self.moving = false
					self.area_2d.show()
					break
	else :
		if Globals.TICK == self.go_time :
			self.moving = true
			self.area_2d.hide()
