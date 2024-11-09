extends CharacterBody3D

const SPEED = 5.0

var collected_items:Array

func _ready() -> void:
	collected_items = []

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input := Input.get_vector("left", "right", "forward", "backward").rotated(-PI/4) # the rotation is to account for the isometric 45deg viewing angle
	var direction := Vector3(input.x, 0, input.y).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

# Important: Collectables collision layer and mask is 14 (i picked it arbitrarily lol)
func pickup_area_entered(area:Area3D) -> void:
	# Add the item name to the collected items array
	collected_items.append(area.collectable_name)

	# Log
	print("Player collected %s" % area.collectable_name)

	# Destroy the item from the world
	area.queue_free()
