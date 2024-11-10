extends Node

# Constants
enum MinigameSection { FANNING, MIXING, BAKING, LOVE, NONE }

# Variables
var current_section = MinigameSection.FANNING
var scores = { "fanning": 0, "mixing": 0, "baking": 0, "love": 0 }

func _ready():
	print("Cooking Manager ready!")
	# Connect the minigame_complete signal from each minigame to the main script
	$Fanning.connect("minigame_complete", Callable(self, "on_section_complete"))
	$Mixing.connect("minigame_complete", Callable(self, "on_section_complete"))
	$Baking.connect("minigame_complete", Callable(self, "on_section_complete"))
	$Love.connect("minigame_complete", Callable(self, "on_section_complete"))

	# Start the first minigame
	print("Starting minigame section:", current_section)
	start_section(current_section)
	

func start_section(section):
	match section:
		MinigameSection.FANNING:
			print("Starting Fanning minigame")
			$Fanning.show()
			$Fanning.start_game()
		MinigameSection.MIXING:
			$Mixing.show()
			$Mixing.start_game()
			print("Starting Mixing minigame")
		MinigameSection.BAKING:
			$Baking.show()
			$Baking.start_game()
			print("Starting Baking minigame")
		MinigameSection.LOVE:
			$Love.show()
			$Love.start_game()
			print("Starting Love minigame")

# function to switch to the next minigame
func on_section_complete(score):
	match current_section:
		MinigameSection.FANNING:
			$Fanning.hide()
			scores["fanning"] = $Fanning.score
			current_section = MinigameSection.MIXING
		MinigameSection.MIXING:
			$Mixing.hide()
			scores["mixing"] = $Mixing.score
			current_section = MinigameSection.BAKING
		MinigameSection.BAKING:
			$Baking.hide()
			scores["baking"] = $Baking.score
			current_section = MinigameSection.LOVE
		MinigameSection.LOVE:
			scores["love"] = $Love.score
			$Love.hide()
			current_section = MinigameSection.NONE
			show_final_result()
	# Start the next minigame section if not the final section
	if current_section != MinigameSection.NONE:
		start_section(current_section)


# placeholder function for showing final result
func show_final_result():
	# Calculate total score
	var total_score = scores["fanning"] + scores["mixing"] + scores["baking"] + scores["love"]

	print("Total score:", total_score)

	# Calculate rank
	var rank = ""
	match total_score:
		0:
			rank = "F"
		1, 2:
			rank = "B"
		3:
			rank = "A"
		4:
			rank = "P"
		_:
			rank = "?"
	
	print("Rank:", rank)

	# Show final result screen
	$FinalResult.show()
	$FinalResult.set_results(rank)
