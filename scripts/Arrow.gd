extends AnimatedAtlas

var notes:Array=[]
var column:int=0

onready var splash=$"Splash"

func _ready():
	var prefix=str(column)
	set_imageatlas("note-skins/"+Settings.note_skin+"/"+Globals.ui_skin+"/arrows")
	centered=true
	speed_scale=1.0
	
	if Settings.show_note_splashes and Globals.ui_skin!="pixel":
		splash.modulate.a=0.75
		splash.scale*=1.025
		splash.set_imageatlas("note-skins/"+Settings.note_skin+"/"+Globals.ui_skin+"/splashes")
		splash.add_animation("static","static")
		splash.add_animation("confirm-1","note impact 1 "+prefix,12)
		splash.add_animation("confirm-2","note impact 2 "+prefix,12)
		splash.set_play_next("confirm-1","static")
		splash.set_play_next("confirm-2","static")
		splash.add_offset("confirm-1",-135,-170)
		splash.add_offset("confirm-2",-135,-170)
	else:
		splash.set_physics_process(false)
		splash.hide()
	
	add_animation("static",prefix+" arrow")
	add_animation("press",prefix+" press",12)
	add_animation("confirm",prefix+" confirm",12)
	play_animation("static")
	
	set_play_next("press","static")
	set_play_next("confirm","static")
	
	if Globals.ui_skin!="pixel":
		if prefix=="down":
			add_offset("confirm",8,-2)
	else:
		scale*=8.0
		
	set_play_next("press","static")
	set_play_next("confirm","static")
	
func add_note(obj):
	add_child(obj)
	notes.append(obj)

func get_notes_path():
	return $"Notes"

func spawn_splash():
	if Settings.show_note_splashes:
		var suffix=str(int(rand_range(1,2)))
		splash.play_animation("confirm-%s"%[suffix],0)

func get_owner():
	return get_parent()
