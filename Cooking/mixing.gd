extends Node2D

#Nodes
@onready var bowl = $bowl
@onready var mixing_timer = $mixing_timer
@onready var instructions_label = $Control/HBoxContainer/Control2/instructions_label
@onready var game_timer = $game_timer
@onready var game_timer_label = $Control/HBoxContainer/Control/timer_label

# Constants
const REQUIRED_DURATION = 2  # Time in seconds to maintain circular motion
const MIN_RADIUS = 50  # Minimum radius for circular motion
const MAX_RADIUS = 250  # Maximum radius for circular motion
const MIN_SPEED = 1  # Minimum angular speed (radians per frame)
const MAX_SPEED = 10  # Maximum angular speed (radians per frame)

# Variables
var mixing_center = Vector2.ZERO
var last_position = Vector2.ZERO
var current_angle = 0.0
var time_in_optimal_range = 0.0
var game_over = false
var score: int = 0

signal minigame_complete(score)

# Called when the node enters the scene tree for the first time.
func _ready():
	mixing_center = bowl.global_position 

func start_game(): # Called from the main game script
	mixing_timer.start()
	game_timer.wait_time = 30 #Normal: 20 Debug: 5
	game_timer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if game_over:
		return

	#update gtimer label
	game_timer_label.text = "Timer: " + str(int(game_timer.time_left))
	
	var mouse_pos = get_global_mouse_position()
	var relative_pos = mouse_pos - mixing_center

	# Calculate radius from center
	var radius = relative_pos.length()

	# Calculate angle
	var angle = relative_pos.angle()
	var angular_speed = abs(angle - current_angle) / delta
	
	# Update for next frame
	current_angle = angle
	
	check_mixing(radius, angular_speed, delta)

# Check if mixing is within range
func check_mixing(radius, angular_speed, delta):
	if MIN_RADIUS <= radius and radius <= MAX_RADIUS and MIN_SPEED <= angular_speed and angular_speed <= MAX_SPEED:
		time_in_optimal_range += delta  # Increment time spent in the optimal range
		instructions_label.text = "Good! Keep stirring!"
	
	if radius < MIN_RADIUS or radius > MAX_RADIUS:
		instructions_label.text = "Maintain a steady circular motion!"
	
	if angular_speed < MIN_SPEED:
		instructions_label.text = "Too slow! Speed up!"
	elif angular_speed > MAX_SPEED:
		instructions_label.text = "Too fast! Slow down!"

	# Check if enough time has been spent in the optimal range
	if time_in_optimal_range >= REQUIRED_DURATION:
		end_minigame(true)

func _on_game_timer_timeout():
	end_minigame(false)

func end_minigame(success):
	game_over = true
	mixing_timer.stop()
	game_timer.stop()

	if success:
		instructions_label.text = "Mixing complete!"
		print("Mixing Minigame: Success + 1")
		score = 1
	else:
		instructions_label.text = "What a mess!"
		print("Mixing Minigame: Failure + 0")
		score = 0
	# Emit signal to notify main script
	emit_signal("minigame_complete", score)



func _on_button_pressed():
	start_game()
