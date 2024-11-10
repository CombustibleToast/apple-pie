extends Control

var jecz_time = 3.0
var fadeout_time = 1
@onready var elapsed_time = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if elapsed_time < jecz_time:
		elapsed_time += delta
	else:
		$Button.show()
		$Sprite2D.show()
		$jecz.hide()
		$gup.hide()

func _on_button_button_up() -> void:
	get_tree().change_scene_to_file("res://World/Game World.tscn")
