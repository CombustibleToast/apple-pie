class_name Dialogue
extends Object

const speaker_class = preload("res://sm/scripts/speaker.gd")
const DEFAULT_NARRATION_COLOR = "darkgray"
const DEFAULT_SPEECH_COLOR = "white"
var narration_color : String = DEFAULT_NARRATION_COLOR # Color for narration
var speech_color : String = DEFAULT_SPEECH_COLOR # Color for dialogue
const USE_FALLBACK_FONT : bool = false # Enables / disables a more-readable fallback font (if pixels are unreadable). Currently buggy. TODO - Add options menu
var narrate : String
var speech : String 
var speaker : Speaker
var line : String # BBCode already applied
var narrating : bool = true
var rng = RandomNumberGenerator.new()

func _init(mys : Speaker = Speaker.new(), myl : String = "!TESTIFICATE!", narraColor : String = "darkgray") -> void:
	speaker = mys
	narration_color = narraColor
	narrate = "[color=" + narration_color + "][i]"
	speech = "[/i][color=" + speech_color + "]"
	line = parse(myl)

func _to_string() -> String:
	return line

## BBCodes the string.
func parse(inp : String) -> String:
	var out = inp
	# Handle narration - Text outside the voice of the characters is italicized
	# The speaker tag "force_narration" skips this.
	# It also is skipped if there are no quote marks (the whole thing is narration)
	var out_quotes = out.split("\"")
	if speaker.text_tags.has("force_narration") or out_quotes.size() == 1:
		out = narrate + out # Whole thing is narration
		narrating = true
	else:
		for idx in range(out_quotes.size()):
			# Odd-indexed entries are interiors of quotes (should not be italicized)
			if (idx % 2) == 1: out_quotes[idx] = styleSpeech(out_quotes[idx])
			else: out_quotes[idx] = styleNarration(out_quotes[idx])
		out = "\"".join(out_quotes)
		narrating = false # Setting false so that the dialogue plays the speaker's talksound
	if USE_FALLBACK_FONT:
		out = "[font=res://font/system_fonts.tres]" + out + ""
		# I don't pretend to understand how system fonts work but this sure Doesn't
	#print(out)
	return out

func styleSpeech(inp : String) -> String:
	var out = inp
	if speaker.text_tags.has("shaky"):
		out = "[wave amp=20]" + out + "[/wave]"	
	return out

func styleNarration(inp : String) -> String:
	var out = inp
	if out.is_empty(): return out # Narration is empty (typically the start / end of a line with a quotation mark)
	if narrating: 
		out = narrate + out + speech
	narrating = !narrating # Toggle 
	return out


#NYI
#enum GenderedWord { SHE, HER, HERS, HERSELF, MISTRESS } # Oh god I need to make this work with a translator
#enum PronounSet { HE, SHE, THEY, IT, EY, ZE }

# Returns words for referring to Dakota.
#func genderflux(word : GenderedWord) -> String:
#	var c : int = rng.randi_range(0,5)
#	var pronouns = c as PronounSet
#	match(word):
#		GenderedWord.SHE:
#			match(pronouns):
#				PronounSet.HE: return "he"
#				PronounSet.SHE: return "she"
#				PronounSet.THEY: return "they"
