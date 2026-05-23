extends Control
@onready var color_rect: ColorRect = $MenuBackground
@onready var tick_speed: HSlider = $MenuBackground/Menu/TickSpeedContainer/Slider
@onready var tick_speed_value_label: Label = $MenuBackground/Menu/TickSpeedContainer/ValueLabel
@onready var player_spawn_rate: HSlider = $MenuBackground/Menu/PassengerSpawnRateContainer/Slider


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	color_rect.position.x = 1920 - Globals.MARGINS[2]
	color_rect.size.x = Globals.MARGINS[2]
	_on_tick_speed_value_changed(tick_speed.value)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	tick_speed_value_label.text = str(Globals.TICKSPEED)
	pass


func _on_tick_speed_value_changed(value: float) -> void:
	Globals.TICKSPEED = ((Globals.MAX_TICKSPEED - Globals.MIN_TICKSPEED) / tick_speed.max_value) * value + Globals.MIN_TICKSPEED
	pass # Replace with function body.
