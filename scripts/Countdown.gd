extends Sprite

signal countdown_finished

var sprites:Array=[]
var sounds:Array=[]

var bump_force:float=1.05
var visible_time:float=0.0
var beat_count:int=0
var counting:bool=true
var scale_to:float=0.7
var play_sound:bool=true

onready var sound=$"Sound"

func on_ready():
	if Globals.ui_skin=="pixel":
		scale_to=4.0
	
	for i in range(3,-1,-1):
		sprites.append(load("res://assets/images/ui-skins/%s/countdown-skins/%s/%s.png"%[Globals.ui_skin,Settings.countdown_skin,i]))
	
	if Globals.ui_skin=="pixel":
		sounds=[
			preload("res://assets/sounds/intro-3-pixel.ogg"),
			preload("res://assets/sounds/intro-2-pixel.ogg"),
			preload("res://assets/sounds/intro-1-pixel.ogg"),
			preload("res://assets/sounds/intro-go-pixel.ogg")
		]
	else:
		sounds=[
			preload("res://assets/sounds/intro-3.wav"),
			preload("res://assets/sounds/intro-2.wav"),
			preload("res://assets/sounds/intro-1.wav"),
			preload("res://assets/sounds/intro-go.wav")
		]
	
func _physics_process(delta):
	var speed=1.0/(((Conductor.bpm*Conductor.pitch_scale)/60.0)/60);
	visible_time=lerp(visible_time,0.0,3/speed)
	modulate.a=clamp(visible_time,0.0,1.0)
	for i in ["x","y"]:
		scale[i]=lerp(scale[i],scale_to,0.1)

func on_beat():
	if !counting:
		return
	visible_time=3
	modulate.a=1.0
	scale*=bump_force
	texture=sprites[beat_count]
	sound.stream=sounds[min(beat_count,sounds.size()-1)]
	
	if beat_count<Globals.countdown_max and play_sound:
		sound.play()
	beat_count+=1
	if beat_count>=Globals.countdown_max and counting:
		emit_signal("countdown_finished")
		counting=false
