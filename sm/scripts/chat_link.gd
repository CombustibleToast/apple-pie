class_name ChatLink
extends MarginContainer

const LINKLABEL_RES = preload("res://ui/chat_linklabel.tscn")
const LINK_COLOR = "mediumpurple"
const SELECTED_LINK_COLOR = "white"
const INACTIVE_LINK_COLOR = "purple"
signal link_selected(meta)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Anima.Node(self).anima_animation("light speed in left", 0.3).play()
	pass # Replace with function body.

## Strips bbcode from a given string using regex. https://github.com/godotengine/godot-proposals/issues/5056
func strip_bbcode(source : String) -> String:
	var regex = RegEx.new()
	regex.compile("\\[.+?\\]")
	return regex.sub(source, "", true)

## Adds a link to the chatlink.
func add_link(string : String, link : String) -> void:
	var newlink = LINKLABEL_RES.instantiate()
	newlink.text = "[color=" + LINK_COLOR + "][url=" + link + "]" + string
	$VBoxContainer.add_child(newlink)
	newlink.meta_clicked.connect(_link_clicked)

## "Selects" the chosen link permanently and emits a signal that is picked up by the storyteller script.
func _link_clicked(meta : String):
	for node in $VBoxContainer.get_children():
		if node is RichTextLabel:
			var stripped_text = strip_bbcode(node.text)
			if node.text.contains(str(meta) + "]"):
				node.text = "[b][color=" + SELECTED_LINK_COLOR + "]" + stripped_text
			else:
				node.text = "[i][color=" + INACTIVE_LINK_COLOR + "]" + stripped_text
	link_selected.emit(str(meta))
	
func lights_out():
	pass
