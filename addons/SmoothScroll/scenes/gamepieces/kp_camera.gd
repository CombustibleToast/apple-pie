extends Camera3D

const FOLLOW_SPEED = 4.0
const FALLBACK_PHEIGHT = 11
var default_pheight = max(FALLBACK_PHEIGHT, 1.0)
const ORTHO_LENIENCE = 7.0
const PLYR_PERSPECTIVE_DISPLACEMENT : Vector3 = Vector3(1.0,1.0,0.0)
var pheight = default_pheight
var target_rotation : Quaternion
var target_position : Vector3
var center_position : Vector3

## TODO fuck with this some more :)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position = position.lerp(target_position, delta * FOLLOW_SPEED) # Track


func _on_board_board_done(center : Vector3):
	size = (center.x * 3)  + ORTHO_LENIENCE # Set ortho size for centered cam
	center_position = Vector3(0, pheight,0)
	target_position = center_position
