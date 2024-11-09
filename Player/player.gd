extends CharacterBody3D

# Movement
enum Facing {LEFT, RIGHT, UP, DOWN}
@onready var current_facing_direction:Facing = Facing.DOWN
const SPEED = 5.0

@onready var collected_items:Array = []

func _process(delta: float) -> void:
	update_animation()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Get the input direction and handle the movement/deceleration.
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

func update_animation():
	# Update sprite animation based on velocity

	# Update facing direction
	# Left/right takes prio over up/down
	# The order of the if statements imply this priority
	var current_velocity = Vector2(velocity.x, velocity.z).rotated(PI/4) # unrotate the velocity from iso rotation
	if(current_velocity.y < 0):
		current_facing_direction = Facing.UP
	if(current_velocity.y > 0):
		current_facing_direction = Facing.DOWN
	if(current_velocity.x < 0):
		current_facing_direction = Facing.LEFT
	if(current_velocity.x > 0):
		current_facing_direction = Facing.RIGHT
	
	# Update animation player
	# If the player is moving, use walk animation. Otherwise use idle animation
	var animation_name:String = ""
	if abs(current_velocity.length_squared()) > 0:
		animation_name = "walk "
	else:
		animation_name = "idle "

	# Add facing direction to animation name
	match(current_facing_direction):
		Facing.UP: animation_name += "up"
		Facing.DOWN: animation_name += "down"
		Facing.LEFT: animation_name += "left"
		Facing.RIGHT: animation_name += "right"

	$AnimatedSprite3D.play(animation_name)
	# print("playing %s" % animation_name)
