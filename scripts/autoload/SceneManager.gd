extends Node

signal scene_changed
signal scene_restarted

onready var animations=$"Animations"

func change_to(scene_name:String,use_transition:bool=true,delay=0.0,speed:float=2.0):
	var path:String="res://scenes/%s.tscn"%[scene_name]
	if Ref.scene!=null:
		Ref.previous_scene_name=Ref.scene.name
	Ref.scene=null
	if use_transition:
		yield(get_tree().create_timer(delay),"timeout")
		fade_in(speed)
		yield(animations,"animation_finished")
	get_tree().change_scene(path)==OK
	yield(get_tree(),"idle_frame")
	if use_transition:
		fade_out(speed)
	emit_signal("scene_changed")
	Ref.scene=get_tree().current_scene

func restart(use_transition:bool=true,delay:float=0.0,speed=2.0):
	if Ref.scene!=null:
		Ref.previous_scene_name=Ref.scene.name
	Ref.scene=null
	if use_transition:
		yield(get_tree().create_timer(delay),"timeout")
		fade_in(speed)
		yield(animations,"animation_finished")
	get_tree().reload_current_scene()
	yield(get_tree(),"idle_frame")
	Ref.scene=get_tree().current_scene
	emit_signal("scene_restarted")
	if use_transition:
		fade_out(speed)

func fade_in(spd:float=2.0):
	animations.play("fade-in")
	animations.playback_speed=spd
	
func fade_out(spd:float=2.0):
	animations.play("fade-out")
	animations.playback_speed=spd
