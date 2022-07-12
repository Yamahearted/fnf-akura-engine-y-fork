extends AnimatedAtlas
class_name Actor

var actor:String=""
var icon:String="no-face"

var sing_len:int=2
var bump_at:int=1

var hp_color:Color=Color.white
var tween:=Tween.new()

func _ready():
	Conductor.connect("beat",self,"on_beat")
	Conductor.connect("bpm_changed",self,"on_bpm_changed")
	add_child(tween)
	
func set_actor(actor_name="bf"):
	var path="res://assets/actors/"+actor_name+".json"
	actor=actor_name
	clear_cache()
	
	if Globals.file_exists(path):
		var f=File.new()
		var data={}
		f.open("res://assets/actors/"+actor_name+".json",File.READ)
		data=parse_json(f.get_as_text())
		f.close()
		
		set_imageatlas(data.imageatlas)
		icon=data.icon
		hp_color=Color(data.hp_color)
		sing_len=data.sing_len
		camera_offset=Vector2(data.camera_offset.x,data.camera_offset.y)
		scale=Vector2(data.scale,data.scale) if data.has("scale") else Vector2(1,1)
		bump_at=data.bump_at if data.has("bump_at") else 1
		
		if data.flip:
			flip()
		
		for i in data.animations.keys():
			var anim_data=data.animations[i]
			add_animation(anim_data.name,anim_data.prefix,anim_data.framerate,anim_data.loop,anim_data.offset.x,anim_data.offset.y)
			set_play_next(anim_data.name,anim_data.play_next)	
			animation_reset_at_beat(anim_data.name,anim_data.reset_at_beat)
			
		play_animation(data.autoplay,0)
	
	for i in animations.keys():
		if animations[i].reset_at_beat:
			animations[i].speed=0.0
	
	if Settings.ultra_performance:
		texture=null
		#region_enabled=false
		#region_rect=Rect2()
		set_physics_process(false)
		hide()
			
func on_beat():
	var target_time:float=Conductor.crochet*Conductor.pitch_scale
	
	match actor:
		"gf","bf-dead":
			if animation in ["idle-1","idle-2"]:
				play_animation("idle-"+["1","2"][Conductor.beat_count%2],0)
	
	for i in animations.keys():
		if animations[i].reset_at_beat:
			if Conductor.beat_count%bump_at==0:
				tween.interpolate_property(
					self,"animations:"+i+":index",0,animations[i].max_frames,target_time*bump_at,Tween.TRANS_SINE,Tween.EASE_OUT
				)
				tween.start()
	
func on_bpm_changed():
	pass

func flip():
	scale.x*=-1

func get_class():
	return "Actor"
