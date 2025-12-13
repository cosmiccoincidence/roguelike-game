extends Camera3D

@export var zoom_min := 6.0
@export var zoom_max := 30.0
@export var zoom_speed := 3.0
@export var zoom_smooth := 8.0

var zoom_target := 12.0
var zoom_height := 12.0  # what the follow code will use

func _ready():
	zoom_target = global_position.y
	zoom_height = zoom_target

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_target -= zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_target += zoom_speed

		zoom_target = clamp(zoom_target, zoom_min, zoom_max)

func _process(delta):
	zoom_height = lerp(zoom_height, zoom_target, 1.0 - exp(-zoom_smooth * delta))
