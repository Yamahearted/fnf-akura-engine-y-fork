extends Node2D

const ALPHABET:PackedScene=preload("res://scenes/Alphabet.tscn")

var cur_option:int=0
var cur_input_slot:int=0
var cur_list_slot:int=0

var options_y:int=0
var options_list:Array=[]

var can_map:bool=true
var is_mapping:bool=false
var can_move:bool=true

var tween:=Tween.new()

onready var sections=$"Sections"
onready var subtitles=$"UI/Subtitles"
onready var subtitles_label=$"UI/Subtitles/Label"
onready var mapping_menu=$"UI/MappingMenu"
onready var bg=$"BG"

func _ready():
	sections.scale*=0.8
	subtitles_label.text="Press SHIFT+DEL to revert all settings to default. Press SHIFT+END to reset all your keybinds to default.\nPress R to clear the current keybind."
	bg.modulate=Color("ab4eba")#Color.lightseagreen
	mapping_menu.hide()
	
	add_child(tween)

	add_section("Gameplay")
	add_option("Down-scroll","","down_scroll")
	add_option("Middle-scroll","","middle_scroll")
	add_option("Ghost-tapping","You won't take any damage if any key pressed and there's no notes in range","ghost_tapping")
	add_option("Disable blueballed button","","disable_blueballed_button")
	add_option("Move camera with sing animation","","move_camera_with_actor")
	add_option("Black bars for pixel ui","","blackbars_pixelui")
	add_option("Ms-offset","","ms_offset","spinbox",[0,500])
	
	
	add_section("Graphics")
	add_option("Low Quality","Recommended to keep it low for lowendpcs.","low_quality")
	add_option("Ultra performance","Recommended to keep it low for lowendpcs.","ultra_performance")
	add_option("Anti-Aliasing","May increase performance by sharper visuals.","antialiasing")
	add_option("Framerate","","framerate","spinbox",[1,1000])
	
	add_section("UI Settings")
	add_option("Note Splashes","","show_note_splashes")
	add_option("Hide UI","","hide_ui")
	add_option("Flashing Lights","","show_flashing_lights")
	add_option("Bump camera","","bump_camera_at_beats")
	add_option("Show combo text","","show_combo_text")
	add_option("Show input ms","","show_note_ms")
	add_option("Show fps counter","","show_fps_counter")
	add_option("Show advanced debug","","advanced_debug")
	add_option("Show enemy notes","","show_enemy_notes")
	add_option("Animate enemy arrows","","animate_enemy_arrows")
	add_option("Update checker","","update_checker")
	add_options_offset()
	add_option("Note Skin","","note_skin","list",Settings.note_skins)
	add_option("Countdown Skin","","countdown_skin","list",Settings.countdown_skins)
	add_option("Timer style","","timer_style","list",Settings.timer_styles)
	
	add_section("Keybinds Notes")
	add_option("Left","","note_0","input")
	add_option("Down","","note_1","input")
	add_option("Up","","note_2","input")
	add_option("Right","","note_3","input")
	
	add_section("Keybinds UI")
	add_option("Left","","ui_left","input")
	add_option("Down","","ui_down","input")
	add_option("Up","","ui_up","input")
	add_option("Right","","ui_right","input")
	add_options_offset(90)
	add_option("Accept","","ui_accept","input")
	add_option("Cancel","","ui_cancel","input")
	add_option("Reset","","ui_reset","input")
	add_option("Pause","","ui_pause","input")
	add_options_offset(90)
	add_option("Vol-up","","ui_volume_add","input")
	add_option("Vol-down","","ui_volume_sub","input")
	
	on_option_changed()
	
func _physics_process(delta):
	var input_y:int=int(Input.is_action_just_pressed("ui_down"))-int(Input.is_action_just_pressed("ui_up"))
	var input_x:int=int(Input.is_action_just_pressed("ui_right"))-int(Input.is_action_just_pressed("ui_left"))
	
	mapping_menu.visible=is_mapping
	
	if input_y!=0 and !is_mapping and can_move:
		on_option_changed(input_y)
	
	if Input.is_action_pressed("ui_shift"):
		if Input.is_action_just_pressed("ui_delete"):
			Settings.reset_all()
		elif Input.is_action_just_pressed("ui_end"):
			Settings.reset_keybinds()
		
	if Input.is_action_just_pressed("ui_cancel") and !is_mapping and can_move:
		SceneManager.change_to(Ref.previous_scene_name)
		SoundManager.play("MenuCancel")
		can_move=false
	
	if Input.is_action_just_pressed("ui_reset") and !is_mapping:
		match options_list[cur_option][1]:
			"input":
				var action:String=options_list[cur_option][2]
				Settings.keybinds[action][cur_input_slot]=KEY_UNKNOWN
				update_current_option(0)
				Settings.save_config()
				Settings.load_config()
				
			"spinbox":
				var key:String=options_list[cur_option][2]
				var limits:Array=options_list[cur_option][5]
				Settings.set(key,limits[0])
				update_current_option(0)
				
		
	if Input.is_action_just_pressed("ui_accept") and !is_mapping:
		var opt:Node2D=options_list[cur_option][3]
		var type:String=options_list[cur_option][1]
		var key=options_list[cur_option][2]
		match type:
			"bool":
				var checkbox:AnimatedAtlas=opt.get_children().back()
				Settings.set(key,not Settings.get(key))
				checkbox.play_animation("static" if not Settings.get(key) else "confirm",0)
				if Settings.get(key)==true:
					SoundManager.play("MenuConfirm")
				else:
					SoundManager.play("MenuCancel")
					
			"input":
				if can_map:
					is_mapping=true
					can_map=false
					can_move=false
					SoundManager.play("MenuConfirm")
								
		Settings.save_config()
		
	if input_x!=0 and !is_mapping and can_move:
		update_current_option(input_x)
	
	for i in options_list.size(): # This shit is important to perfomance!
		var opt:Node2D=options_list[i][3]
		if opt.global_position.y>=720+(64*4) or opt.global_position.y<-(64*4):
			opt.set_physics_process(false)
			opt.hide()
		else:
			opt.set_physics_process(true)
			opt.show()
	
func _input(event):
	if event is InputEventKey and not event.echo:
		if is_mapping and event.is_pressed():
			var action=options_list[cur_option][2]
			Settings.keybinds[action][cur_input_slot]=event.scancode
			Settings.save_config()
			Settings.load_config()
			is_mapping=false
			update_current_option()
			yield(get_tree().create_timer(0.1),"timeout")
			can_map=true
			can_move=true
			
func update_current_option(change:int=0):
	var opt:Node2D=options_list[cur_option][3]
	var title:String=options_list[cur_option][0]
	var type:String=options_list[cur_option][1]
	var key:String=options_list[cur_option][2]
	var extra:Array=options_list[cur_option][5]
	
	match type:
		"spinbox":
			var old_value=Settings.get(key)
			
			var arrows:Array=[opt.get_children()[opt.get_child_count()-1],opt.get_children()[opt.get_child_count()-2]]
			arrows[clamp(-change+1,0,1)].play_animation("confirm",0)
			
			var spd=1 if not Input.is_action_pressed("ui_shift") else 100
			Settings.set(key,clamp(Settings.get(key)+(change*spd),extra[0],extra[1]))
			opt.text=str("   ",title+"   ",Settings.get(key))
			Settings.save_config()
		
			if Settings.get(key)!=old_value:
				SoundManager.play("MenuScroll")
			
		"list":
			var prev_slot=cur_list_slot
			var arrows:Array=[opt.get_children()[opt.get_child_count()-1],opt.get_children()[opt.get_child_count()-2]]
			cur_list_slot=clamp(cur_list_slot+change,0,extra.size()-1)
			arrows[clamp(-change+1,0,1)].play_animation("confirm",0)
			
			if cur_list_slot!=prev_slot:
				SoundManager.play("MenuScroll")
			
			Settings.set(key,extra[cur_list_slot])
			opt.text=str("   ",title+"   ",Settings.get(key))
			Settings.save_config()
		
		"input":
			var inputs:Node2D=opt.get_children().back()
			cur_input_slot=clamp(cur_input_slot+change,0,1)
			inputs.text=str("/c6" if cur_input_slot==1 else "/c0",OS.get_scancode_string(Settings.keybinds[key][0]),"  ","/c6" if cur_input_slot==0 else "/c0",OS.get_scancode_string(Settings.keybinds[key][1]))
			
		
func add_option(text:String,info:String,variable:String,type:String="bool",data:Array=[]):
	var options:Node2D=sections.get_children().front()
	var opt:Node2D=ALPHABET.instance()
	var value=Settings.get(variable)
	options.add_child(opt)
	opt.position.y=options_y
	opt.position.x+=120
	opt.text=str("   ",text,"   ",value) if type=="spinbox" or type=="list" else str("   "+text)
	add_options_offset(90)
	
	match type:
		"bool":
			var checkbox:=AnimatedAtlas.new()
			opt.add_child(checkbox)
			checkbox.set_imageatlas("checkbox")
			checkbox.add_animation("static","back to idle",24,false,-6,-22)
			checkbox.add_animation("confirm","confirm",24,false,-10,-32)
			checkbox.play_animation("static" if not value else "confirm")
			checkbox.position.y-=18
			checkbox.scale*=0.7
		"input":
			var inputs:Node2D=ALPHABET.instance()
			opt.text=str("   ",text)
			opt.add_child(inputs)
			inputs.position.x=56*12
			inputs.text=str("/c0",OS.get_scancode_string(Settings.keybinds[variable][0]),"  /c6",OS.get_scancode_string(Settings.keybinds[variable][1]))
			
		"spinbox","list":
			var arrows:Array=[AnimatedAtlas.new(),AnimatedAtlas.new()]
			for i in arrows:
				i.set_imageatlas("story-mode/arrow")
				i.add_animation("static","static")
				i.add_animation("confirm","confirm")
				i.set_play_next("confirm","static")
				i.play_animation("static")
				i.position.y+=56
				opt.add_child(i)
			arrows[0].position.x+=49
			arrows[1].position.x=(len(text+" ")*49)+24
			arrows[1].scale.x=-1
			
	options_list.append([text,type,variable,opt,opt.global_position.y,data])
		
func add_section(text:String,bold:bool=true):
	var title:Node2D=ALPHABET.instance()
	var section:=Node2D.new()
	sections.add_child(section)
	section.add_child(title)
	if sections.get_child_count()!=1:
		add_options_offset(90)
	title.text=("/b" if bold else "")+text
	title.position.x=160
	title.position.y=options_y
	add_options_offset(120)
	
func on_option_changed(change:int=0):
	var prev_option=cur_option
	cur_list_slot=0
	cur_option+=change #clamp(cur_option+change,0,options_list.size()-1)
	
	if cur_option!=prev_option:
		SoundManager.play("MenuScroll")
	
	if cur_option<0:
		cur_option=options_list.size()-1
	elif cur_option>options_list.size()-1:
		cur_option=0

	tween.interpolate_property(sections,"global_position:y",sections.global_position.y,-options_list[cur_option][4]+240,0.32,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	
	for i in options_list.size():
		var opt:Node2D=options_list[i][3]
		tween.interpolate_property(opt,"position:x",opt.position.x,160 if i==cur_option else 138,0.3,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	
	tween.start()
	
	if options_list[cur_option][1]=="input":
		var opt:Node2D=options_list[cur_option][3]
		var key:String=options_list[cur_option][2]
		var inputs:Node2D=opt.get_children().back()
		inputs.text=str("/c6" if cur_input_slot==1 else "/c0",OS.get_scancode_string(Settings.keybinds[key][0]),"  ","/c6" if cur_input_slot==0 else "/c0",OS.get_scancode_string(Settings.keybinds[key][1]))
				
	
	
func add_options_offset(amount:int=56):
	options_y+=amount
