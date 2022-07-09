extends Sprite
class_name AnimatedAtlas

signal animation_finished
signal animation_changed

var atlas:Array=[]
var animations:Dictionary={}
var animation:String=""
var paused:bool=false
var speed_scale:float=1.0
var size:Vector2
var camera_offset:Vector2
var flip_x:bool=false
var can_play_next:bool=true

func _ready():
	region_enabled=true
	region_filter_clip=true
	centered=false
	
func _physics_process(_delta):
	if animation in animations.keys():
		var anim=animation
		var loop=animations[anim]["loop"]
		var index=animations[anim]["index"]
		var speed=animations[anim]["speed"]
		var max_frames=animations[anim]["max_frames"]
		var play_next=animations[anim]["play_next"]
		if index+speed>max_frames and loop:
			index=0
		elif index+speed>max_frames and !loop:
			index=max_frames
			emit_signal("animation_finished")
			if play_next!="":
				if anim==animation and can_play_next and animation!=play_next:
					play_animation(play_next)
		index+=speed*(0 if paused else speed_scale)
		animations[anim]["index"]=clamp(index,0,max_frames)
	
	if animation in animations.keys():
		var index=floor(animations[animation]["index"])
		var frame_data=animations[animation]["frames"][index]
		region_rect=frame_data.region
		offset=(-frame_data.position/(2 if centered else 1))+(animations[animation]["offset"])-size
	else:
		region_rect=Rect2()
		offset=Vector2()

func add_animation(anim_name:String,prefix:String,framerate:int=24,loop:bool=false,offset_x=0,offset_y=0,play_next="",reset_at_beat=false):
	if atlas.size()>0:
		animations[anim_name]={}
		animations[anim_name]["name"]=anim_name
		animations[anim_name]["prefix"]=prefix
		animations[anim_name]["index"]=0
		animations[anim_name]["max_frames"]=0
		animations[anim_name]["loop"]=loop
		animations[anim_name]["framerate"]=framerate*2
		animations[anim_name]["offset"]=Vector2(offset_x,offset_y)
		animations[anim_name]["frames"]=[]
		animations[anim_name]["speed"]=((framerate*2)/60.0)
		animations[anim_name]["play_next"]=play_next
		animations[anim_name]["reset_at_beat"]=reset_at_beat
		
		for f in atlas:
			if str(f.name).begins_with(prefix):
				var frame_data={
					"position":Vector2(f.frameX,f.frameY),
					"region":Rect2(f.x,f.y,f.width,f.height)
				}
				animations[anim_name]["frames"].append(frame_data)
		
		animations[anim_name]["max_frames"]=animations[anim_name]["frames"].size()-1

func add_animation_by_indices(anim_name:String,prefix:String,indices:Array=[0],framerate=24,loop=false,offset_x=0,offset_y=0,play_next="",reset_at_beat=false):
	if atlas.size()>0:
		animations[anim_name]={}
		animations[anim_name]["name"]=anim_name
		animations[anim_name]["prefix"]=prefix
		animations[anim_name]["index"]=0
		animations[anim_name]["max_frames"]=0
		animations[anim_name]["loop"]=loop
		animations[anim_name]["framerate"]=framerate
		animations[anim_name]["offset"]=Vector2(offset_x,offset_y)
		animations[anim_name]["frames"]=[]
		animations[anim_name]["speed"]=(framerate/30.0)
		animations[anim_name]["play_next"]=play_next
		animations[anim_name]["reset_at_beat"]=reset_at_beat
		
		var target_frames:Array=[]
		
		for f in atlas:
			if str(f.name).begins_with(prefix):
				var frame_data={
					"position":Vector2(f.frameX,f.frameY),
					"region":Rect2(f.x,f.y,f.width,f.height)
				}
				target_frames.append(frame_data)
		
		for i in indices:
			animations[anim_name]["frames"].append(target_frames[i])
		
		animations[anim_name]["max_frames"]=animations[anim_name]["frames"].size()-1
	
func remove_animation(anim_name):
	animations.erase(anim_name)

func get_animation_length(anim_name=animation):
	if anim_name in animations.keys():
		return animations[anim_name]["max_frames"]
	return 1
	
func add_offset(anim_name,x,y):
	if anim_name in animations.keys():
		animations[anim_name]["offset"]+=Vector2(x,y)

func set_play_next(anim_name,next_name):
	if anim_name in animations.keys():
		animations[anim_name]["play_next"]=next_name

func set_animation_speed(anim_name,spd=0.3):
	if anim_name in animations.keys():
		animations[anim_name]["speed"]=spd

func play_animation(anim_name,index=0):
	if anim_name in animations.keys():
		animation=anim_name
		if index!=-1:
			animations[anim_name]["index"]=clamp(index,0,animations[animation]["max_frames"])
		emit_signal("animation_changed")

func get_frame_region(anim_name=animation,index=0):
	if anim_name in animations.keys():
		return animations[anim_name]["frames"][clamp(index,0,animations[anim_name]["max_frames"])]["region"]
	return Rect2()

func get_anim_offset(anim_name):
	if anim_name in animations.keys():
		return animations[anim_name]["offset"]
	return Vector2()

func seek_animation(anim_name=animation,index=0):
	if anim_name in animations.keys():
		animations[anim_name]["index"]=index

func get_current_frame(anim_name=animation):
	if anim_name in animations.keys():
		return animations[anim_name]["index"]
	return 0

func set_imageatlas(path):
	var data=AtlasParser.open(path)
	texture=data.texture
	atlas=data.atlas

func animation_reset_at_beat(anim_name,enable=true):
	if anim_name in animations.keys():
		animations[anim_name]["reset_at_beat"]=enable

func clear_cache():
	texture=null
	atlas=[]
	animations={}
	region_rect=Rect2()
	animation=""

func get_class():
	return "AnimatedAtlas"
