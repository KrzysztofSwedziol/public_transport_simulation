extends Node2D

const WALK_SPEED = 5

enum STATES {
	WALKING_TO_ENTRY_STOP,
	WAITING_FOR_VEHICLE,
	RIDING,
	WALKING_TO_TARGET,
	ARRIVED
}

var COLOR = Color.WHITE
var city_map = null
var spawn_position: Vector2
var target_position: Vector2
var start_node = null
var end_node = null

var state = STATES.WALKING_TO_TARGET
var plan := {}
var walk_path := []
var walk_path_position := 0
var next_position: Vector2
var current_vehicle = null
var entry_stop = null
var exit_stop = null
var selected_line = null
var selected_direction = -1

func initialize(map_ref, spawn: Vector2, target: Vector2, start, end) -> void:
	city_map = map_ref
	spawn_position = spawn
	target_position = target
	start_node = start
	end_node = end
	global_position = spawn_position
	_create_plan()

func _ready() -> void:
	z_index = 3

func _process(delta: float) -> void:
	match state:
		STATES.WALKING_TO_ENTRY_STOP:
			_walk(delta)
		STATES.WAITING_FOR_VEHICLE:
			_try_board_vehicle()
		STATES.RIDING:
			_try_exit_vehicle()
		STATES.WALKING_TO_TARGET:
			_walk(delta)
		STATES.ARRIVED:
			queue_free()
	
	#print("Passenger state: ", STATES.find_key(state))
	
	queue_redraw()

func _create_plan() -> void:
	# Use A* to find shortest path based on travel time
	var astar = AStar2D.new()
	
	# Add all nodes to A* graph
	var node_to_id = {}
	var id_to_node = {}
	var id_counter = 0
	
	for node in city_map.nodes:
		node_to_id[node] = id_counter
		id_to_node[id_counter] = node
		astar.add_point(id_counter, node.global_position)
		id_counter += 1
	
	# Add virtual edges between stops
	for node in city_map.nodes:
		var from_id = node_to_id[node]
		for edge in node.virtual_edges:
			var to_id = node_to_id[edge.end_node]
			# Connect points (A* will use Euclidean distance as cost)
			astar.connect_points(from_id, to_id, false)
	
	# Find path from start to end
	var start_id = node_to_id[start_node]
	var end_id = node_to_id[end_node]
	
	var path_ids = astar.get_id_path(start_id, end_id)
	
	if path_ids.is_empty():
		# No transit path found, walk directly
		walk_path = city_map.get_road_path(start_node, end_node)
		_start_walking(spawn_position, target_position, walk_path, STATES.WALKING_TO_TARGET)
		return
	
	# Convert ID path to node path
	var path_nodes = []
	for id in path_ids:
		path_nodes.append(id_to_node[id])
	
	# Build plan from path: sequence of walks and rides
	plan = {
		"path_nodes": path_nodes,
		"current_step": 0
	}
	
	# Start walking to first stop
	var first_stop = path_nodes[0]
	_start_walking(spawn_position, first_stop.global_position, city_map.get_road_path(start_node, first_stop), STATES.WALKING_TO_ENTRY_STOP)
	
	entry_stop = first_stop
	if path_nodes.size() > 1:
		exit_stop = path_nodes[1]  # Second node is exit for first ride

func _start_walking(from_position: Vector2, final_position: Vector2, node_path: Array, next_state: int) -> void:
	walk_path = []
	walk_path.append(from_position)
	
	for node in node_path:
		walk_path.append(node.global_position)
	
	if walk_path.size() == 1 or walk_path[walk_path.size() - 1] != final_position:
		walk_path.append(final_position)
	
	walk_path_position = 1
	state = next_state
	
	if walk_path_position >= walk_path.size():
		_on_walk_finished()
		return
	
	next_position = walk_path[walk_path_position]

func _walk(delta: float) -> void:
	var step = WALK_SPEED * delta * Globals.TICKSPEED
	global_position = global_position.move_toward(next_position, step)
	
	if global_position != next_position:
		return
	
	walk_path_position += 1
	if walk_path_position >= walk_path.size():
		_on_walk_finished()
		return
	
	next_position = walk_path[walk_path_position]

func _on_walk_finished() -> void:
	if state == STATES.WALKING_TO_ENTRY_STOP:
		state = STATES.WAITING_FOR_VEHICLE
		return
	
	if state == STATES.WALKING_TO_TARGET:
		state = STATES.ARRIVED

func _try_board_vehicle() -> void:
	# Find the edge from entry_stop to exit_stop
	var edge = null
	for e in entry_stop.virtual_edges:
		if e.end_node == exit_stop:
			edge = e
			break
	
	if edge == null:
		# No transit edge found
		state = STATES.WALKING_TO_TARGET
		return
	
	selected_line = edge.line_info["line_ref"]
	selected_direction = edge.line_info["direction"]
	
	# Look for a vehicle on this line going in the right direction, stopped at entry_stop
	for vehicle in selected_line.vehicles:
		if not is_instance_valid(vehicle):
			continue
		
		var can_take = false
		
		# Check if vehicle is correct line and direction
		if vehicle.line != selected_line or vehicle.direction != selected_direction:
			continue
		
		# Check if vehicle is stopped at entry or very close
		if selected_line.vehicle_can_take_passenger(vehicle, entry_stop, exit_stop):
			can_take = true
		else:
			var dist_tol := 8.0
			if vehicle.has_free_seat() and vehicle.global_position.distance_to(entry_stop.global_position) <= dist_tol:
				can_take = true
		
		if not can_take:
			continue
		
		if vehicle.board(self):
			# Increase z_index while riding to appear above vehicle
			z_index = 4
			state = STATES.RIDING
			return

func _try_exit_vehicle() -> void:
	if current_vehicle == null or not is_instance_valid(current_vehicle):
		_start_walking(global_position, target_position, city_map.get_road_path(exit_stop, end_node), STATES.WALKING_TO_TARGET)
		return
	
	if current_vehicle.is_stopped_at(exit_stop):
		current_vehicle.unboard(self)
		# Restore z_index after exiting
		z_index = 3
		
		# Check if we need to continue to end_node or transfer
		if plan.get("path_nodes", []).size() > plan.get("current_step", 0) + 2:
			# Continue with next segment
			plan["current_step"] = plan.get("current_step", 0) + 1
			var next_stop = plan["path_nodes"][plan["current_step"] + 1]
			entry_stop = exit_stop
			exit_stop = next_stop
			state = STATES.WAITING_FOR_VEHICLE
		else:
			# Final walk to target
			_start_walking(global_position, target_position, city_map.get_road_path(exit_stop, end_node), STATES.WALKING_TO_TARGET)
