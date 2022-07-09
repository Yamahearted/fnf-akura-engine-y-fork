extends Node2D

const MOD_PANEL:PackedScene=preload("res://scenes/ModPanel.tscn")

var mods:Array=[]
var cur_mod:int=0
var images_queue_size:int=0

var has_reset:bool=false
var has_selected:bool=false

var tween:=Tween.new()

onready var title=$"Title"
onready var press_enter=$"PressEnter"
onready var press_shift=$"PressShift"
onready var mods_panels=$"Mods"
onready var arrow_left=$"ArrowLeft"
onready var arrow_right=$"ArrowRight"

onready var nomods_title=$"NoModsTitle"
onready var nomods_press_enter=$"NoModsPressEnter"

func _ready():
	add_child(tween)
	
	for i in Globals.get_mods_list():
		mods.append(i)
	
	var mods_count:int=0
	for mod in mods:
		var f:=File.new()
		var data={}
		if f.file_exists("user://mods/%s/package.json"%[mod]):
			var mod_panel:Node2D=MOD_PANEL.instance()
			mods_panels.add_child(mod_panel)
			
			f.open("user://mods/%s/package.json"%[mod],File.READ)
			data=parse_json(f.get_as_text())
			f.close()
			
			mod_panel.title.text=data.name
			mod_panel.desc.text=data.description
			mod_panel.icon.texture=load_external_tex("user://mods/%s/icon.png"%[mod])
			
			for img in Globals.get_content_in_folder("user://mods/%s/screenshots/"%[mod]):
				var img_path:String="user://mods/%s/screenshots/%s"%[mod,img]
				var tex=load_external_tex(img_path)
				mod_panel.add_image(tex)
			
			#load_external_tex()

			mods_count+=1
		
	arrow_right.scale.x*=-1
	for i in [arrow_left,arrow_right]:
		i.set_imageatlas("story-mode/arrow")
		i.add_animation("static","static")
		i.add_animation("confirm","confirm")
		i.set_play_next("confirm","static")
		i.play_animation("static")
	
	if mods.empty():
		mods_panels.hide()
		title.hide()
		press_enter.hide()
		arrow_left.hide()
		arrow_right.hide()
	else:
		nomods_press_enter.hide()
		nomods_title.hide()
	
func _physics_process(delta):
	var input_y:int=int(Input.is_action_just_pressed("ui_down"))-int(Input.is_action_just_pressed("ui_up"))
	var input_x:int=int(Input.is_action_just_pressed("ui_right"))-int(Input.is_action_just_pressed("ui_left"))
	
	if Input.is_action_just_pressed("ui_shift") and not has_reset:
		SoundManager.play("MenuConfirm")
		Settings.mod=""
		Settings.save_config()
		ProjectSettings.load_resource_pack("AkuraEngine.pck", true)
		has_reset=true
		yield(get_tree().create_timer(0.8),"timeout")
		SceneManager.change_to("Startup")
		
	if Input.is_action_just_pressed("ui_accept") and not has_reset:
		if !mods.empty() and not has_selected:
			SoundManager.play("MenuConfirm")
			Settings.mod=mods[cur_mod]
			Settings.save_config()
			has_selected=true
			yield(get_tree().create_timer(0.8),"timeout")
			#get_tree().quit()
			ModsManager.load_mods()
			SceneManager.change_to("TitleScreen")
		elif mods.empty() and not has_selected:
			SoundManager.play("MenuConfirm")
			OS.shell_open(OS.get_user_data_dir()+"/mods/")
			has_selected=true
			yield(get_tree().create_timer(0.5),"timeout")
			has_selected=false
		
	if Input.is_action_just_pressed("ui_cancel") and not has_selected:
		SoundManager.play("MenuCancel")
		has_selected=true
		yield(get_tree().create_timer(0.8),"timeout")
		SceneManager.change_to("MainOptionsMenu")
		
	if has_selected:
		var alpha_index:int=int(OS.get_ticks_msec()/60)%2
		if not mods.empty():
			press_enter.modulate.a=[0.0,1.0][alpha_index]
		else:
			nomods_press_enter.modulate.a=[0.0,1.0][alpha_index]
	else:
		press_enter.modulate.a=1.0
		nomods_press_enter.modulate.a=1.0
	
	if has_reset:
		var alpha_index:int=int(OS.get_ticks_msec()/60)%2
		press_shift.modulate.a=[0.0,1.0][alpha_index]
		
	if input_x!=0 and not mods.empty():
		var old_mod:int=cur_mod
		var arrow:Object=[arrow_left,arrow_right][clamp(input_x,0,1)]
		arrow.play_animation("confirm",0)
		cur_mod=clamp(cur_mod+input_x,0,mods.size()-1)
		if cur_mod!=old_mod:
			var old_mod_panel:Node2D=mods_panels.get_child(old_mod)
			old_mod_panel.hide()
			
			var mod_panel:Node2D=mods_panels.get_child(cur_mod)
			mod_panel.show()
			
			SoundManager.play("MenuScroll")
			
func load_external_tex(path):
	var f:=File.new()
	f.open(path,File.READ)
	var bytes=f.get_buffer(f.get_len())
	var img=Image.new()
	var data=img.load_png_from_buffer(bytes)
	var imgtex=ImageTexture.new()
	imgtex.create_from_image(img)
	f.close()
	return imgtex
