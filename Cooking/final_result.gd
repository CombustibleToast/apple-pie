extends Node2D

# Nodes
@onready var results_label = $results_label

func set_results(rank):
	results_label.text = "Rank: " + rank
	results_label.show()
	print("Final Rank:", rank)