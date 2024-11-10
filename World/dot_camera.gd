extends Camera3D

@export var player: CharacterBody3D
@export var storyteller: Control

@onready var default_translation: Vector3 = position
@export var delta_paused_translation: Vector3
@export var delta_transition_rate: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	update_position()

func update_position():
	var net_translation: Vector3 = default_translation + delta_paused_translation
	if storyteller.maximized:
		position.x = move_toward(default_translation.x, net_translation.x, delta_transition_rate)
		position.y = move_toward(default_translation.y, net_translation.y, delta_transition_rate)
		position.z = move_toward(default_translation.z, net_translation.z, delta_transition_rate)
	else:
		position.x = move_toward(net_translation.x, default_translation.x, delta_transition_rate)
		position.y = move_toward(net_translation.y, default_translation.y, delta_transition_rate)
		position.z = move_toward(net_translation.z, default_translation.z, delta_transition_rate)