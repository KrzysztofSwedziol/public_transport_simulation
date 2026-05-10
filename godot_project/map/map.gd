extends Node2D

@onready var main: Node2D = $".."

const NODE = preload("res://map/node/node.tscn")
const ROAD = preload("res://map/road/road.tscn")
const AREA = preload("res://map/area/area.tscn")
const LINE = preload("res://map/line/line.tscn")
const PASSENGER = preload("res://agents/passenger/passenger.tscn")

var nodes: Array[Node2D] = []
var roads: = {}
var lines: Array[Node2D] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	populate_with_nodes()
	
	connect_voronoi_neighbours()
	
	generate_lines()
	
	pass # Replace with function body.

func generate_lines() :
	var RNG = RandomNumberGenerator.new()
	RNG.randomize()
	
	for i in range(main.NUM_LINES) :
		
		var start = RNG.randi_range(0, self.nodes.size() - 1)
		var through = RNG.randi_range(0, self.nodes.size() - 1)
		var end = RNG.randi_range(0, self.nodes.size() - 1)
		
		while through == start :
			through = RNG.randi_range(0, self.nodes.size() - 1)
		while end == through :
			end = RNG.randi_range(0, self.nodes.size() - 1)
		
		var line = LINE.instantiate()
		line.initialize(nodes[start], nodes[through], nodes[end])
		self.add_child(line)
		self.lines.append(line)

func populate_with_nodes() :
	var size = get_viewport().get_visible_rect().size
	var RNG = RandomNumberGenerator.new()
	RNG.randomize()
	
	for i in range(main.MAX_NODES) :
		var current_node = NODE.instantiate() as Node2D
		self.add_child(current_node)
		
		current_node.position = Vector2(
			RNG.randf_range(main.MARGINS[0], size.x - main.MARGINS[2]),
			RNG.randf_range(main.MARGINS[1], size.y - main.MARGINS[3])
		)
		
		self.nodes.append(current_node)

func spawn_passenger(spawn_position = null, target_position = null) :
	var size = get_viewport().get_visible_rect().size
	var RNG = RandomNumberGenerator.new()
	RNG.randomize()
	
	var randomize_positions = spawn_position == null or target_position == null
	
	if randomize_positions :
		spawn_position = Vector2(
			RNG.randf_range(main.MARGINS[0], size.x - main.MARGINS[2]),
			RNG.randf_range(main.MARGINS[1], size.y - main.MARGINS[3])
		)
		
	var start_node = self.nodes[0]
	for node in self.nodes :
		if start_node.global_position.distance_to(spawn_position) > node.global_position.distance_to(spawn_position) :
			start_node = node
	
	if randomize_positions :
		target_position = Vector2(
			RNG.randf_range(main.MARGINS[0], size.x - main.MARGINS[2]),
			RNG.randf_range(main.MARGINS[1], size.y - main.MARGINS[3])
		)
	var end_node = self.nodes[0]
	for node in self.nodes :
		if end_node.global_position.distance_to(target_position) > node.global_position.distance_to(target_position) :
			end_node = node
	
	if randomize_positions :
		while start_node == end_node :
			target_position = Vector2(
				RNG.randf_range(main.MARGINS[0], size.x - main.MARGINS[2]),
				RNG.randf_range(main.MARGINS[1], size.y - main.MARGINS[3])
			)
			for node in self.nodes :
				if end_node.global_position.distance_to(target_position) > node.global_position.distance_to(target_position) :
					end_node = node
	
	var passenger = PASSENGER.instantiate()
	
	passenger.set_nodes(spawn_position, target_position, start_node, end_node)
	
	self.add_child(passenger)

func connect_voronoi_neighbours() :
	var points: PackedVector2Array = PackedVector2Array()
	
	for node in nodes :
		points.append(node.position)
	
	var triangles := Geometry2D.triangulate_delaunay(points)
	
	var edges := {}
	
	for i in range(0, triangles.size(), 3) :
		var a = triangles[i]
		var b = triangles[i + 1]
		var c = triangles[i + 2]
		
		_add_edge(edges, a, b)
		_add_edge(edges, b, c)
		_add_edge(edges, c, a)
		
	for edge_key in edges.keys() :
		var a = edge_key.x
		var b = edge_key.y
		
		add_connection(nodes[a], nodes[b])

func add_connection(start, end) :
	
	var road = ROAD.instantiate() as Node2D
	road.start = start
	road.end = end
	self.add_child(road)
	roads[[start, end]] = road
	
	road = ROAD.instantiate() as Node2D
	road.start = end
	road.end = start
	self.add_child(road)
	roads[[end, start]] = road
		
func _add_edge(edges, a, b) :
	var key = Vector2i(min(a, b), max(a, b))
	edges[key] = true
	pass


func tick(delta) :
	#print("Time passed from last tick: ", delta)
	print("Current tick: ", "%4d " % Globals.TICK, delta)
	for line in self.lines :
		line.tick(delta)
	pass

var prev_click = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()

	if Input.is_action_just_pressed("click"):
		print("Clicked: ", mouse_pos)
		if prev_click == null :
			prev_click = mouse_pos
		else :
			print("Spawning passenger")
			spawn_passenger(prev_click, mouse_pos)
			prev_click = null
	pass
