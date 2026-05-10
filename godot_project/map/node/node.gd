extends Node2D

var COLOR = Color.BLACK

var roads = []
var stops = []
@onready var node_visualization: Sprite2D = $NodeVisualization

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.z_index = 1
	queue_redraw()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func redraw() :
	queue_redraw()
	
func _draw() :
	node_visualization.redraw()

func add_road(road) :
	var other = road.end
	if road.start != self : return
	if other == self : return
	if roads.has(road) : return
	roads.append(road)
