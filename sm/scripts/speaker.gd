class_name Speaker
extends Resource
@export var internal : String # Internal reference name
@export var icon : CompressedTexture2D # No idea if this is right.
@export var display : String # Display name.
@export var name_color : String # Color for the display name
@export_enum("shaky", "character", "self", "force_narration") var text_tags : Array[String] = []
@export var talksound : AudioStreamRandomizer = load("res://sm/resources/ui/default_talksound.tres") # Speaker's sound effects (randomly selected and played)
@export var base_pitch : float = 1.0 # Basic pitch of this speaker.
@export var stylebox : StyleBox

func _init(myi : String = "ERR", standoname : String = "ERRANT", myd : String = "[shake][rainbow]SYSTEM ERROR[/rainbow][/shake]") -> void:
	internal = myi
	icon = load("res://sm/images/chaticons/icon_" + standoname + ".png")
	# print("icon exists? " + str(icon))
	text_tags = ["QUAKE", "force_narration"]
	display = myd

func _to_string() -> String:
	var chatterName = "[b]" + display + "[/b]"
	if name_color.is_empty(): print("Current speaker has no defined name color; not styling")
	else:
		chatterName = "[color=" + name_color + "]" + chatterName + "[/color]"
	return chatterName
