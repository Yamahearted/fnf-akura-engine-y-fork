extends AnimatedAtlas

var arrow:AnimatedAtlas

var time:float=0.0
var pressed_time:float=0.0
var must_hit:bool=true
var column:int=0

var is_spawned:bool=false
var is_sustain:bool=false
var is_held:bool=false
var is_pressed:bool=false
var is_missed:bool=false

var max_length:float=0.0
var length:float=0.0

onready var slider_group=$"Slider"
onready var slider_mid=$"Slider/Middle"
onready var slider_end=$"Slider/End"

func _ready():
	is_sustain=max_length>0.0
	slider_group.visible=is_sustain
	slider_group.modulate.a*=0.7
	slider_group.show_behind_parent=true
	centered=true
	
	var prefix=str(column)
	set_imageatlas("note-skins/"+Settings.note_skin+"/"+Globals.ui_skin+"/notes")
	add_animation("static",prefix)
	play_animation("static")
	
	if is_sustain:
		for i in [slider_mid,slider_end]:
			i.set_imageatlas("note-skins/"+Settings.note_skin+"/"+Globals.ui_skin+"/sliders")
			i.add_animation("static",prefix+(" hold piece" if i==slider_mid else " hold end"))
			i.play_animation("static")
			if Globals.ui_skin!="pixel":
				i.add_offset("static",-51/2.0,0)
			else:
				i.add_offset("static",-3.5,0)
				
	slider_mid.hide()
	slider_end.hide()
	slider_group.hide()
	slider_mid.set_physics_process(false)
	slider_end.set_physics_process(false)
	slider_group.set_physics_process(false)
	slider_update()
	
func slider_update():
	if is_sustain:
		var mid_height=44 if Globals.ui_skin!="pixel" else 6
		slider_group.visible=length>0.0
		slider_group.scale.y=1.0 if !Settings.down_scroll else -1.0
		slider_mid.scale.y=(1.0/mid_height)*(length*Globals.timescale*Conductor.pitch_scale*(1.0 if Globals.ui_skin!="pixel" else 0.1))
		
		slider_end.position.y=(length*Globals.timescale*Conductor.pitch_scale*(1.0 if Globals.ui_skin!="pixel" else 0.1))
		
		slider_mid.scale.y=max(slider_mid.scale.y,0.0)
		
		slider_end.position.y=max(slider_end.position.y,0)
		
func clear_cache():
	.clear_cache()
	if is_sustain:
		for i in [slider_mid,slider_end]:
			i.texture=null
			i.atlas=[]
			i.animations={}
			i.animation=""

func set_physics_process(toggle:bool):
	.set_physics_process(toggle)
	if is_sustain:
		slider_mid.set_physics_process(toggle)
		slider_end.set_physics_process(toggle)
		slider_group.set_process(toggle)
		slider_group.set_physics_process(toggle)

func show():
	visible=true
	if is_sustain:
		slider_group.show()
		slider_mid.show()
		slider_end.show()

func hide():
	visible=false
	if is_sustain:
		slider_group.hide()
		slider_mid.hide()
		slider_end.hide()
	
func on_pressed():
	var actor=Ref.bf if arrow.get_owner().is_player else Ref.dad
	var sing_animation="sing-"+["left","down","up","right"][int(column)] if actor.scale.x>0 else "sing-"+["right","down","up","left"][int(column)]
	
	if not arrow.get_owner().is_player:
		if Settings.animate_enemy_arrows:
			arrow.play_animation("confirm",0)
	else:
		arrow.play_animation("confirm",0)
	
	actor.play_animation(sing_animation,0)
	
	if arrow.get_owner().is_player:
		var rating=get_rating()
		Status.combo+=1
		Status.rating=rating
		Status.score+=get_score_points(rating)
		Status.add_hp(get_healing_value(rating))
		Status.total_hit=min(Status.total_hit+get_accuracy(),Status.total_notes+1)
		Status.total_notes+=1
		Status[get_rating()+"s"]+=1
		Status.pressed_ms=(time-pressed_time)
		Ref.combo.spawn()
		Ref.health_bar.bump_score()
		
		if rating=="sick":
			arrow.spawn_splash()
		
func on_held():
	var actor=Ref.bf if arrow.get_owner().is_player else Ref.dad
	var sing_animation="sing-"+["left","down","up","right"][int(column)] if actor.scale.x>0 else "sing-"+["right","down","up","left"][int(column)]
	
	if not arrow.get_owner().is_player:
		if Settings.animate_enemy_arrows:
			arrow.play_animation("confirm",-1)
	else:
		arrow.play_animation("confirm",-1)
	
	if actor.animation!=sing_animation:
		actor.play_animation(sing_animation,0)
		
	if actor.get_current_frame()>actor.sing_len:
		actor.seek_animation(sing_animation,0)
	
	if arrow.get_current_frame()>2:
		arrow.seek_animation("confirm",0)
	
	if arrow.get_owner().is_player:
		Status.score+=1
		Status.add_hp(0.1)
		Status.total_hit=min(Status.total_hit+0.001,Status.total_notes)
		Ref.health_bar.bump_score()
		
func on_missed():
	var actor=Ref.bf if arrow.get_owner().is_player else Ref.dad
	var miss_animation="miss-"+["left","down","up","right"][int(column)] if actor.scale.x>0 else "miss-"+["right","down","up","left"][int(column)]
	if arrow.get_owner().is_player and Status.can_take_damage:
		Status.combo=0
		Status.misses+=1
		Status.total_notes+=1
		Status.rating=""
		Status.score-=10
		Status.subtract_hp(5)
		if is_instance_valid(Ref.scene):
			Ref.scene.drown_out_song()
		Ref.health_bar.bump_score()
		Ref.combo.spawn(true)
		actor.play_animation(miss_animation,0)
		
		
func on_missing():
	var actor=Ref.bf if arrow.get_owner().is_player else Ref.dad
	var miss_animation="miss-"+["left","down","up","right"][int(column)] if actor.scale.x>0 else "miss-"+["right","down","up","left"][int(column)]
	if arrow.get_owner().is_player and Status.can_take_damage:
		Status.combo=0
		Status.subtract_hp(0.2)
		Status.score-=0.1
		Status.total_hit=max(Status.total_hit-0.001,0.0)
		if actor.animation!=miss_animation:
			actor.play_animation(miss_animation,0)
		if is_instance_valid(Ref.scene):
			Ref.scene.drown_out_song(false)
		
func get_rating():
	var ms=abs(time-pressed_time)
	var rating="shit"
	if ms<0.17:
		rating="shit"
	if ms<0.12:
		rating="bad"
	if ms<0.08:
		rating="good"
	if ms<0.04:
		rating="sick"
	return rating

func get_accuracy():
	var ms=abs(time-pressed_time)
	var percent=0.0
	if ms<0.17:
		percent=0.0
	if ms<0.12:
		percent=0.3
	if ms<0.08:
		percent=0.8
	if ms<0.04:
		percent=1.0
	return percent

func get_score_points(rating):
	var points=0
	match rating:
		"shit":
			points=1
		"bad":
			points=3
		"good":
			points=5
		"sick":
			points=10
	return points

func get_healing_value(rating):
	var heal=0
	match rating:
		"shit":
			heal=0
		"bad":
			heal=2
		"good":
			heal=4
		"sick":
			heal=6
	return heal
