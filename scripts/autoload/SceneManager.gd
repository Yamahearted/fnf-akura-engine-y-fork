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
		animations.playback_speed=speed
		animations.play("fade-in")
		yield(animations,"animation_finished")
	get_tree().change_scene(path)==OK
	yield(get_tree(),"idle_frame")
	if use_transition:
		animations.play("fade-out")
	emit_signal("scene_changed")
	Ref.scene=get_tree().current_scene

func restart(use_transition:bool=true,delay:float=0.0,speed=2.0):
	if Ref.scene!=null:
		Ref.previous_scene_name=Ref.scene.name
	Ref.scene=null
	if use_transition:
		yield(get_tree().create_timer(delay),"timeout")
		animations.playback_speed=speed
		animations.play("fade-in")
		yield(animations,"animation_finished")
	get_tree().reload_current_scene()
	yield(get_tree(),"idle_frame")
	Ref.scene=get_tree().current_scene
	emit_signal("scene_restarted")
	if use_transition:
		animations.play("fade-out")
