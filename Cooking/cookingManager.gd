extends Node

# Constants
enum MinigameSection { FANNING, MIXING, BAKING, LOVE, NONE }

# Variables
var current_section = MinigameSection.FANNING

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
func on_section_complete():
	#hide the current minigame
	match current_section:
		MinigameSection.FANNING:
			$Fanning.hide()
			current_section = MinigameSection.MIXING
		MinigameSection.MIXING:
			$Mixing.hide()
			current_section = MinigameSection.BAKING
		MinigameSection.BAKING:
			$Baking.hide()
			current_section = MinigameSection.LOVE
		MinigameSection.LOVE:
			$Love.hide()
			current_section = MinigameSection.NONE
			show_final_result()
	# Start the next minigame section if not the final section
	if current_section != MinigameSection.NONE:
		start_section(current_section)

# placeholder function for showing final result
func show_final_result():
	print("All minigames complete! Show final result here.")
