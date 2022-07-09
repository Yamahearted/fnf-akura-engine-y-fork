extends Node2D

onready var left_fill=$"Base/Left"
onready var right_fill=$"Base/Right"
onready var label=$"Label"

func _physics_process(delta):
	var seconds:int=int(Conductor.time)%60
	var minutes:int=(int(Conductor.time)/60)%60
	var hours:int=(int(Conductor.time)/60)/60
	
	var left_minutes:int=(int(Conductor.length-Conductor.time)/60)%60
	var left_seconds:int=int(Conductor.length-Conductor.time)%60
	
	if is_instance_valid(Ref.scene):
		if Ref.scene.song_started:
			if Conductor.length>0.0 and Conductor.time>0.0:
				var time_percent=float(Conductor.time)/float(Conductor.length)
				left_fill.region_rect.size.x=lerp(left_fill.region_rect.size.x,413-(413*time_percent),0.32)
		else:
			left_fill.region_rect.size.x=413
		
	match Settings.timer_style:
		"time-elapsed":
			if is_instance_valid(Ref.scene):
				if Ref.scene.song_started:
					label.text="%s:%s"%[str(minutes).pad_zeros(2),str(seconds).pad_zeros(2)]
		"time-left":
			if is_instance_valid(Ref.scene):
				if Ref.scene.song_started:
					label.text="%s:%s"%[str(left_minutes).pad_zeros(2),str(left_seconds).pad_zeros(2)]
		"song-name":
			label.text="%s-%s"%[Globals.song,Globals.difficulty]
			
		_: # In case there's no timer to show, just disable this to avoid any performance useless usage.
			hide()
			set_physics_process(false)
			return
