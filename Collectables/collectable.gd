extends Area3D

@export var collectable_name: String
@export var collectable_sprite: Texture2D
var spin_rate: float = 2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if collectable_sprite:
		$Sprite3D.texture = collectable_sprite
	else:
		$Sprite3D.texture = load("res://Collectables/Sprites/placeholder_collectable_icon.svg") #default image if missing
		print("%s is missing a sprite!" % name)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	# Spin pointer
	$MeshInstance3D.rotate(Vector3(0,1,0), spin_rate * delta)

func disable_pointer():
	$MeshInstance3D.hide()