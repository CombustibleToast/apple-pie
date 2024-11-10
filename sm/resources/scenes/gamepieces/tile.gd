class_name Tile
extends Node3D

## TODO none of this is correct

var xy : Vector2i 
var defaultColor : Color = Color.BLACK

func recolor(color : Color):
	$MeshInstance3D.get_surface_override_material(0).albedo_color = color

func raise():
	$AnimationPlayer.stop()
	$AnimationPlayer.queue("raise")
	$AnimationPlayer.queue("hover_up")

func lower():
	$AnimationPlayer.stop()
	$AnimationPlayer.queue("lower")
	$AnimationPlayer.queue("RESET")

func test():
	$AnimationPlayer.stop()
	$AnimationPlayer.queue("raise")
	$AnimationPlayer.queue("lower")
	$AnimationPlayer.queue("RESET")
#func _ready():
#	print("")
	# unpainted.emit()

func paint(color : Color):
	# print("new color " + str(color))
	recolor(color)

func unpaint():
	# print("uncolor")
	recolor(defaultColor)
