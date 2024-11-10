extends CharacterBody3D

# Movement
enum Facing {LEFT, RIGHT, UP, DOWN}
@onready var current_facing_direction:Facing = Facing.DOWN
@onready var special_animation = false
const SPEED = 5.0
const WAIT_TIME = 0.4
var time_since_played : float

# Links
@export var storyteller: Control

# Item pickups
@onready var collected_items:Array = []
@export var item_pickup_animation_time:float = 2


func _process(delta: float) -> void:
	time_since_played -= delta
	update_animation()

func _physics_process(delta: float) -> void:
	update_movement(delta)

func update_movement(fixed_delta: float):
	# Disallow player movement while sm is open
	if storyteller.maximized:
		return
	# Disallow player movement during special animation
	if special_animation:
		return

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * fixed_delta

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
	add_item_to_collection(area)

func update_animation():
	# Don't do anything if there's a special animation going on
	if special_animation:
		return
	
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
		if time_since_played < 0: 
			$AudioStreamPlayer3D.play()
			time_since_played = WAIT_TIME
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

func add_item_to_collection(item:Area3D):
	collected_items.append(item.collectable_name)

	# Log
	print("Player collected %s" % item.collectable_name)

	# Play animation
	special_animation = true
	$AnimatedSprite3D.play("got item")
	item.position = position + Vector3(0,2,0)
	item.disable_pointer()
	$"Got item sound".play()

	# Wait for animation
	await get_tree().create_timer(item_pickup_animation_time).timeout
	special_animation = false
	current_facing_direction = Facing.DOWN

	# Destroy the item from the world
	item.queue_free()
