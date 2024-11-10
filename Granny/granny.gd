extends Area3D

@export var player_node: CharacterBody3D
@export var storyteller: Control

@onready var player_in_interact_range: bool = false
@onready var required_item_list: Array = [
	"Apple 1",
	"Apple 2",
	"Apple 3",
	"Dough",
	"Sugar",
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Check for interaction
	if player_in_interact_range and Input.is_action_just_pressed("interact"):
		trigger_interaction()

func trigger_interaction():
	print("Player interacted with %s!" % name)
	check_ingredient_completion()

func check_ingredient_completion():
	# Guard clause: don't run this code if player is not linked to this script
	if not player_node:
		print("Player node is not linked to granny!")
		return
	
	# Find the missing items
	var player_items:Array = player_node.collected_items
	var missing_items:Array = []

	for item in required_item_list:
		if item not in player_items:
			missing_items.append(item)
			
	# If there are items missing, trigger the missing items dialogue
	# 	Not implemented, so just print that items are missing
	if len(missing_items) > 0:
		print("Player is missing items:")
		storyteller.ext_load_file("granny_missing_items")
		for item in missing_items:
			print("\t%s" % item)
	
	# There are no missing items, go to the next section (cooking minigames?)
	#	Not implemented, so just print that all items are gotten
	else:
		print("Player has all items!")
		storyteller.ext_load_file("granny_all_items") 

func _on_area_entered(area:Area3D) -> void:
	print("%s detected entry from %s" % [name, area.name])
	player_in_interact_range = true
	pass # Replace with function body.


func _on_area_exited(area:Area3D) -> void:
	print("%s detected exit from %s" % [name, area.name])
	player_in_interact_range = false
	pass # Replace with function body.
