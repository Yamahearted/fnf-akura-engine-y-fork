extends Node2D

var retried:bool=true

onready var camera=$"Camera"
onready var actor=$"Actor"
onready var sounds={
	"retry":$"Sounds/Retry",
	"dies":$"Sounds/Dies"
}
onready var music=$"Music"

func _ready():
	actor.connect("animation_changed",self,"on_actor_animation_changed")
	sounds.dies.play()
	
	match Temp.data.player.name:
		_:
			actor.set_actor("bf-dead")
			actor.global_position=Temp.data.player.global_position
			actor.scale=Temp.data.player.scale
			
	camera.move_to=Temp.data.camera.global_position
	camera.global_position=Temp.data.camera.global_position
	camera.zoom_to=Temp.data.camera.zoom
	camera.zoom=Temp.data.camera.zoom
	camera.offset=Temp.data.camera.offset
	camera.offset_to=Temp.data.camera.offset
	camera.zoom_spd=1.2
	yield(get_tree().create_timer(0.3),"timeout")
	camera.move_to=actor.global_position
	camera.offset_to=actor.camera_offset
	yield(get_tree().create_timer(0.3),"timeout")
	camera.zoom_to=Vector2(0.8,0.8)
	
func _process(delta):
	if !Conductor.paused:
		var time=music.get_playback_position()+AudioServer.get_time_since_last_mix()
		time-=AudioServer.get_output_latency()
		Conductor.time=time if time>Conductor.time else Conductor.time
	
	if Input.is_action_just_pressed("ui_accept") and actor.animation in ["idle-1","idle-2"] and  retried:
		Conductor.paused=true
		retried=false
		sounds.retry.play()
		music.stop()
		actor.play_animation("confirm",0)
		yield(get_tree().create_timer(2.0),"timeout")
		SceneManager.change_to("Gameplay")
		Status.reset()
		Temp.clear()
		
func on_actor_animation_changed():
	if actor.animation=="idle-1" and !music.playing:
		music.play()
		Conductor.reset()
		Conductor.paused=false

func on_music_finished():
	if !Conductor.paused:
		Conductor.time=0.0
		music.play()
