extends Node2D

# nodes
@onready var baking_meter = $baking_meter
@onready var baking_timer = $baking_timer
@onready var instructions_label = $instructions_label
@onready var stop_button = $stop_button


# Constants
const MAX_BAKING_LEVEL = 100
const OPTIMAL_MIN = 60  # Minimum value for optimal baking range
const OPTIMAL_MAX = 80  # Maximum value for optimal baking range
const BAKING_SPEED = 10  # Speed at which the baking level increases (adjustable for tuning)

# Variables
var baking_level = 0
var game_over = false

signal minigame_complete

func _ready():
	baking_meter.value = baking_level
	instructions_label.text = "Wait for the perfect moment and hit stop!"

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
	else:
		instructions_label.text = "The pie isn't great, but it's edible."
	emit_signal("minigame_complete")
