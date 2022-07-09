extends Node

var tween:=Tween.new()

func _ready():
	add_child(tween)

func play(snd_name:String,start:float=0.0,target_volume:float=0.0,fade:bool=false,fade_duration:float=1.0):
	var snd:AudioStreamPlayer=get_node(snd_name)
	snd.play(start)
	snd.seek(start)
	if fade:
		tween.interpolate_property(snd,"volume_db",-80,target_volume,fade_duration,Tween.TRANS_CUBIC,Tween.EASE_OUT)
		tween.start()
	else:
		snd.volume_db=target_volume
	
func stop(snd_name:String,fade:bool=false,fade_duration:float=1.0):
	var snd:AudioStreamPlayer=get_node(snd_name)
	var time:float=get_time(snd_name)
	if fade:
		tween.interpolate_property(snd,"volume_db",snd.volume_db,-80,fade_duration,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	else:
		snd.stop()
	return time

func get_time(snd_name:String):
	return get_node(snd_name).get_playback_position()

func is_playing(snd_name:String):
	return get_node(snd_name).playing
