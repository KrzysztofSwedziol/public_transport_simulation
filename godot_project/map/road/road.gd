extends Node2D

var start
var end

var color_width = 2
var lines = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.z_index = 0
	start.add_road(self)
	queue_redraw()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _draw() :
	
	var start_position = to_local(start.global_position)
	var end_position = to_local(end.global_position)
	

	
	var count = self.lines.size()
	
	if count > 0 :
		var width = color_width * count
		var direction = end_position - start_position
		if not direction.is_zero_approx() :
			pass
			var normal = direction.normalized().orthogonal()
			var start_offset = -width * 0.5 + color_width * 0.5
			
			var offset_vector = Vector2.ZERO
			
			for i in range(count) :
				offset_vector = normal * (start_offset + i * color_width)
				
				draw_line(
					start_position + offset_vector,
					end_position + offset_vector,
					lines[i].COLOR,
					color_width
				)
	else :
		draw_line(
			start_position,
			end_position,
			Color.BLACK,
			color_width
		)
	
	start.redraw()
	end.redraw()
	
