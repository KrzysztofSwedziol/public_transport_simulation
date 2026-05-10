extends Node2D

const VEHICLE = preload("res://map/line/vehicle.tscn")


const STOP_PROBABILITY = 0.49
const STOP_DURATION = 2
const NIGHT_LINE_PROBABILITY = 0.2
# x / y means, that on average, x buses leave every y minutes
const LEAVE_FREQUENCY = 1.0 / 45
const TRAM_PROBABILITY = 0.2
enum DIRECTIONS {
	FORWARD,
	BACKWARD
}

var start
var end
var COLOR = Color.BLUE
var TRAM_LINE = false
var NUMBER = 0

var path = []
var stops = []
var vehicles = []

var schedule = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var RNG = RandomNumberGenerator.new()
	RNG.randomize()
	if RNG.randf() < TRAM_PROBABILITY :
		self.TRAM_LINE = true
	create_schedule()
	
	pass # Replace with function body.


func tick(delta: float) -> void:
	#for vehicle in self.vehicles :
		#vehicle.tick()
	var directions = self.schedule.get(Globals.TICK, [])
	if directions.size() == 0 : return
	#print("Found directions on tick %4d " % Globals.TICK, directions)
	spawn_agent(directions)
	
func spawn_agent(directions) :
	var capacity = 10
	var speed = 50
	if self.TRAM_LINE :
		capacity *= 3
		speed *= 2
	for direction in directions :
		var vehicle = VEHICLE.instantiate()
		vehicle.COLOR = self.COLOR
		vehicle.speed = speed
		vehicle.capacity = capacity
		vehicle.stops = self.stops
		vehicle.stop_duration = STOP_DURATION
		if direction == DIRECTIONS.FORWARD :
			#print("TICK %4d" % Globals.TICK, ": Spawning agent on start")
			vehicle.path = self.path.duplicate()
			vehicle.global_position = self.start.global_position
		elif direction == DIRECTIONS.BACKWARD :
			#print("TICK %4d" % Globals.TICK, ": Spawning agent on end")
			self.path.reverse()
			vehicle.path = self.path.duplicate()
			self.path.reverse()
			vehicle.global_position = self.end.global_position
		else :
			#print("TICK %4d" % Globals.TICK, ": Invalid spawn direction")
			continue
		self.add_child(vehicle)
		self.vehicles.append(vehicle)

func create_schedule(frequency = LEAVE_FREQUENCY) :
	var RNG = RandomNumberGenerator.new()
	RNG.randomize()
	
	var start_hour = 0
	var end_hour = 1440
	
	if RNG.randf() < NIGHT_LINE_PROBABILITY :
		# line is coursing from 00:00 to 07:59
		end_hour = 480
		# no trams at night
		self.TRAM_LINE = false
	else :
		# line is coursing from 07:00 to 23:59
		start_hour = 420
	
	# first bus is leaving exactly at start hour, from both start and end
	self.schedule[start_hour] = [DIRECTIONS.FORWARD]
	self.schedule[start_hour].append(DIRECTIONS.BACKWARD)
	
	var last_start = start_hour
	
	# randomly create bus schedule
	for i in range(start_hour + 1, end_hour) :
		if RNG.randf() >= frequency :
			continue
		last_start = i
		# with difference of +- 5 minutes, make sure another bus is leaving from end to start
		var second_time = max(min(i + RNG.randi_range(-5, 5), end_hour - 1), start_hour + 1)
		
		var forward_table = schedule.get(i, [])
		if DIRECTIONS.FORWARD not in forward_table :
			forward_table.append(DIRECTIONS.FORWARD)
			schedule[i] = forward_table
		var backward_table = schedule.get(second_time, [])
		if DIRECTIONS.BACKWARD not in backward_table :
			backward_table.append(DIRECTIONS.BACKWARD)
			schedule[second_time] = backward_table

func bfs(start, end, no_go_zone = []) :
	var queue = [start]
	var visited = {}
	var parent = {}
	
	visited[start] = true
	parent[start] = null
	
	for node in no_go_zone :
		visited[node] = true
		
	var current = null
	
	while queue.size() > 0 :
		current = queue.pop_front()
		if current == end : break
		
		for road in current.roads :
			var neighbour = road.end
			if not visited.has(neighbour) :
				visited[neighbour] = true
				parent[neighbour] = current
				queue.append(neighbour)
				
	return parent

func initialize(start, through, end) :
	self.NUMBER = Globals.get_line_number()
	self.COLOR = Globals.get_line_color(self.NUMBER)
	self.start = start
	self.end = end
	
	self.path = []
	var parent = bfs(start, through)
	
	var current = through
	while current != null :
		self.path.append(current)
		current = parent[current]
	
	self.path.reverse()
	
	parent = bfs(through, end, self.path)
	
	var temp_path = []
	current = end
	while current != null :
		temp_path.append(current)
		current = parent[current]
	temp_path.reverse()
	
	self.path = self.path + temp_path
	
	var RNG = RandomNumberGenerator.new()
	RNG.randomize()
	
	
	var prev = self.path[0]
	
	self.stops.append(prev)
	prev.stops.append(self)
	
	for i in range(1, self.path.size()) :
		
		current = self.path[i]
		
		if RNG.randf() < STOP_PROBABILITY or current == start or current == end or current == through :
			self.stops.append(current)
			current.stops.append(self)
		
		for road in prev.roads :
			if road.end == current :
				road.lines.append(self)
				road.queue_redraw()
		for road in current.roads :
			if road.end == prev :
				road.lines.append(self)
				road.queue_redraw()
				
		prev = current
				
	
	self.stops.reverse()
