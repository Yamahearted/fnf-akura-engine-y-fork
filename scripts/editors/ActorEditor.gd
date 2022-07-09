extends Node2D

var cur_animation=0
var camera_offset={"x":0,"y":0}

onready var world=get_node("World")
onready var actor=get_node("World/Actor")
onready var ghost=get_node("World/Ghost")

onready var menu={
	"actor":{
		"name":get_node("UI/Tabs/Actor/Name"),
		"icon_name":get_node("UI/Tabs/Actor/IconName"),
		"imageatlas_name":get_node("UI/Tabs/Actor/ImageAtlasName"),
		"hp_color":get_node("UI/Tabs/Actor/HpColor"),
		"sing_len":get_node("UI/Tabs/Actor/SingLen"),
		"flip":get_node("UI/Tabs/Actor/Flip"),
		"autoplay_name":get_node("UI/Tabs/Actor/AutoplayName")
	},
	"animations":{
		"name":get_node("UI/Tabs/Animations/Name"),
		"prefixes":get_node("UI/Tabs/Animations/Prefixes"),
		"framerate":get_node("UI/Tabs/Animations/Framerate"),
		"loop":get_node("UI/Tabs/Animations/Loop"),
		"play_next":get_node("UI/Tabs/Animations/PlayNext"),
		"reset_at_beat":get_node("UI/Tabs/Animations/ResetAtBeat")
	}
}
onready var hpbar=get_node("Hpbar")
onready var icon=get_node("Icon")
onready var offsets_label=get_node("UI/OffsetsLabel")

func _ready():
	SoundManager.play("Musics/Breakfast",0.0,0.0,true,3.0)
	Ref.scene=self
	
	actor.position=Vector2()
	actor.can_play_next=false
	ghost.can_play_next=false
	
	for i in [menu.actor.name,menu.actor.autoplay_name,menu.actor.icon_name,menu.actor.imageatlas_name,menu.actor.sing_len.get_line_edit(),menu.animations.name,menu.animations.framerate.get_line_edit(),menu.animations.play_next ]:
		i.connect("mouse_entered",i,"grab_focus")
		i.connect("mouse_exited",i,"release_focus")

func _input(event):
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("mb_right") and not Input.is_action_pressed("ui_ctrl"):
			world.position+=event.relative
		
		if Input.is_action_pressed("mb_left") and Input.is_action_pressed("ui_ctrl"):
			actor.add_offset(actor.animation,event.relative.x*(1.0/world.scale.x),event.relative.y*(1.0/world.scale.y))
		
		if Input.is_action_pressed("mb_right") and Input.is_action_pressed("ui_ctrl"):
			camera_offset.x+=event.relative.x*(1.0/world.scale.x)
			camera_offset.y+=event.relative.y*(1.0/world.scale.x)
			
			#actor.
			#world.position+=event.relative
		
	if event is InputEventMouseButton:
		var wheel_dir=int(event.button_index==BUTTON_WHEEL_DOWN)-int(event.button_index==BUTTON_WHEEL_UP)
		world.scale+=Vector2(wheel_dir,wheel_dir)*0.032
		for i in ["x","y"]:
			world.scale[i]=max(world.scale[i],0.1)
	
func _process(delta):
	var offset_input=Vector2(
		int(Input.is_action_just_pressed("ui_right"))-int(Input.is_action_just_pressed("ui_left")),
		int(Input.is_action_just_pressed("ui_down"))-int(Input.is_action_just_pressed("ui_up"))
	)

	if offset_input.length()!=0:
		var input_spd=12 if Input.is_action_pressed("ui_shift") else 1
		if !actor.atlas.empty() and !actor.animations.empty():
			actor.add_offset(actor.animation,offset_input.x*input_spd,offset_input.y*input_spd)
	
	if Input.is_action_just_pressed("ui_cancel"):
		SoundManager.stop("Musics/Breakfast")
		SceneManager.change_to(Ref.previous_scene_name)
	
	if Input.is_action_just_pressed("ui_tab"):
		ghost.animations=actor.animations.duplicate(true)
		ghost.animation=actor.animation
		ghost.animations[ghost.animation].offset=actor.animations[actor.animation].offset
		ghost.seek_animation(actor.animation,0)
	
	if actor.flip_x!=menu.actor.flip.pressed:
		actor.flip_x=menu.actor.flip.pressed
		actor.scale.x*=-1.0
	
	ghost.scale=actor.scale
	
	offsets_label.text=""
	if !actor.animation.empty() and !actor.atlas.empty():
		for i in actor.animations.keys():
			var anim_offset=actor.animations[i].offset
			offsets_label.text+=str(
				"  " if actor.animations[i].name==actor.animation else "",
				i," (",anim_offset.x,",",anim_offset.y,")\n"
			)
	else:
		offsets_label.text="No animations or atlas loaded yet!"
	
	update()

func _draw():
	# Origin point
	draw_line(Vector2(world.position.x,world.position.y-8),Vector2(world.position.x,world.position.y+8),Color.white,3)
	draw_line(Vector2(world.position.x-8,world.position.y),Vector2(world.position.x+8,world.position.y),Color.white,3)
	
	# Camera offset point
	draw_line(
		Vector2(
			world.position.x + (camera_offset.x*world.scale.x),
			world.position.y + (camera_offset.y*world.scale.y) -8
		),
		Vector2(
			world.position.x + (camera_offset.x*world.scale.x),
			world.position.y + (camera_offset.y*world.scale.y) +8
		),
		Color.red,3
	)
	draw_line(
		Vector2(
			world.position.x + (camera_offset.x*world.scale.x)-8,
			world.position.y + (camera_offset.y*world.scale.y)
		),
		Vector2(
			world.position.x + (camera_offset.x*world.scale.x)+8,
			world.position.y + (camera_offset.y*world.scale.y)
		),
		Color.red,3
	)
	
func save_actor():
	var f=File.new()
	var anims_to_save={}
	for i in actor.animations.keys():
		var anim_data=actor.animations[i]
		anims_to_save[i]={}
		anims_to_save[i]["name"]=anim_data.name
		anims_to_save[i]["prefix"]=anim_data.prefix
		anims_to_save[i]["framerate"]=anim_data.framerate
		anims_to_save[i]["play_next"]=anim_data.play_next
		anims_to_save[i]["offset"]={"x":anim_data.offset.x,"y":anim_data.offset.y}
		anims_to_save[i]["loop"]=anim_data.loop
		anims_to_save[i]["reset_at_beat"]=anim_data.reset_at_beat
	
	var data={
		"name":menu.actor.name.text,
		"icon":menu.actor.icon_name.text,
		"flip":menu.actor.flip.pressed,
		"autoplay":menu.actor.autoplay_name.text,
		"sing_len":menu.actor.sing_len.value,
		"imageatlas":menu.actor.imageatlas_name.text,
		"hp_color":menu.actor.hp_color.color.to_html(false),
		"animations":anims_to_save,
		"camera_offset":camera_offset
	}
	f.open("res://assets/actors/"+menu.actor.name.text+".json",File.WRITE)
	f.store_string(to_json(data))
	f.close()
	printt("Actor saved!","actors/"+data.name)
	
func load_actor():
	var path="res://assets/actors/"+menu.actor.name.text+".json"
	
	var f=File.new()
	var data={}
	f.open(path,File.READ)
	data=parse_json(f.get_as_text())
	f.close()
	
	menu.actor.name.text=data.name
	menu.actor.icon_name.text=data.icon
	menu.actor.sing_len.value=data.sing_len
	menu.actor.flip.pressed=data.flip
	menu.actor.autoplay_name.text=data.autoplay
	menu.actor.imageatlas_name.text=data.imageatlas
	menu.actor.hp_color.color=Color(data.hp_color)
	camera_offset=data.camera_offset
	
	import_imageatlas()
	
	for i in data.animations.keys():
		var anim_data=data.animations[i]
		actor.add_animation(anim_data.name,anim_data.prefix,anim_data.framerate,anim_data.loop,anim_data.offset.x,anim_data.offset.y)
		actor.set_play_next(anim_data.name,anim_data.play_next)
		actor.animation_reset_at_beat(anim_data.name,anim_data.reset_at_beat)
		
	if !actor.animations.empty():
		actor.play_animation(actor.animations.keys()[0])
	
	on_iconname_changed(menu.actor.icon_name.text)
	on_hpcolor_changed(menu.actor.hp_color.color)
	on_actor_animation_changed()
	
	printt("Actor Loaded!","actors/"+data.name)

func import_imageatlas():
	menu.animations.prefixes.clear()
	
	actor.clear_cache()
	actor.set_imageatlas(menu.actor.imageatlas_name.text)
	
	ghost.clear_cache()
	ghost.set_imageatlas(menu.actor.imageatlas_name.text)
	
	var prefixes=[]
	for f in actor.atlas:
		var prefix=str(f.name).left(len(f.name)-3)
		if !prefix in prefixes:
			prefixes.append(prefix)
			menu.animations.prefixes.add_item(prefix)
	
func create_animation():
	var anim_name=menu.animations.name.text
	if len(anim_name)>0:
		if !actor.atlas.empty():
			var previous_offset=Vector2()
			if anim_name in actor.animations.keys():
				previous_offset=actor.animations[anim_name].offset
				actor.remove_animation(anim_name)
			actor.add_animation(
				anim_name,
				menu.animations.prefixes.text,
				menu.animations.framerate.value,
				menu.animations.loop.pressed
			)
			actor.add_offset(anim_name,previous_offset.x,previous_offset.y)
			actor.animations[anim_name].reset_at_beat=menu.animations.reset_at_beat.pressed
			
			if len(menu.animations.play_next.text)>0:
				actor.set_play_next(anim_name,menu.animations.play_next.text)

			cur_animation=actor.animations.keys().size()-1
			ghost.animations=actor.animations.duplicate(true)
			actor.play_animation(anim_name,0)
			for i in actor.animations.keys().size():
				if actor.animations.keys()[i]==anim_name:
					cur_animation=i
					break

func on_actor_animation_changed():
	var anim_data=actor.animations[actor.animation]
	
	for i in menu.animations.prefixes.get_item_count():
		if menu.animations.prefixes.get_item_text(i)==anim_data.prefix:
			menu.animations.prefixes.select(i)
			break
	
	menu.animations.loop.pressed=anim_data.loop
	menu.animations.reset_at_beat.pressed=anim_data.reset_at_beat
	menu.animations.framerate.value=anim_data.framerate
	menu.animations.name.text=anim_data.name
	menu.animations.play_next.text=anim_data.play_next

func play_actor_previous_animation():
	if !actor.animations.empty() and !actor.atlas.empty():
		cur_animation=clamp(cur_animation-1,0,actor.animations.keys().size()-1)
		var anim_name=actor.animations.keys()[cur_animation]
		actor.play_animation(anim_name,0)
		on_actor_animation_changed()
		
func play_actor_next_animation():
	if !actor.animations.empty() and !actor.atlas.empty():
		cur_animation=clamp(cur_animation+1,0,actor.animations.keys().size()-1)
		var anim_name=actor.animations.keys()[cur_animation]
		actor.play_animation(anim_name,0)
		on_actor_animation_changed()

func on_iconname_changed(icon_name):
	var path="res://assets/images/icons/"+icon_name+".png"
	icon.texture=load(path) if Globals.file_exists(path) else load("res://assets/images/icons/face.png")
	
func on_hpcolor_changed(color):
	hpbar.modulate=color

