extends Node2D

var possible_options:PoolStringArray=["storymode","freeplay","donate","options"]

var cur_option:int=0
var has_selected:bool=false
var has_left:bool=false

var tween:=Tween.new()

onready var version_label=$"UI/VersionLabel"
onready var options=$"Options"
onready var bg=$"BG"

func _ready():
	add_child(tween)
	bg.scale*=1.15
	
	if Settings.allow_mods and Globals.allow_mods:
		possible_options.append("mods")
	
	version_label.text="AküraEngine %s | Made on Godot engine."%[Globals.ENGINE_VERSION]
	
	if not SoundManager.is_playing("Musics/FreakyMenu"):
		SoundManager.play("Musics/FreakyMenu")
	
	for i in possible_options.size():
		var prefix:String=possible_options[i]
		var opt:=AnimatedAtlas.new()
		opt.set_imageatlas("main-options/%s"%[prefix])
		opt.add_animation("static",prefix+" basic0",24,true)
		opt.add_animation("selected",prefix+" white0",8,true,-80 if prefix!="mods" else -20)
		opt.play_animation("static")
		opt.position.x=1280/2-opt.get_frame_region("static",0).size.x/2
		opt.position.y=i*180
		opt.centered=true
		options.add_child(opt)

	on_option_changed()
	
func _physics_process(delta):
	var input_y:int=int(Input.is_action_just_pressed("ui_down"))-int(Input.is_action_just_pressed("ui_up"))
	
	if Input.is_action_just_pressed("ui_cancel") and not has_left and not has_selected:
		SoundManager.play("MenuCancel")
		SceneManager.change_to("TitleScreen")
		has_left=true
	
	if Input.is_action_just_pressed("ui_accept") and not has_selected:
		SoundManager.play("MenuConfirm")
		has_selected=true
		yield(get_tree().create_timer(0.8),"timeout")
		match possible_options[cur_option]:
			"storymode":
				SceneManager.change_to("StoryModeMenu")
			"freeplay":
				SceneManager.change_to("FreeplayMenu")
			"donate":
				OS.shell_open("https://ninja-muffin24.itch.io/funkin")
				yield(get_tree().create_timer(0.2),"timeout")
				has_selected=false
			"options":
				SceneManager.change_to("OptionsMenu")
			"mods":
				SceneManager.change_to("ModsMenu")
			
	if input_y!=0 and not has_selected:
		on_option_changed(input_y)
	
	if has_selected:
		var option:AnimatedAtlas=options.get_child(cur_option)
		var color_index:int=int(OS.get_ticks_msec()/80)%2
		option.modulate=[Color.white,Color.transparent][color_index]
	else:
		var option:AnimatedAtlas=options.get_child(cur_option)
		option.modulate=Color.white
	
	
func on_option_changed(change:int=0):
	var old_option:int=cur_option
	cur_option=clamp(cur_option+change,0,possible_options.size()-1)
	
	if old_option!=cur_option:
		SoundManager.play("MenuScroll")
		
	for i in options.get_child_count():
		options.get_child(i).play_animation("selected" if i==cur_option else "static")
	
	
	tween.interpolate_property(options,"position:y",options.position.y,720/2 - cur_option*180,0.6,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	tween.interpolate_property(bg,"position:y",bg.position.y,360 - cur_option*180/32.0 - 8,0.6,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	
	
	
	tween.start()
	
	
	
