class_name D6
extends MeshInstance3D


var mat : BaseMaterial3D 

var id
var value

## Rot for the individual sides (in degrees): assuming Z- is screen-down. 
## Based on the rot of the d6 node itself (not the model)
var sideRot: Vector3 = ( 
	Vector3(90,0,0) if value == 2
	else Vector3(0,90,90) if value == 3 
	else Vector3(0,270,270) if value == 4
	else Vector3(270,0,0) if value == 5
	else Vector3(180,0,0) if value == 6
	else Vector3.ZERO 
)

func _ready():
	make_unique()

func make_unique():
	get("material_override").albedo_color = Color.AQUA
