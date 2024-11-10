extends Node2D

# nodes
@onready var baking_meter = $Control/HBoxContainer/Control4/baking_meter
@onready var baking_timer = $baking_timer
@onready var instructions_label = $Control/HBoxContainer/Control2/instructions_label
@onready var stop_button = $Control/HBoxContainer/Control3/stop_button


# Constants
const MAX_BAKING_LEVEL = 100
const OPTIMAL_MIN = 60  # Minimum value for optimal baking range
const OPTIMAL_MAX = 80 # Maximum value for optimal baking range
const BAKING_SPEED = 5  # Speed at which the baking meter increases

# Variables
var baking_level = 0
var game_over = false
var score: int = 0

signal minigame_complete(score)

func _ready():
	baking_meter.value = baking_level
	instructions_label.text = "Wait for the baking meter to get to the optimal range, then hit the button!"

func start_game():
	baking_timer.start()

func _on_baking_timer_timeout():
	if not game_over:
		increase_baking_level(BAKING_SPEED)

func increase_baking_level(amount):
	baking_level += amount
	baking_meter.value = baking_level  # Update the baking meter visually
	if baking_level >= MAX_BAKING_LEVEL:
		end_minigame(false)  # End the game if baking level exceeds max

func _on_stop_button_pressed():
	if not game_over:
		check_baking_result()
		end_minigame(true)

func check_baking_result():
	if OPTIMAL_MIN <= baking_level and baking_level <= OPTIMAL_MAX:
		instructions_label.text = "Perfect! Baking complete."
	elif baking_level < OPTIMAL_MIN:
		instructions_label.text = "Not baked enough! Keep baking."
	elif baking_level > OPTIMAL_MAX:
		instructions_label.text = "Overbaked! Stop baking."

func end_minigame(success):
	game_over = true
	baking_timer.stop()
	stop_button.disabled = true
	if success:
		instructions_label.text = "Baking complete!"
		print("Baking Minigame: Success + 1")
		score = 1
	else:
		instructions_label.text = "The pie isn't great, but it's edible."
		print("Baking Minigame: Failure + 0")
		score = 0
	emit_signal("minigame_complete", score)


func _on_start_button_pressed():
	start_game()
