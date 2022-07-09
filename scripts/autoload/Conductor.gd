extends Node

signal beat
signal bpm_changed

var audio_player:AudioStreamPlayer

var time:float=0.0
var length:float=0.0

var bpm:int=100
var crochet:float=(60.0/bpm)
var step_crochet:float=crochet/4.0
var pitch_scale:float=1.0

var beat:bool=false
var paused:bool=true
var beat_count:int=0


func _physics_process(delta):
	if !paused:
		if is_instance_valid(audio_player):
			var track_time=audio_player.get_playback_position()+AudioServer.get_time_since_last_mix()
			track_time-=AudioServer.get_output_latency()
			time=track_time if track_time>time else time
			length=audio_player.stream.get_length()
			if time>=length-0.1 and audio_player.is_playing() and track_time<time:
				time=0.0
			
	if (fmod(abs(time+Settings.ms_offset/1000.0),crochet)<=crochet/2.0 and beat):
		beat=false;
		beat_count+=1;
		emit_signal("beat");
	elif (fmod(abs(time+Settings.ms_offset/1000.0),crochet)>crochet/2.0):
		beat=true;
	
	#pitch_scale=1.0
		
func set_bpm(bpm):
	self.bpm=bpm
	crochet=(60.0/bpm)
	step_crochet=crochet/4.0
	emit_signal("beat")
	emit_signal("bpm_changed");
	print("Bpm changed: ",bpm)

func reset():
	set_bpm(100)
	beat=false
	paused=true
	beat_count=0
	pitch_scale=1.0
	time=0.0
	length=0.0
