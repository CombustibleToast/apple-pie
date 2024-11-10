extends Control

const RESERVED_WORDS = [ "GOTO", "FILE", "END", "LINK", "ERR", "SHOWIF", "SHOWONCE", "DEBUG", "start" ]

const SM_DEBUG = true ## Controls if "SHOWIF@DEBUG" displays
const CHATBOX_RES = preload("res://ui/chat.tscn")
const CHATBOX_HL_RES = preload("res://ui/chat_headless.tscn")
const CHATBOX_BRK_RES = preload("res://ui/chat_break.tscn")
const CHATLINK_RES = preload("res://ui/chat_link.tscn")
const CHATLINK_CLS = preload("res://sm/scripts/chat_link.gd")
const DIALOGUE_CLS = preload("res://sm/scripts/dialogue.gd")
const RESOURCES_PATH : String = "res://sm/resources/" # Path to text
const NARRATION_DEFAULT_COLOR = "darkgray"
const SELF_DEFAULT_COLOR = "mediumpurple"
const BREAK_TEXT_STYLING : String = "[center][font=font/zeldadxt.ttf][font_size=35]"
const ADVANCE_TEXT_STYLING : String = BREAK_TEXT_STYLING + "[tornado radius=3][pulse freq=0.7 color=#0][font_size=21]"
const MAX_MSGS : int = 20 ## Const which determines how many messages are allowed to be in the chatlog before the oldest ones are deleted
var anim_max
var anim_min
@export var open_on_start = true ## Determines if the storyteller in this scene opens when it loads. 
@export var on_load : String = "c0start" ## The file to load on `_ready`.
@export var passage_delimiter : String = "\\n\\n" 	## User-defined delimiter for passages. Whenever these appear in files, they will seperate.
@export var tab_delimiter : String = "\\t" 			## User-defined delimiter which operates as a tab. Useful if you want to replace it with spaces (per editor preference).
@export var comment_delimiter : String = "#" 		## User-defined delimiter which determines lines that begin with it as comments.
@export var interject_delimiter : String = "!" 		## User-defined delimiter which determines passages that are named with it as interjects.
@export var clarifier_delimiter : String = "@" 		## User-defined delimiter which is used as indicator of a clarifier to change the mode or create superdirections.
@export var link_delimiter : String = ">"			## User-defined delimiter which is used as indicator of a link.
@export var speaker_separator : String = " ~ "		## User-defined separator which appears between the speaker of a line and the line itself (verbatim)
var current_file = {} ## Dictionary containing passages, keyed to their names.
var passage : String  ## Current passage loaded.
var passage_name : String ## Passage name loaded
var click_to_advance : bool = true ## Bool which determines if clicking can advance the plot / load the next line.
var currently_talking : Speaker ## The Speaker who is currently speaking.
var mem_speakers = { "ERR" : Speaker.new() } ## Memory for speakers in a scene, loaded per textfile to minimize file-access.
var familiar : bool ## Bool which flicks on when we spawn a header for a specific talker -- when we are "familiar" with this speaker.
var t2_mode : String = "" ## String which determines the effect of tab-level 2. Used for things like populating link boxes.
var advancetext : CenterContainer
var msg_count : int = 0 ## Counts how many messages are in the scrollbox. Limits scope of the passage box.
var line_num : int = 0 ## Counts lines of a passage text remaining until we load a Responses object.
var timers = { 
	"ATfade" : 0.0, ## Fades in the advancetext
	"ATwait" : 0.0  ## Pauses the advancetext.
	}
var queued_actions = []
var dialogue_context = {} ## Contains the line and additional functionality. Used to populate link boxes and apply clarifiers
var maximized : bool = false ## Determines if the window is maximized
var accepting_external_input = true

##### OVERVIEW ######
# This system is called SM / StoryMode. Storyteller is the object that runs it.
#
# This system was highly inspired by the internal formatting of corru.observer (https://corru.observer), a game you should play.
# However it should also be noted that our systems are not identical (and that I'm unaffiliated with them).
# This system supports certain features that corru.works's does not, and vice versa, naturally.
#
# A .txt file is loaded in using load_file.
#
# A "passage" is a dialogue scene contained within these .txt files. Each file can contain many such passages, and the passages will ideally branch to one another.
# Passages are defined by being placed between instances of passage_delimiter, starting at start of file (which is a defacto passage_delimiter)
# Worth noting that commented lines are not counted (lines which begin with #)
# NYI multiline comments (SYNTAX_NOT_COMPLETE)
#
# When loaded, the .txt file saves the text contents of all passages within that file as dictionary entries in current_file.
# In SOP, we will only operate within one .txt file at a time, loading them using external script calls (like loading a new area).
# However, hot-swapping files is supported using superdirections.
# 
# The first line of a passage is always a tab level 0 (T0) string, a "name" used for looking up that passage elsewhere (i.e. `current_file["name"]`)
# T1 strings are generally speakers, defined in the "res://sm/resources/speakers/" folder; these determine how the chatboxes are flavored
# T2 strings are generally dialogue lines, stated by their closest T1 speaker. They can also be other things, determined by t2_mode (used for populating link boxes)
# T3 strings are specially handled events and conditions which take place when a dialogue line is put into console (i.e. sound effects).
# 
# When read into the UI, a talksound is played (see speaker.gd for more on that), but ONLY if the text contains a quotation
# A generic UI click sound is also played


# Called when the node enters the passage tree for the first time.
func _ready() -> void:
	advancetext = find_child("ADVANCETEXT")
	passage_delimiter = passage_delimiter.c_unescape() # So that it looks correct in editor
	tab_delimiter = tab_delimiter.c_unescape() # So that it looks correct in editor
	print(len(tab_delimiter))
	anim_max = Anima.Node($Panel).anima_animation("bouncing in left", 0.5).anima_with(Anima.Node($Buttons/MaxButton)).anima_animation("fade out left").anima_with(Anima.Node($Buttons/MinButton)).anima_animation("bouncing in left", 0.3)
	anim_min = Anima.Node($Panel).anima_animation("bounce out left", 0.3).anima_with(Anima.Node($Buttons/MaxButton)).anima_animation("bouncing in left").anima_with(Anima.Node($Buttons/MinButton)).anima_animation("bounce out left", 0.3)
	if open_on_start: load_file(on_load)
	else:
		maximized = true 
		max_min()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	advancetext.get_child(0).visible_ratio = 1.0 - timers["ATfade"] / 3
	if click_to_advance: 
		timers["ATwait"] -= delta
		if(timers["ATwait"] < 0): timers["ATfade"] -= delta
	else:
		if timers.has("SMwait"): 
			timers["SMwait"] -= delta
			if(timers["SMwait"] < 0):
				timers.erase("SMwait")
				toggle_input("")
				print("timer expired!")
	if !queued_actions.is_empty() and !timers.has("SMwait"): # RUN QUEUED ACTIONS
		click_to_advance = false
		for action in queued_actions: 
			if !action.is_valid():
				push_warning(action.get_method() + " is not a valid Callable")
			else:
				print("trying to run..." + action.get_method())
				await action.call()
		queued_actions.clear()
		click_to_advance = true
	pass

func story_clicked(quiet : int = 0) -> void:
	timers["ATfade"] = 7.0
	timers["ATwait"] = 3.0
	advancetext.get_child(0).text = ADVANCE_TEXT_STYLING + "CLICK / ENTER to advance"
	await spawn_chatbox(next_line(), -1, quiet)

func ext_load_file(file_name : String):
	if !current_file.is_empty(): print_debug("tried to load a new file, but we're already in a file!")
	else: load_file(file_name)

func ext_load_passage(psg_name : String):
	if !current_file.is_empty(): print_debug("tried to load a new passage, but we're already in a file!")
	else: load_passage(psg_name)

## Loads a file. ONLY CALL THE EXT VERSION WITH SIGNALS
func load_file(file_name : String) -> void:
	if !maximized: max_min()
	if current_file: kill_meta()
	current_file = {} # Clear the dictionary
	var res_absolute_path = file_name.is_absolute_path() # Handles file paths copied directly from editor (FOR DEBUG / POSSIBLE MODDING PURPOSES)
	var filepath = (file_name) if res_absolute_path else (RESOURCES_PATH + "text/" + file_name + ".txt")
	var file = FileAccess.open(filepath, FileAccess.READ).get_as_text()
	$Buttons/MinButton.disabled = true
	# Remove comments / notes
	var regex = RegEx.create_from_string("(^" + comment_delimiter + ".*\\n)|(^\\s*\\n)")
	file = regex.sub(file, "", true)
	# Split up passages
	var passages = file.split(passage_delimiter) # Passages are divided by blank newlines
	#$Buttons/MinButton.disabled = true
	advancetext.get_child(0).text = ADVANCE_TEXT_STYLING + "CLICK / ENTER to BEGIN"
	for p in passages:
		var p_name = p.get_slice("\n", 0) # Get passage's name
		var passage_beyond = p.trim_prefix(p_name + "\n") # Get the rest of the passage
		current_file[p_name] = passage_beyond
	load_passage("start") # Files will typically begin with this, but we can load it arbitrarily for ease of file editing

## Ends the reading of a file.
func end_file():
	kill_meta()
	var termina = CHATBOX_BRK_RES.instantiate()
	termina.get_child(0).text = BREAK_TEXT_STYLING + "[color=dimgray]––««––[color=white]×¤×[color=dimgray]––»»––"
	$Bzzrt.play()
	await chatlog_add(termina)
	Anima.Node(termina).anima_animation("fade in down", 0.3).play()
	currently_talking = null
	click_to_advance = false
	accepting_external_input = true
	current_file = {}
	$Buttons/MinButton.disabled = false
	line_num = 0

## Starts a passage from a currently loaded file (to be used for changing passages)
func load_passage(p_name : String) -> bool:
	if current_file.is_empty(): push_error("tried to load a passage with no file loaded!")
	if p_name == "END":
		end_file()
		return true
	var try_passage = current_file.get(p_name)
	if try_passage:
		if !dialogue_context.is_empty(): await process_context(p_name)
		print("Beginning passage - " + p_name)
		self.passage_name = p_name
		click_to_advance = true
		#print("TEST EXPORT - [" + try_story + "]")
		passage = try_passage
		var linked_in = (line_num != 0) or (msg_count != 0)
		accepting_external_input = false
		line_num = -1
		dialogue_context.clear() # No inter-passage block-controls
		if linked_in:
			$Kaclicker.play()
			story_clicked(1) ## When linked to a new passage, start it off by advancing one line
		return true
	else: say_debug("Tried to load a passage [" + passage_name.c_escape() + "] but couldn't find it!!")
	return false

func load_interject(interject_name : String, n : Node) -> bool:
	var index = n.get_index() + 1
	if !current_file: say_debug("Trying to load a meta, but there's no file...")
	var try_interject = current_file.get(interject_delimiter + interject_name)
	if try_interject:
		print("interjecting at idx " + str(index))
		var interjection = try_interject.strip_edges()
		familiar = true
		spawn_chatbox(say(interjection, n.dialogue.speaker, false, SELF_DEFAULT_COLOR), index, 1)
		$Kaclicker.play()
		# Interjects load up a single line passage
		return true
	else: say_debug("Tried to load an interject [" + interject_name.c_escape() + "] but couldn't find it!!")
	return false

## Destroys the meta of interjects when files are swapped
func kill_meta():
	dialogue_context.clear()
	for n in $Panel/ScrollContainer/VBoxContainer.get_children():
		if n.has_method("lights_out"): n.call_deferred("lights_out")

## Sets up all necessary variables for talking for a specific speaker. Grabs the speakers from `mem_speakers`, or loads it and then saves it for the future.
func change_speaker(speaker : String = "ERR") -> Speaker:
	speaker = speaker.strip_edges()
	var spkr_res
	if mem_speakers.get(speaker): 
		spkr_res = mem_speakers[speaker]
	else:
		print("LOADING NEW SPEAKER - " + speaker)
		spkr_res = load(RESOURCES_PATH + "speakers/spkr_"+ speaker + ".tres")
		mem_speakers[speaker] = spkr_res # Saves it into memory for later
	familiar = false
	currently_talking = spkr_res
	return spkr_res

## Creates a new Dialogue object
func say(line : String, speaker : Speaker = currently_talking, update_speaker : bool = true, color : String = NARRATION_DEFAULT_COLOR) -> Dialogue:
	if update_speaker and not currently_talking == speaker: 
		change_speaker(speaker.internal)
	return Dialogue.new(speaker, line.strip_edges(), color)

## Sends a debug-styled message to the user, for user-end bug catching.
func say_debug(line : String) -> void:
	$Bzzrt.play()
	spawn_chatbox(say("ERROR ENCOUNTERED -- not part of the story, we promise!", mem_speakers["ERR"]))
	spawn_chatbox(say(line))
	push_warning(line)

## Grabs the next line of a dialogue file
func next_line_string() -> String:
	line_num += 1
	return passage.get_slice("\n", line_num)

func peek_next() -> String:
	return passage.get_slice("\n", line_num +1)

func should_not_display(key : Variant):
	var check_conditionals = dialogue_context[key].any(func(bl): 
			if bl is bool: 
				return bl == false # If a SHOWIF or SHOWONCE failed
			return false)
	if check_conditionals: print("a flag was false for: " + str(dialogue_context[key]))
	return check_conditionals

## Processes the next line of a dialogue file.
func next_line() -> Dialogue:
	var next = next_line_string()
	#print("["+ next +"]")
	#T0 - Name of scenes.
	if next.is_empty():
		say_debug("Processed a blank line") # ERROR OUT
		return null
	var t0 = get_tab_lvl(next, 0)
	# NOTE 10/06/2024 - Not sure if we need to process tier 0 since literally always it'll be used for scene names (which are stripped out by load_file)
	# NOTE 10/17/2024 - Yes we can and should lmao
	# NOTE 10/19/2024 - This should be used for block controls
	match(t0):
		"\n":
			say_debug("Processed a new line") # ERROR OUT
			return null
		tab_delimiter: # TIER UP
			return handle_t1(next)
		_: # NAME OF SCENE
			load_passage(next.strip_edges()) # Possibly redundant
			return next_line()

func get_tab_lvl(string : String, i : int) -> String:
	var start = len(tab_delimiter) * i
	# print("Grabbing tab level " + str(i) + " from [" + str.c_escape() + "]")
	var out = string.substr(start, len(tab_delimiter))
	# print("... it's [" + out.c_escape() + "]")
	return out

## Handles Tier 1 of dialogue file
func handle_t1(next : String) -> Dialogue:
	#T1 - Speaker of dialogue / Responses
	var t1 = get_tab_lvl(next, 1)
	match(t1):
		tab_delimiter: # TIER UP
			return handle_t2(next)
		_: # DEFAULT CASE: Speakers / Modeswitches
			if next.contains(clarifier_delimiter): 
				var speaker = next.get_slice(clarifier_delimiter,1)
				if speaker.is_empty(): 
					return handle_superdirect(next)
				t2_mode = next.get_slice(clarifier_delimiter,0).strip_edges()
				print("T2 mode changed! " + t2_mode)
				change_speaker(speaker)
			else:
				if not t2_mode.is_empty(): print("T2 mode cleared! " + t2_mode)
				t2_mode = ""
				change_speaker(next)
			#print("CHANGED WHO IS TALKING to " + str(spkr_res))
			return next_line()

## Handles Tier 2/3 of dialogue passage
func handle_t2(next : String) -> Dialogue:
	#T2 - Dialogue lines themselves
	# var t2 = get_tab_lvl(next, 2)
	match(t2_mode):
		"LINK": # LINK MODE
			link_mode(next)
		_: # NORMAL DIALOGUE
			dialogue_context[0] = [next.strip_edges()] # Sets the dialogue line
			while peek_next().begins_with(tab_delimiter.repeat(3)): # Handles T3 for dialogue
				next = next_line_string()
				var clarifier = handle_clarifier(next)
				dialogue_context[0].append_array(clarifier)
	#if dialogue_context.has("!BLOCK!"): # BLOCK CONTROL
	#	dialogue_context[0].append_array(dialogue_context["!BLOCK!"])
	if dialogue_context.has(0): # We're trying to say a line
		if should_not_display(0): return next_line() ## HANDLING SHOWIF / SHOWONCE
		return say(dialogue_context[0][0])
	return null

## Handles superdirections, which are T1 strings used for quickswapping files and passages.
## These are indicated by two clarifier_delimiter s.
## They also may be used to step into new functions.
func handle_superdirect(next : String):
	next = next.strip_edges()
	var dest = next.get_slice(clarifier_delimiter, 2)
	## @@ indicates SUPERDIRECTIONS -- allows for quickswapping
	match(next.get_slice(clarifier_delimiter,0)):
		"CLOSE":
			max_min()
			end_file()
		"GOTO": ## GOTO@@ -- steps into a new passage
			load_passage(dest)
		"FILE": ## FILE@@ -- hotswaps to a new file
			line_num = 0
			load_file(dest)
			story_clicked(0)
		_:
			say_debug("unhandled / malformed superdirect -- nice going!")
			pass
	return null

## Handles T3 / clarifiers.
## Appends clarifiers to the dialogue_context array
func handle_clarifier(t3 : String) -> Array:
	t3 = t3.strip_edges()
	print(t3)
	var out = []
	var first_half = t3.get_slice(clarifier_delimiter,0).trim_prefix("____")
	var second_half = t3.get_slice(clarifier_delimiter,1)
	match(first_half):
		"CLOSE":
			# CLOSE -- to be used for automagically :tm: closing the whole window for effect
			# NEEDS TESTING
			max_min()
			end_file()
			return out
		"CALL":
			## CALL -- adds a callable to the listing
			## These are queued once the chatbox hits the screen.
			var callable = Callable.create(self, second_half)
			return [callable]
		"SIGNAL":
			## SIGNAL -- to be used for signalling other things going on
			## NYI
			pass
		"CONTINUE":
			# CONTINUE -- used to stop a block control
			dialogue_context.erase("!BLOCK!")
			return out
		"WAIT":
			## WAIT -- pauses a certain amount of time before reenabling "click_to_advance"... 
			## typically called when animation things need to happen simultaneously
			## NYI
			return [float(second_half)]
		"AUTO": 
			## AUTO -- auto-advances... like wait but "clicks" after
			return [float(second_half), story_clicked]
		"SHOWIF":
			## SHOWIF -- if a variable matches a specific state, add it to the chatbox
			if second_half.contains("DEBUG"):
				out.append(SM_DEBUG)
			## NYI - CAN CHECK SAVEGAMES, CHECK JSON INFORMATION
			return out
		"SHOWONCE":
			## SHOWONCE -- essentially SHOWIF but simplified
			## only returns true if the line hasn't been seen before (mini flags)
			## NYI
			pass
	print_debug("unhandled clarifier")
	return ["!unhandled!"]
	
## Reads in an entire dialogue brancher. Populates a `ChatLink` object and fills it with links.
func link_mode(next : String):
	var meta_destination = 0
	var display_text = ""
	click_to_advance = false
	while next.begins_with(tab_delimiter.repeat(2)):
		next = next.strip_edges()
		display_text = link_delimiter + next.get_slice(" : ", 1)
		meta_destination = next.get_slice(" : ", 0).substr(1) ## Cuts off the start (SYNTAX_NOT_COMPLETE)
		dialogue_context[meta_destination] = [display_text]
		print("Adding link " + display_text + " pointing to " + meta_destination)
		while peek_next().begins_with(tab_delimiter.repeat(3)): # Handles T3 for links
			next = next_line_string()
			var clarifier = handle_clarifier(next)
			dialogue_context[meta_destination].append_array(clarifier)
		if not peek_next().contains(link_delimiter): break
		else: next = next_line_string()
	dialogue_context.erase(0)
	var newlinkbox = CHATLINK_RES.instantiate() # Instance of chat linkbox
	var talksprite = newlinkbox.get_child(0).get_child(0) 
	talksprite.texture = currently_talking.icon	# Update talksprite
	chatlog_add(newlinkbox)
	newlinkbox.link_selected.connect(load_passage) # Realizing I have to just trust the system lmfao
	for k in dialogue_context.keys():
		if should_not_display(k) or dialogue_context[k][0] is not String:
			continue ## SKIPS
		else:
			print("NEW LINK TO " + k)
			newlinkbox.add_link(dialogue_context[k][0], k) # Create link for each link stated
			## Worth noting that newlinkbox should probably handle the extra T3 context sent to it
	
## Populates information about a chatbox, instantiates it, and places it on the bottom of the scroll container.
## Used for normal dialogue spawning functions.
func spawn_chatbox(dialogue : Dialogue, to_index : int = -1, quiet : int = 0) -> void:
	if not dialogue: 
		print("spawn_chatbox: null dialogue!")
		return
	if str(dialogue).is_empty():
		print_debug("spawn_chatbox: empty dialogue!")
		return
	var newbox
	var ds = dialogue.speaker
	# Check new speaker
	$Talker.stream = ds.talksound
	$Talker.pitch_scale = max(0.1, ds.base_pitch)
	if familiar:
		newbox = CHATBOX_HL_RES.instantiate()
		newbox.get_child(0).text = ""
	else: # NEW SPEAKER
		newbox = CHATBOX_RES.instantiate()
		newbox.get_child(0).text = str(ds) + speaker_separator
		familiar = true
	newbox.dialogue = dialogue
	# Set up data
	newbox.interjected.connect(load_interject)
	newbox.get_child(0).meta_hover_started.connect(toggle_input)
	newbox.get_child(0).meta_hover_ended.connect(toggle_input)
	if dialogue_context.has(0):
		await process_context(0)
		dialogue_context.erase(0)
	await chatlog_add(newbox, to_index)
	# CARRY FORWARD BLOCK CONTROL
	var block_control = dialogue_context["!BLOCK!"] if dialogue_context.has("!BLOCK") else [true]
	dialogue_context["!BLOCK!"] = block_control
	if not dialogue.narrating and quiet != 2: $Talker.play() # Only plays talksound if not pure narration (i.e. someone actually talks in it)
	if quiet == 0: $Clicker.play() ## 1 mutes the clicker, 2 mutes the clicker AND the talker
	pass

## Adds a node to the chatlog at `to_index` and focuses it.
## By default, adds at bottom of list.
func chatlog_add(n : Node, to_index : int = -1):
	msg_count += 1
	if msg_count > MAX_MSGS: 
		await chatlog_rem() # LOOKS JANKY with the SCROLL BOX, MIGHT NEED TO FIX LATER - JAN
	var vb = $Panel/ScrollContainer/VBoxContainer
	vb.add_child(n)
	vb.move_child(n, to_index)
	n.name = (passage_name + currently_talking.internal + str(msg_count)).to_pascal_case() # This uses currently_talking even in contexts where we aren't speaking as the current talker, but it's fine bc its purely internal
	vb.move_child(advancetext, -1) # Moves advance text to the bottom
	await get_tree().process_frame # Has to await this to ensure race conditions don't occur; see https://docs.godotengine.org/en/stable/classes/class_scrollcontainer.html#class-scrollcontainer-method-ensure-control-visible
	$Panel/ScrollContainer.ensure_control_visible(n)

## Removes a node from the chatlog at `to_index`.
## By default, removes eldest child.
func chatlog_rem(from_index : int = 0):
	var vb = $Panel/ScrollContainer/VBoxContainer
	var indexed_child = vb.get_child(from_index)
	vb.remove_child(indexed_child)
	await get_tree().process_frame
	msg_count -= 1
	
func process_context(k : Variant):
	# REACT TO DIALOGUE CONTEXT
	for ct in dialogue_context[k]:
		if ct is bool:
			continue
		if ct is float: # TIMERS
			timers["SMwait"] = ct
			click_to_advance = false
		if ct is Callable:
			queued_actions.append(ct)

func _on_gui_input(event : InputEvent) -> void:
	if click_to_advance:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			await story_clicked()

func toggle_input(_meta : Variant) -> void: 
	if t2_mode.is_empty(): # Not handling meta elsewhere
		click_to_advance = !click_to_advance

func max_min() -> void:
	maximized = !maximized
	if maximized: await anim_max.play()
	else: await anim_min.play()
	$CarriageReturn.play()
	click_to_advance = maximized && current_file
	$Buttons/MaxButton.visible = !maximized
	pass # Replace with function body.
