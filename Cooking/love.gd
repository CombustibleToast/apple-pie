extends Node2D
# Node references
@onready var love_meter = $love_meter
@onready var oscillation_timer = $oscillation_timer
@onready var instructions_label = $instructions_label
@onready var stop_button = $stop_button

# Constants
const MAX_LOVE_LEVEL = 100
const OPTIMAL_CENTER_MIN = 45  # Minimum value for optimal love range
const OPTIMAL_CENTER_MAX = 55  # Maximum value for optimal love range
const OSCILLATION_SPEED = 5  # Speed at which the love level increases (adjustable for tuning)

# Variables
var love_level = 50
var moving_up = true
var game_over = false

signal minigame_complete

func _ready():
	love_meter.value = love_level
	instructions_label.text = "Hit stop when you feel the love is just right."

func start_game():
	oscillation_timer.start()

func _on_oscillation_timer_timeout():
	if game_over:
		return
	
	# Increase or decrease love level based on direction
	if moving_up:
		love_level += OSCILLATION_SPEED
		if love_level >= MAX_LOVE_LEVEL:
			moving_up = false
	else:
		love_level -= OSCILLATION_SPEED
		if love_level <= 0:
			moving_up = true

	love_meter.value = love_level  # Update the love meter visually

func _on_stop_button_pressed():
	if not game_over:
		check_love_result()
		end_minigame(true)

func check_love_result():
	if OPTIMAL_CENTER_MIN <= love_level and love_level <= OPTIMAL_CENTER_MAX:
		instructions_label.text = "Perfect! Love is just right."
	elif love_level < OPTIMAL_CENTER_MIN:
		instructions_label.text = "Not enough love! Keep loving."
	elif love_level > OPTIMAL_CENTER_MAX:
		instructions_label.text = "Too much love! Stop loving."

func end_minigame(success):
	game_over = true
	oscillation_timer.stop()
	stop_button.disabled = true

	if success:
		instructions_label.text = "<3!"
	else:
		instructions_label.text = "The pie is missing the perfect touch of love."
	emit_signal("minigame_complete")



