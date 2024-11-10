extends MarginContainer

## A [MarginContainer] that contains and displays [Dialogue].
## Per rules of Godot UI, borrows the [Theme] of the greater Storyteller, in particular being styled by the [theme_item Panel].
const SPEAKER_STYLING_ON = true
const INTERJECT_STYLING_ON = true
const CLICKED_STYLING = "[b][color=mediumpurple][wave amp=50]$1[/wave][/color][/b]"
const CLIPPED_STYLING = "[color=plum]$1[/color]"
signal interjected(meta : String, n : Node)
var dialogue : Dialogue

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Custom stylization
	$Label.text += str(dialogue)
	if SPEAKER_STYLING_ON:
		if dialogue.speaker.stylebox: 
			$Label/Background.add_theme_stylebox_override("panel", dialogue.speaker.stylebox)		
	$Label/Background/Talksprite.texture = dialogue.speaker.icon
	if INTERJECT_STYLING_ON: # Interject stylization
		if dialogue.narration_color != dialogue.DEFAULT_NARRATION_COLOR:
			var newpanel = get_theme_stylebox("panel", "Panel").duplicate()
			newpanel.border_color = dialogue.narration_color
			$Label/Background.add_theme_stylebox_override("panel", newpanel)
			pass
	Anima.Node(self).anima_animation("light speed in left", 0.3).play()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

## Replaces all URL tags so that we don't reach for files we don't have access to anymore
func lights_out():
	var re := RegEx.create_from_string("\\[url=.*?\\](.*?)\\[\\/url\\]")
	$Label.text = re.sub($Label.text, CLIPPED_STYLING, true)

## Replaces the URL tag clicked with CLICKED_STYLING
func _on_label_meta_clicked(meta: Variant) -> void:
	# Style the text
	var label = $Label.text
	var re := RegEx.create_from_string("\\[url=%s\\](.*?)\\[\\/url\\]" % meta) # Contribution from Ste / qubus https://discord.com/channels/1235157165589794909/1259831429324472433/1301292844929122335
	$Label.text = re.sub(label, CLICKED_STYLING, true)
	interjected.emit(meta, self)
	pass # Replace with function body.
