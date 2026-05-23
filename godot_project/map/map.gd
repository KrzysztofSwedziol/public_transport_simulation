extends Node2D

@onready var main: Node2D = $".."

# Edge class for transit connections between stops
class Edge:
	var start_node: Node2D
	var end_node: Node2D
	var distance: float
	var travel_time: float
	var cost: float
	var line_info: Dictionary  # {line_number: int, line_ref: Node2D, direction: int}
	
	func _init(start: Node2D, end: Node2D, dist: float, time: float, info: Dictionary) -> void:
		start_node = start
		end_node = end
		distance = dist
		travel_time = time
		cost = time  # Initially cost equals travel time
		line_info = info

const NODE = preload("res://map/node/node.tscn")
const ROAD = preload("res://map/road/road.tscn")
const AREA = preload("res://map/area/area.tscn")
const LINE = preload("res://map/line/line.tscn")
const PASSENGER = preload("res://agents/passenger/passenger.tscn")

# Assumed speeds (pixels per simulation-minute) and stop duration (minutes)
const ASSUMED_WALK_SPEED = 100
const ASSUMED_VEHICLE_SPEED = 50
const ASSUMED_STOP_DURATION = 2
var nodes: Array[Node2D] = []
var roads := {}
var lines: Array[Node2D] = []
var rng := RandomNumberGenerator.new()

var prev_click = null

func _ready() -> void:
	rng.randomize()
	populate_with_nodes()
	connect_voronoi_neighbours()
	generate_lines()
	_generate_virtual_edges()

func generate_lines() -> void:
	for i in range(main.NUM_LINES):
		var start = rng.randi_range(0, nodes.size() - 1)
		var through = rng.randi_range(0, nodes.size() - 1)
		var end = rng.randi_range(0, nodes.size() - 1)
		
		while through == start:
			through = rng.randi_range(0, nodes.size() - 1)
		while end == through or end == start:
			end = rng.randi_range(0, nodes.size() - 1)
		
		var line = LINE.instantiate()
		line.initialize(nodes[start], nodes[through], nodes[end])
		add_child(line)
		lines.append(line)

func populate_with_nodes() -> void:
	var size = get_viewport().get_visible_rect().size
	
	for i in range(main.MAX_NODES):
		var current_node = NODE.instantiate() as Node2D
		add_child(current_node)
		current_node.position = Vector2(
			rng.randf_range(Globals.MARGINS[0], size.x - Globals.MARGINS[2]),
			rng.randf_range(Globals.MARGINS[1], size.y - Globals.MARGINS[3])
		)
		nodes.append(current_node)

func spawn_passenger(spawn_position = null, target_position = null) -> void:
	var size = get_viewport().get_visible_rect().size
	var randomize_positions = spawn_position == null or target_position == null
	
	if randomize_positions:
		spawn_position = Vector2(
			rng.randf_range(Globals.MARGINS[0], size.x - Globals.MARGINS[2]),
			rng.randf_range(Globals.MARGINS[1], size.y - Globals.MARGINS[3])
		)
		target_position = Vector2(
			rng.randf_range(Globals.MARGINS[0], size.x - Globals.MARGINS[2]),
			rng.randf_range(Globals.MARGINS[1], size.y - Globals.MARGINS[3])
		)
	
	var start_node = get_closest_node(spawn_position)
	var end_node = get_closest_node(target_position)
	
	if randomize_positions:
		while start_node == end_node:
			target_position = Vector2(
				rng.randf_range(Globals.MARGINS[0], size.x - Globals.MARGINS[2]),
				rng.randf_range(Globals.MARGINS[1], size.y - Globals.MARGINS[3])
			)
			end_node = get_closest_node(target_position)
	
	var passenger = PASSENGER.instantiate()
	add_child(passenger)
	passenger.initialize(self, spawn_position, target_position, start_node, end_node)

func get_closest_node(target_position: Vector2) -> Node2D:
	var closest = nodes[0]
	for node in nodes:
		if closest.global_position.distance_to(target_position) > node.global_position.distance_to(target_position):
			closest = node
	return closest

func get_road_path(start, end, blocked_nodes: Array = []) -> Array:
	if start == end:
		return []
	
	var queue = [start]
	var visited = {}
	var parent = {}
	visited[start] = true
	parent[start] = null
	
	for node in blocked_nodes:
		visited[node] = true
	
	while queue.size() > 0:
		var current = queue.pop_front()
		if current == end:
			return _reconstruct_path(parent, end)
		
		for road in current.roads:
			var neighbour = road.end
			if not visited.has(neighbour):
				visited[neighbour] = true
				parent[neighbour] = current
				queue.append(neighbour)
	
	return []

func _reconstruct_path(parent: Dictionary, end) -> Array:
	if not parent.has(end):
		return []
	
	var path = []
	var current = end
	while current != null:
		path.append(current)
		current = parent[current]
	path.reverse()
	return path

func find_direct_transit_plan(start_node, end_node) -> Dictionary:
	var best_plan := {}
	var best_score = INF
	
	for line in lines:
		for entry_stop in line.stops:
			for exit_stop in line.stops:
				if entry_stop == exit_stop:
					continue
				
				var direction = line.get_direction_between_stops(entry_stop, exit_stop)
				if direction == -1:
					continue
				
				var walk_to_entry = get_road_path(start_node, entry_stop)
				var walk_from_exit = get_road_path(exit_stop, end_node)
				if start_node != entry_stop and walk_to_entry.is_empty():
					continue
				if exit_stop != end_node and walk_from_exit.is_empty():
					continue
				
				var ride_path = line.get_path_between_stops(entry_stop, exit_stop, direction)
				# Estimate times (in simulation minutes): walking time, riding time and stop penalties
				var walk_to_entry_time = 0.0
				if walk_to_entry.size() > 0:
					walk_to_entry_time = get_path_distance(walk_to_entry) / ASSUMED_WALK_SPEED

				var walk_from_exit_time = 0.0
				if walk_from_exit.size() > 0:
					walk_from_exit_time = get_path_distance(walk_from_exit) / ASSUMED_WALK_SPEED

				var ride_distance = get_path_distance(ride_path)
				var ride_time = 0.0
				if ride_distance > 0:
					ride_time = ride_distance / line.default_speed

				# Count stops along ride_path to add stop duration penalties
				var stops_count = 0
				for node in ride_path:
					if node in line.stops:
						stops_count += 1
				var stop_penalty = stops_count * line.STOP_DURATION

				# Compute passenger arrival tick at entry stop (after walking)
				var walk_to_entry_minutes = int(ceil(walk_to_entry_time))
				var passenger_arrival_tick = (Globals.TICK + walk_to_entry_minutes) % 1440

				# Compute wait time until next vehicle arrives at entry stop after passenger arrival
				var wait_time = line.get_next_arrival_wait(entry_stop, direction, passenger_arrival_tick)
				if wait_time == INF:
					continue

				var score = walk_to_entry_time + wait_time + ride_time + stop_penalty + walk_from_exit_time
				if score < best_score:
					best_score = score
					best_plan = {
						"line": line,
						"direction": direction,
						"entry_stop": entry_stop,
						"exit_stop": exit_stop,
						"walk_to_entry": walk_to_entry,
						"walk_from_exit": walk_from_exit,
						"ride_path": ride_path,
					}
	
	return best_plan

func get_path_distance(path: Array) -> float:
	var distance := 0.0
	for i in range(1, path.size()):
		distance += path[i - 1].global_position.distance_to(path[i].global_position)
	return distance

func connect_voronoi_neighbours() -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for node in nodes:
		points.append(node.position)
	
	var triangles := Geometry2D.triangulate_delaunay(points)
	var edges := {}
	
	for i in range(0, triangles.size(), 3):
		_add_edge(edges, triangles[i], triangles[i + 1])
		_add_edge(edges, triangles[i + 1], triangles[i + 2])
		_add_edge(edges, triangles[i + 2], triangles[i])
	
	for edge_key in edges.keys():
		add_connection(nodes[edge_key.x], nodes[edge_key.y])

func add_connection(start, end) -> void:
	var road = ROAD.instantiate() as Node2D
	road.start = start
	road.end = end
	add_child(road)
	roads[[start, end]] = road
	
	road = ROAD.instantiate() as Node2D
	road.start = end
	road.end = start
	add_child(road)
	roads[[end, start]] = road

func _add_edge(edges: Dictionary, a: int, b: int) -> void:
	var key = Vector2i(min(a, b), max(a, b))
	edges[key] = true

func _generate_virtual_edges() -> void:
	# For each line, create edges between consecutive stops in both directions
	for line in lines:
		var line_number = line.NUMBER
		var line_ref = line
		
		# Forward direction
		var stops_forward = line.stops
		for i in range(stops_forward.size() - 1):
			var stop_a = stops_forward[i]
			var stop_b = stops_forward[i + 1]
			_add_virtual_edge(stop_a, stop_b, line_number, line_ref, line.DIRECTIONS.FORWARD)
		
		# Backward direction
		var stops_backward = stops_forward.duplicate()
		stops_backward.reverse()
		for i in range(stops_backward.size() - 1):
			var stop_a = stops_backward[i]
			var stop_b = stops_backward[i + 1]
			_add_virtual_edge(stop_a, stop_b, line_number, line_ref, line.DIRECTIONS.BACKWARD)

func _add_virtual_edge(start: Node2D, end: Node2D, line_number: int, line_ref: Node2D, direction: int) -> void:
	var distance = start.global_position.distance_to(end.global_position)
	var vehicle_speed = ASSUMED_VEHICLE_SPEED
	
	# Check if line is a tram (higher speed)
	if line_ref.TRAM_LINE:
		vehicle_speed = ASSUMED_VEHICLE_SPEED * 2
	
	# Travel time = distance / speed (no stop duration here, that's per-stop)
	var travel_time = distance / vehicle_speed
	
	var line_info = {
		"line_number": line_number,
		"line_ref": line_ref,
		"direction": direction
	}
	
	var edge = Edge.new(start, end, distance, travel_time, line_info)
	start.virtual_edges.append(edge)

func tick(delta) -> void:
	print("Current tick: ", "%4d " % Globals.TICK, delta)
	for line in lines:
		line.tick(delta)

func _process(delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	
	var viewport_size = get_viewport().get_visible_rect().size
	
	var inside_margins = (
		mouse_pos.x >= Globals.MARGINS[0]
		and mouse_pos.y >= Globals.MARGINS[1]
		and mouse_pos.x <= viewport_size.x - Globals.MARGINS[2]
		and mouse_pos.y <= viewport_size.y - Globals.MARGINS[3]
	)
	
	if Input.is_action_just_pressed("click"):
		if inside_margins:
			print("Clicked: ", mouse_pos)
			if prev_click == null:
				prev_click = mouse_pos
			else:
				print("Spawning passenger")
				spawn_passenger(prev_click, mouse_pos)
				prev_click = null
