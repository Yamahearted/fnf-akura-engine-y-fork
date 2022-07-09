extends Node
class_name SongEvent

func on_event(event,arg1,arg2):
	match event:
		"Hey":
			if Ref.get(arg1):
				Ref[arg1].play_animation("taunt-hey",0)
			pass
		"SkipTimeTo":
			Conductor.time=float(arg1)
			Ref.scene.inst.seek(float(arg1))
			Ref.scene.voices.seek(float(arg1))
			Status.can_take_damage=false
			#yield(get_tree(),"idle_frame")
			#Status.can_take_damage=true
			pass
		"SetCameraZoom":
			Ref.camera.zoom_to.x=float(arg1)
			Ref.camera.zoom_to.y=float(arg1)
			Ref.camera.zoom_spd=float(arg2)
			pass
		"ShakeCamera":
			pass
		"ChangeActor":
			pass
		"ChangePitch":
			Conductor.pitch_scale=float(arg1)
			pass
		"ChangeNotesSpeed":
			Globals.timescale*=float(arg1)
			pass
		"PlayAnimation":
			if Ref.get(arg1):
				Ref[arg1].play_animation(arg2,0)
			pass
		_:
			printt("Event was not found!",event,arg1,arg2)
	printt("Called event ",Conductor.time,event,arg1,arg2)
	queue_free()
