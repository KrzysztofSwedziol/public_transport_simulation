extends Sprite2D
@onready var node: Node2D = $".."

var SIZE := 1


func _ready() -> void:
	redraw()


func redraw() -> void:
	gen_circle()


func get_circle_size() -> int:
	return 10


func gen_circle() -> void:
	var circle_size := get_circle_size()

	var image := Image.create(circle_size, circle_size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	var center := Vector2(circle_size / 2.0, circle_size / 2.0)
	var radius := circle_size / 2.0 - 2.0

	for x in range(circle_size):
		for y in range(circle_size):
			if center.distance_to(Vector2(x, y)) <= radius:
				image.set_pixel(x, y, node.COLOR)

	texture = ImageTexture.create_from_image(image)
