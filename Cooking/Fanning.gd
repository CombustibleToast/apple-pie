extends Node2D
# Node references
@onready var flame_meter = $Control/HBoxContainer/Control3/flame_meter
@onready var instructions_label = $Control/HBoxContainer/Control2/instructions_label
@onready var intensity_timer = $intensity_timer
@onready var game_timer = $game_timer
@onready var timer_label = $Control/HBoxContainer/Control/timer_label

# Constants
const MAX_INTENSITY = 100 
const MIN_OPTIMAL = 50  # Min intensity for the optimal range
const MAX_OPTIMAL = 75  # Max intensity for the optimal range
const REQUIRED_DURATION = 12  # Time (seconds) to maintain optimal range

# Variables
var flame_intensity: int = 50  # Initial flame intensity
var in_optimal_time: int = 0  # Time spent in the optimal range
var game_over = false
var score: int = 0

signal minigame_complete(score)

func _ready():
	flame_meter.value = flame_intensity
	score = 0

func start_game():
	game_timer.wait_time = 20 #Normal: 20 Debug: 5
	game_timer.start()
	intensity_timer.start()

# display the timer value
func _process(_delta):
	timer_label.text = "Timer: " + str(int(game_timer.time_left))

func _input(event):
	if event.is_action_pressed("ui_accept") and not game_over:  # "ui_accept" = mouse click
		increase_flame_intensity(5)  # Increase by 10 units per click

func increase_flame_intensity(amount):
	flame_intensity += amount
	flame_intensity = clamp(flame_intensity, 0, MAX_INTENSITY)  # Limit flame intensity to max value
	update_flame_meter()

func _on_intensity_timer_timeout():
	flame_intensity -= 5  # Decrease flame intensity by 5 units each tick
	flame_intensity = max(flame_intensity, 0)  # Ensure intensity doesn't go below zero
	update_flame_meter()
	check_optimal_range()

func update_flame_meter():
	flame_meter.value = flame_intensity

# Each frame, check if the current flame intensity is within the target range. If so, count that time toward in_optimal_time.
func check_optimal_range():
	if MIN_OPTIMAL <= flame_intensity and flame_intensity <= MAX_OPTIMAL:
		in_optimal_time += intensity_timer.wait_time  # Add time within optimal range
		instructions_label.text = "Good! Keep the flame steady."
	elif flame_intensity < MIN_OPTIMAL:
		instructions_label.text = "Flame is too low! Fan harder!"
	elif flame_intensity > MAX_OPTIMAL:
		instructions_label.text = "Flame is too high! Slow down!"

	if in_optimal_time >= REQUIRED_DURATION:
		print("Win: Time in optimal range: " + str(in_optimal_time))
		end_minigame(true) # Success if optimal range maintained 

func _on_game_timer_timeout():
	print("Fail: Time in optimal range: " + str(in_optimal_time))
	end_minigame(false)  # Fail if time runs out

func end_minigame(success):
	game_over = true
	intensity_timer.stop()
	game_timer.stop()
	
	if success:
		instructions_label.text = "Success! You kept the flame steady!"
		print("Fanning Minigame: Success + 1")
		score = 1
	else:
		instructions_label.text = "Finish! You did alright..."
		print("Fanning Minigame: Fail + 0")
		score = 0
	emit_signal("minigame_complete", score)


func _on_button_pressed():
	start_game()
