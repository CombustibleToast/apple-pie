extends Area3D

@onready var player_in_interact_range: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Check for interaction
	if player_in_interact_range and Input.is_action_just_pressed("interact"):
		trigger_interaction()

func trigger_interaction():
	print("Player interacted with %s!" % name)

func _on_area_entered(area:Area3D) -> void:
	print("%s detected entry from %s" % [name, area.name])
	player_in_interact_range = true
	pass # Replace with function body.


func _on_area_exited(area:Area3D) -> void:
	print("%s detected exit from %s" % [name, area.name])
	player_in_interact_range = false
	pass # Replace with function body.
