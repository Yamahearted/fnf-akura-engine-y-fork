extends Node2D

const ALPHABET:PackedScene=preload("res://scenes/Alphabet.tscn")
const INTRO_TEXTS:Array=[
	"text number one",
	"text number two",
	"text number three"
]

var is_started:bool=false
var is_skipped:bool=false
var beat_count:int=0

var tween:=Tween.new()

onready var flash_rect=$"Flash/Rect"
onready var strings=$"Strings"
onready var newgrounds_logo=$"NewgroundsLogo"
onready var press_enter=$"PressEnter"
onready var logo=$"Logo"
onready var gf=$"GF"

func _ready():
	add_child(tween)
	
	SceneManager.animations.play("fade-out")
	Ref.scene=self
	
	Conductor.reset()
	Conductor.connect("beat",self,"on_beat")
	Conductor.set_bpm(102)
	
	SoundManager.play("Musics/FreakyMenu")
	Conductor.audio_player=SoundManager.get_node("Musics/FreakyMenu")
	
	gf.hide()
	logo.hide()
	newgrounds_logo.hide()
	press_enter.hide()
	flash_rect.hide()
	
	logo.set_imageatlas("title-screen/logo")
	logo.add_animation("bump","logo bumpin",24,false,-894/2,-670/2)
	logo.animation_reset_at_beat("bump")
	logo.play_animation("bump")
	
	press_enter.set_imageatlas("title-screen/press-enter")
	press_enter.add_animation("idle","Press Enter to Begin",24,true,-1495/2,-79/2)
	press_enter.add_animation("pressed","ENTER PRESSED",24,true,-1495/2,-79/2)
	press_enter.play_animation("idle")
	
	gf.set_imageatlas("title-screen/gf")
	gf.add_animation("idle-1","gfDance2 ",24,false,-717/2,-648)
	gf.add_animation("idle-2","gfDance1 ",24,false,-717/2,-648)
	
	#gf.add_animation_by_indices("idle-2","gfDance",[15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28],24,false,-717/2,-648)
	gf.animation_reset_at_beat("idle-1")
	gf.animation_reset_at_beat("idle-2")
	gf.play_animation("idle-1")

	Conductor.paused=false
	
func _physics_process(delta):
	if Input.is_action_just_pressed("ui_accept") and is_skipped and not is_started:
		SoundManager.play("MenuConfirm")
		is_started=true
		press_enter.play_animation("pressed")
		tween.interpolate_property(flash_rect,"modulate:a",1.0,0.0,1.4,Tween.TRANS_CUBIC,Tween.EASE_OUT)
		tween.start()
		yield(get_tree().create_timer(1.0),"timeout")
		SceneManager.change_to("MainOptionsMenu")
	
	if Input.is_action_just_pressed("ui_accept") and !is_skipped:
		skip_intro()
	
func on_beat():
	var target_time:float=Conductor.crochet*Conductor.pitch_scale
	
	for a in [gf,logo]:
		for i in a.animations.keys():
			if a.animations[i].reset_at_beat:
				if Conductor.beat_count%1==0:
					tween.interpolate_property(
						a,"animations:"+i+":index",0,a.animations[i].max_frames,target_time,Tween.TRANS_SINE,Tween.EASE_OUT
					)
					tween.start()
	
	gf.play_animation("idle-"+["1","2"][beat_count%2])
	
	if is_skipped:
		beat_count+=1
		return
	
	match beat_count:
		1:
			#Transition.fade_out()
			add_string("/bNINJAMUFFIN99")
			add_more_string("/bPHANTOMARCADE")
			add_more_string("/bKAWAISPRITE")
			add_more_string("/bEVILSK8ER")
		
		3:
			add_more_string("/bPRESENT")
		4:
			clear_strings();
		5:
			add_string("/bIN ASSOCIATION")
			add_more_string("/bWITH")
		7:
			add_more_string("/bIN NEWGROUNDS")
			newgrounds_logo.show()
			yield(get_tree(),"idle_frame")
			strings.position.y-=180
			#newgrounds_logo.show()
		8:
			newgrounds_logo.hide()
			clear_strings()
		9:
			randomize()
			var i=int(rand_range(0,INTRO_TEXTS.size()))
			add_string("/b"+str(INTRO_TEXTS[i]).to_upper())
		11:
			randomize()
			var i=int(rand_range(0,INTRO_TEXTS.size()))
			add_more_string("/b"+str(INTRO_TEXTS[i]).to_upper())
		12:
			clear_strings();
		13:
			add_string("/b FRIDAY")
		14:
			add_more_string("/b NIGHT")
		15:
			add_more_string("/b FUNKIN")
		16:
			skip_intro()
			pass
			#skip_intro()
	
	beat_count+=1

func skip_intro():
	if !is_skipped:
		clear_strings()
		strings.hide()
		newgrounds_logo.hide()
		flash_rect.show()
		tween.interpolate_property(flash_rect,"modulate:a",1.0,0.0,4.5,Tween.TRANS_CUBIC,Tween.EASE_OUT)
		tween.start()
		yield(get_tree().create_timer(0.05),"timeout")
		gf.show()
		logo.show()
		press_enter.show()
		is_skipped=true

func add_string(text):
	var string=ALPHABET.instance()
	string.text=text
	strings.add_child(string)
	yield(get_tree(),"idle_frame") # This will give time enough to set and get the string width
	if is_instance_valid(string):
		string.position=Vector2((1280/2)-(string.width/2)+26,(720/2)-50*2)

func add_more_string(text):
	add_string(text)
	yield(get_tree(),"idle_frame")
	var height=((strings.get_child_count()-1)*(44*2))
	for i in strings.get_child_count():
		var string=strings.get_child(i)
		if is_instance_valid(string):
			string.position.y=((720/2)-44*2)+(i*44*2)
	strings.position.y=0-height/2
	
func clear_strings():
	strings.position.y=0
	for i in strings.get_children():
		i.queue_free()		
