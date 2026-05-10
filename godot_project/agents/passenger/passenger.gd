extends Node2D

var COLOR = Color.BLACK
var path
var stops
var speed = 100
var capacity

var path_position := 0
var next_position: Vector2
var spawn
var target

func set_nodes(spawn, target, start, end) :
	self.spawn = spawn
	self.target = target
	self.position = spawn
	
	path = get_passenger_path(start, end)
	
	if path.size() > 0 :
		next_position = path[0].position
	else :
		next_position = target

func get_passenger_path(start, end) :
	if start == end : return []
	#var parent_map = Globals.bfs(start, end)
	#var new_path = []
	#var current = end
	#while current != null :
		#new_path.append(current)
		#current = parent_map[current]
	#new_path.reverse()
	#return new_path
	return []

func _ready() -> void:
	z_index = 3
	
	
	
	#position = path[0].position
	#path_position = 1

	#if path_position >= path.size():
		#queue_free()
		#return

	#next_position = path[path_position].position


func _process(delta: float) -> void:
	var step = speed * delta * Globals.TICKSPEED

	position = position.move_toward(next_position, step)

	if position == next_position:
		path_position += 1
		
		if path_position == path.size():
			next_position = self.target
			return

		if path_position > path.size():
			queue_free()
			return

		next_position = path[path_position].position
	
	self.queue_redraw()
