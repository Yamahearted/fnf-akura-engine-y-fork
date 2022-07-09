extends CanvasLayer

const ALPHABET:PackedScene=preload("res://scenes/Alphabet.tscn")
var options_text:PoolStringArray=[]

var cur_option:int=0
var pause_delay:float=0.0

var is_paused:bool=false
var can_pause:bool=false

var tween:=Tween.new()

onready var bg=$"BG"
onready var options=$"Options"

onready var song_label=$"Song"
onready var diff_label=$"Difficulty"

func _ready():
	add_child(tween)
	
	options_text.append("resume")
	options_text.append("restart song")
	options_text.append("settings")
	
	if OS.has_feature("editor"):
		options_text.append("skip song")
		options_text.append("edit song")
		options_text.append("edit actors")

	if Globals.can_botplay:
		options_text.append("botplay")
	
	options_text.append("exit to menu")
	
	for i in options_text.size():
		var option=ALPHABET.instance()
		option.text="/b"+options_text[i]
		option.modulate=Color.darkgray*0.5
		option.modulate.a=1.0
		options.add_child(option)
	options.position=Vector2(60,(720/2)-80)
	
	fade_out()
	on_option_changed(0)
	
func _physics_process(delta):
	pause_delay=max(pause_delay-1,0) # This is bullshit i know, but it prevends input echo when the player has the same key for both confirm and pause button.
	
	if is_paused:
		var y_input:int=int(Input.is_action_just_pressed("ui_down"))-int(Input.is_action_just_pressed("ui_up"))
		
		if Input.is_action_just_pressed("ui_accept") and pause_delay==0:
			on_option_pressed()
		
		if y_input!=0:
			on_option_changed(y_input)
		
		for opt in options.get_children(): # This shit is important to perfomance!
			if opt.global_position.y>=720+(64*4) or opt.global_position.y<-(64*4):
				opt.set_physics_process(false)
				opt.hide()
			else:
				opt.set_physics_process(true)
				opt.show()

func fade_in():
	tween.interpolate_property(song_label,"rect_position:y",10,20,0.8,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	tween.interpolate_property(diff_label,"rect_position:y",30,48,0.4,Tween.TRANS_CUBIC,Tween.EASE_OUT)

	tween.interpolate_property(song_label,"modulate:a",0.0,1.0,0.8,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	tween.interpolate_property(diff_label,"modulate:a",0.0,1.0,0.4,Tween.TRANS_CUBIC,Tween.EASE_OUT)

	tween.interpolate_property(options,"modulate:a",0.0,1.0,0.12,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	tween.interpolate_property(bg,"modulate:a",0.0,0.7,0.3,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	tween.interpolate_property(options,"position",options.position,Vector2(90-cur_option*40,(720/2)-80-cur_option*130),0.4,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	tween.start()

func fade_out():
	tween.interpolate_property(song_label,"modulate:a",1.0,0.0,0.8,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	tween.interpolate_property(diff_label,"modulate:a",1.0,0.0,0.4,Tween.TRANS_CUBIC,Tween.EASE_OUT)

	tween.interpolate_property(options,"modulate:a",0.0,0.0,0.12,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	tween.interpolate_property(bg,"modulate:a",0.7,0.0,0.3,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	tween.start()				

func pause_game():
	SoundManager.play("Musics/Breakfast",0.0,0.0,true,3.0)
	get_tree().paused=true
	is_paused=true
	pause_delay=5
	
	song_label.text=str(Globals.song).capitalize()
	diff_label.text=str(Globals.difficulty).to_upper()
	
	fade_in()

func unpause_game():
	SoundManager.stop("Musics/Breakfast")
	get_tree().paused=false
	is_paused=false
	fade_out()
	for i in options.get_children():
		i.set_physics_process(false)
		i.hide()
	
func on_option_pressed():
	match options_text[cur_option]:
		"resume":
			unpause_game()
			fade_out()
			#unpause_game()
		"restart song":
			SoundManager.stop("Musics/Breakfast")
			SceneManager.restart()
			can_pause=false
			unpause_game()
		
		"edit song":
			SoundManager.stop("Musics/Breakfast")
			SceneManager.change_to("editors/SongEditor")
			unpause_game()
			can_pause=false
		
		"edit actors":
			SoundManager.stop("Musics/Breakfast")
			SceneManager.change_to("editors/ActorEditor")
			unpause_game()
			can_pause=false
		
		"botplay":
			Status.botplay=!Status.botplay
			options.get_child(cur_option).self_modulate=Color.yellow if Status.botplay else Color.white
			Ref.health_bar.bump_score()
		
		"settings":
			SoundManager.stop("Musics/Breakfast")
			SceneManager.change_to("OptionsMenu")
			unpause_game()
			can_pause=false
			
		"skip song":
			Ref.scene.call("on_song_finished")
			SoundManager.stop("Musics/Breakfast")
			unpause_game()
			can_pause=false
		
		"exit to menu":
			SoundManager.stop("Musics/Breakfast")
			if Globals.is_storymode:
				SceneManager.change_to("StoryModeMenu")
			else:
				SceneManager.change_to("FreeplayMenu")
			unpause_game()
			can_pause=false
			
func on_option_changed(change:int=0):
	var old_option:int=cur_option
	cur_option=clamp(cur_option+change,0,options.get_child_count()-1)
	
	if cur_option!=old_option:
		SoundManager.play("MenuScroll")
	
	tween.interpolate_property(options,"position",options.position,Vector2(90-cur_option*40,(720/2)-80-cur_option*130),0.3,Tween.TRANS_CUBIC,Tween.EASE_OUT)
			
	for i in options.get_child_count():
		var opt=options.get_child(i)
		var color=Color.white if i==cur_option else (Color.darkgray*0.5)
		color.a=1.0
		if i==cur_option:
			opt.set_physics_process(true)
		else:
			opt.set_physics_process(false)
		tween.interpolate_property(opt,"position:x",opt.position.x,(i+1)*45 if i==cur_option else (i+1)*40,0.3,Tween.TRANS_CIRC,Tween.EASE_OUT)
		tween.interpolate_property(opt,"position:y",opt.position.y,(i+1)*130,0.3,Tween.TRANS_CIRC,Tween.EASE_OUT)
		tween.interpolate_property(opt,"modulate",opt.modulate,color,0.3,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	
	tween.start()
