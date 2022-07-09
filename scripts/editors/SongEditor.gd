extends Node2D

const VCR_FONT:DynamicFont=preload("res://assets/fonts/vcr.tres")
const GRID_SIZE:int=40

var zoom_list:PoolRealArray=[0.25,0.5,1,2,3,4,6,8,12,16,24]

var basic_events:PoolStringArray=[
	" ",
	"Hey",
	"SkipTimeTo",
	"SetCameraZoom",
	"PlayAnimation",
	"ChangePitch"
]
var events_desc:Dictionary={
	" ":"",
	"Hey":"Plays the 'taunt-hey' animation\nArg1 = Actor name\n",
	"SkipTimeTo":"This is a debug feature so expect to activate the imortal mode when used.\nArg1 = Time to skip to",
	"SetCameraZoom":"Arg1 = Zoom value\nArg2 = Duration in secs",
	"PlayAnimation":"Arg1 = Actor name\nArg2 = Animation to play",
	"ChangePitch":"Arg1 = New song's pitch value"
}

var event_image:Texture=preload("res://assets/images/event-arrow.png")
var note_atlas:=AnimatedAtlas.new()

var strum_time:float=0.0
var strumline_y:float=0.0

var cur_section:int=0
var cur_note:int=-1
var cur_zoom:int=2
var cur_event:int=-1
var cur_subevent:int=0

var show_tabs:bool=true
var auto_scroll:bool=true
var last_section:int=0

var mouse_snap:=Vector2(1,1)

var chart:Dictionary={
	"name":"",
	"difficulty":"easy",
	"bpm":100,
	"speed":1.0,
	"sections":[],
	"dad":"dad",
	"bf":"bf",
	"gf":"gf",
	"stage":"Stage",
	"ui_skin":"base",
	"arrows_count":4
}
var copied_section:Dictionary

var tween:=Tween.new()

onready var inst=$"Inst"
onready var voices=$"Voices"
onready var camera=$"Camera"

onready var icons=$"Icons"
onready var icon_bf=$"Icons/Bf"
onready var icon_dad=$"Icons/Dad"
onready var icon_event=$"Icons/Event"
onready var conductor_label=$"UI/ConductorLabel"

onready var tabs={
	"parent":$"UI/Tabs",
	"song":{
		"name":$"UI/Tabs/Song/Name",
		"difficulty":$"UI/Tabs/Song/Difficulty",
		"bf":$"UI/Tabs/Song/Boyfriend",
		"gf":$"UI/Tabs/Song/Girlfriend",
		"dad":$"UI/Tabs/Song/Dad",
		"stage":$"UI/Tabs/Song/Stage",
		"ui_skin":$"UI/Tabs/Song/UISkin",
		"bpm":$"UI/Tabs/Song/Bpm",
		"speed":$"UI/Tabs/Song/Speed"
	},
	"section":{
		"bpm":$"UI/Tabs/Section/Bpm",
		"length":$"UI/Tabs/Section/Length",
		"must_hit":$"UI/Tabs/Section/MustHit",
		"change_bpm":$"UI/Tabs/Section/ChangeBpm",
		"section_to_copy":$"UI/Tabs/Section/SectionToCopy"
	},
	"note":{
		"type":$"UI/Tabs/Note/Type",
		"time":$"UI/Tabs/Note/Time",
		"length":$"UI/Tabs/Note/Length",
	},
	"event":{
		"type":$"UI/Tabs/Event/Type",
		"arg1":$"UI/Tabs/Event/Arg1",
		"arg2":$"UI/Tabs/Event/Arg2",
		"manual_label":$"UI/Tabs/Event/Manual/Label",
		"slot_label":$"UI/Tabs/Event/SlotLabel"
	}
}

func _ready():
	Conductor.connect("bpm_changed",self,"on_bpm_changed")
	Conductor.reset()
	Conductor.audio_player=inst
	
	add_child(tween)
	add_child(note_atlas)
	note_atlas.set_physics_process(false)
	note_atlas.hide()
	
	for i in [tabs.song.bpm,tabs.song.speed,tabs.section.bpm,tabs.section.length,tabs.note.time,tabs.note.length,tabs.event.arg1,tabs.event.arg2]:
		if i.get_class()=="SpinBox":
			i=i.get_line_edit()
		i.connect("mouse_entered",i,"grab_focus")
		i.connect("mouse_exited",i,"release_focus")
	
	for i in basic_events:
		tabs.event.type.add_item(i)
	
	for i in Globals.get_actor_list():
		tabs.song.bf.add_item(i)
		tabs.song.gf.add_item(i)
		tabs.song.dad.add_item(i)
	
	for i in Globals.get_difficulties_list():
		tabs.song.difficulty.add_item(i)
	
	for i in Globals.get_song_list():
		tabs.song.name.add_item(i)
	
	for i in Globals.get_stage_list():
		tabs.song.stage.add_item(i)
	
	for i in Globals.get_ui_skins_list():
		tabs.song.ui_skin.add_item(i)
	
	for i in Globals.get_note_type_list():
		tabs.note.type.add_item(i)
	
	for i in tabs.song.name.get_item_count():
		if tabs.song.name.get_item_text(i)==Globals.song:
			tabs.song.name.select(i)
			break
	
	for i in tabs.song.difficulty.get_item_count():
		if tabs.song.difficulty.get_item_text(i)==Globals.difficulty:
			tabs.song.difficulty.select(i)
			break
		
	load_song()

	camera.offset.x=-1280/2+(4*2*GRID_SIZE)/2
	camera.use_tween=false

	note_atlas.set_imageatlas("note-skins/"+Settings.note_skin+"/"+Globals.ui_skin+"/notes")
	note_atlas.add_animation("0","0");
	note_atlas.add_animation("1","1");
	note_atlas.add_animation("2","2");
	note_atlas.add_animation("3","3");
	
	for i in [icon_bf,icon_dad]:
		for a in ["x","y"]:
			i.scale[a]=(1.0/150)*64
		i.hframes=2
	
	icon_event.texture=event_image
	icon_event.position.x=-20
	for a in ["x","y"]:
		icon_event.scale[a]=(1.0/128)*40
	
	icons.position.y=-50
	
	while get_section_start(chart.sections.size()-1)<Conductor.length:
		add_section()
	
	Conductor.set_bpm(chart.bpm)
	
func _input(event):
	if Conductor.paused and !Input.is_action_pressed("ui_ctrl"):
		if event is InputEventMouseButton:
			var wheel_direction=int(event.button_index==BUTTON_WHEEL_DOWN)-int(event.button_index==BUTTON_WHEEL_UP)
			Conductor.time=clamp(Conductor.time+((Conductor.step_crochet/2.0)*wheel_direction),0.0,Conductor.length)
	
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("mb_right"):
			camera.offset+=-event.relative*camera.zoom

		
func _process(_delta):
	cur_zoom=clamp(cur_zoom+(int(Input.is_action_just_pressed("ui_x"))-int(Input.is_action_just_pressed("ui_z"))),0,zoom_list.size()-1)
	
	mouse_snap=Vector2(
		get_local_mouse_position().x-GRID_SIZE/2,
		get_local_mouse_position().y-GRID_SIZE/2
		
	).snapped(Vector2(GRID_SIZE,GRID_SIZE if !Input.is_action_pressed("ui_shift") else 1))
	
	if !Conductor.paused:
		var time=inst.get_playback_position()+AudioServer.get_time_since_last_mix()
		time-=AudioServer.get_output_latency()
		Conductor.time=time if time>Conductor.time else Conductor.time
	
	if Input.is_action_just_pressed("ui_tab"):
		auto_scroll=!auto_scroll
		printt("auto_scroll: ",auto_scroll)
		
	if Input.is_action_just_pressed("ui_cancel"):
		Globals.song=tabs.song.name.text
		Globals.difficulty=tabs.song.difficulty.text
		SceneManager.change_to("Gameplay")

		
	if Input.is_action_just_pressed("ui_space"):
		Conductor.paused=!Conductor.paused
		if Conductor.paused:
			if inst.stream!=null:
				inst.stop()
			if voices.stream!=null:
				voices.stop()
		else:
			if inst.stream!=null:
				inst.play(Conductor.time)
			if voices.stream!=null:
				voices.play(Conductor.time)
	
	if Conductor.time>=Conductor.length-0.01:
		Conductor.time=0.0
		Conductor.paused=true
		inst.stop()
		voices.stop()
		cur_section=0
	
	if Conductor.paused:
		if Input.is_action_just_pressed("ui_right"):
			cur_section+=1
			Conductor.time=get_section_start(cur_section)
			update_section_tab()
			cur_note=-1
			cur_event=-1
			cur_subevent=0
			
		elif Input.is_action_just_pressed("ui_left"):
			cur_section-=1
			Conductor.time=get_section_start(cur_section)
			update_section_tab()
			cur_note=-1
			cur_event=-1
			cur_subevent=0
				
		cur_section=clamp(cur_section,0,chart.sections.size()-1);
	
	if cur_section!=get_section_id(Conductor.time) and auto_scroll:
		cur_section=get_section_id(Conductor.time)
		cur_note=-1
		cur_event=-1
		cur_subevent=0

		while get_section_start(chart.sections.size()-1)<Conductor.length:
			add_section()
		
		var section_data:Dictionary=chart.sections[cur_section]
		var da_bpm:int=chart.bpm
		
		if section_data.change_bpm:
			da_bpm=section_data.bpm
			
		Conductor.set_bpm(da_bpm)
		update_section_tab()
	
	if Input.is_action_just_pressed("mb_left"):
		if mouse_can_place_notes():
			place_note(get_strum_time(mouse_snap.y),int(mouse_snap.x/GRID_SIZE))
		if mouse_can_place_events():
			place_event(get_strum_time(mouse_snap.y))
	
	chart.name=tabs.song.name.text
	chart.difficulty=tabs.song.difficulty.text
	chart.bf=tabs.song.bf.text
	chart.gf=tabs.song.gf.text
	chart.dad=tabs.song.dad.text
	chart.stage=tabs.song.stage.text
	chart.ui_skin=tabs.song.ui_skin.text
	
	icon_dad.texture=Globals.get_actor_icon(tabs.song.dad.text)
	icon_dad.position.x=((4*2*GRID_SIZE)/2)+4/2*GRID_SIZE if chart.sections[cur_section].must_hit else 4/2*GRID_SIZE

	icon_bf.texture=Globals.get_actor_icon(tabs.song.bf.text)
	icon_bf.position.x=((4*2*GRID_SIZE)/2)+4/2*GRID_SIZE if not chart.sections[cur_section].must_hit else 4/2*GRID_SIZE
	
	strum_time=fmod(Conductor.time-get_section_start(cur_section),Conductor.step_crochet*chart.sections[cur_section].length_in_steps)
	strumline_y=get_strum_y(strum_time if auto_scroll else Conductor.time-get_section_start(cur_section))
	camera.position.y=strumline_y
	
	conductor_label.text="%s/%s\nSection: %s"%[stepify(Conductor.time,0.01),stepify(Conductor.length,0.01),cur_section]
	
	update()
	
func _draw():
	for x in range(-1,4*2):
		for y in (16*4)*get_chart_zoom():
			var grid_color=[Color("d9d5d5"),Color("e7e6e6")][(x+y)%2]
			if y+1>chart.sections[cur_section].length_in_steps*get_chart_zoom():
				grid_color*=0.8
			if y+1>(chart.sections[cur_section].length_in_steps+chart.sections[cur_section+1].length_in_steps)*get_chart_zoom():
				grid_color*=0.8
			draw_rect(
				Rect2(x*GRID_SIZE,y*GRID_SIZE,GRID_SIZE,GRID_SIZE),
				grid_color
			)
	
	for i in range(1,4):
		var beatline_y=get_strum_y(Conductor.step_crochet*i*4)
		draw_line(
			Vector2(-GRID_SIZE,beatline_y),
			Vector2(4*2*GRID_SIZE,beatline_y),
			Color(Color.crimson.r,Color.crimson.g,Color.crimson.b,0.5),2
		)
	
	for i in range(0,2):
		var section_offset_y=(chart.sections[cur_section+i].length_in_steps*GRID_SIZE if i>0 else 0)*get_chart_zoom()
		
		for event in chart.sections[cur_section+i].events:
			var event_color=Color.white
			
			if get_strum_y(event[0])+section_offset_y<strumline_y:
				event_color*=0.64
				event_color.a=1.0
			
			if cur_event!=-1:
				if chart.sections[cur_section].events[cur_event]==event:
					var mult=abs(cos(OS.get_ticks_msec()/800.0))
					event_color=Color.white*(1.0+(mult*0.55))
					event_color*=0.64
					event_color.a=1
			
			draw_texture_rect_region(
				event_image,
				Rect2(
					-1*GRID_SIZE,get_strum_y(event[0])+section_offset_y,
					GRID_SIZE,GRID_SIZE
				),
				Rect2(0,0,128,128),
				event_color
			)
			
			var subevents_count=event[1].size()
			draw_string(
				VCR_FONT,
				Vector2(
					(-1*GRID_SIZE+20)-str(subevents_count).length()*6.5,
					(get_strum_y(event[0])+section_offset_y+16)+(GRID_SIZE/2)-10
				),
				str(subevents_count)
			)
		
		for note in chart.sections[cur_section+i].notes:
			var note_color=Color.white

			if get_strum_y(note[0])+section_offset_y<strumline_y:
				note_color*=0.64
				note_color.a=1.0
			
			if cur_note!=-1:
				if chart.sections[cur_section].notes[cur_note]==note:
					var mult=abs(sin(OS.get_ticks_msec()/800.0))
					note_color=Color.white*(1.0+(mult*0.55))
					note_color*=0.64
					note_color.a=1
		
			draw_texture_rect_region(
				note_atlas.texture,
				Rect2(
					note[1]*GRID_SIZE,get_strum_y(note[0])+section_offset_y,
					GRID_SIZE,GRID_SIZE
				),
				note_atlas.get_frame_region(str(int(note[1])%4),0),
				note_color
			)
			
			var notetype_nmb:String=str(get_note_type_number(note[3])) if note[3]!=" " else ""
			draw_string(
				VCR_FONT,
				Vector2(
					(note[1]*GRID_SIZE+20)-str(notetype_nmb).length()*5,
					(get_strum_y(note[0])+section_offset_y+16)+(GRID_SIZE/2)-10
				),
				str(notetype_nmb)
			)
			
			if note[2]>0.0:
				var slider_dist=Math.distance(0,get_strum_y(note[0])+GRID_SIZE/2+section_offset_y,0,strumline_y)
				draw_line(
					Vector2(note[1]*GRID_SIZE+GRID_SIZE/2,round(get_strum_y(note[0])+section_offset_y+GRID_SIZE/2)),
					Vector2(note[1]*GRID_SIZE+GRID_SIZE/2,round(get_strum_y(note[0]+note[2])+GRID_SIZE/2+section_offset_y)),

					Color.dimgray*0.4,8.0
				)
				if strumline_y>=get_strum_y(note[0])+section_offset_y+GRID_SIZE/2:
					draw_line( 
						Vector2(note[1]*GRID_SIZE+GRID_SIZE/2,round(get_strum_y(note[0])+section_offset_y+GRID_SIZE/2)),
						Vector2(note[1]*GRID_SIZE+GRID_SIZE/2,
						round(clamp(
							get_strum_y(note[0])+section_offset_y+slider_dist,
							get_strum_y(note[0])+section_offset_y,
							get_strum_y(note[0]+note[2])+section_offset_y
						))+GRID_SIZE/2),
						Color.white,8.0
					)
		
	draw_line(
		Vector2(-GRID_SIZE,strumline_y),
		Vector2(4*2*GRID_SIZE,strumline_y),
		Color.white,4
	)
	
	if mouse_can_place_notes() or mouse_can_place_events():
#		draw_rect(
#			Rect2(mouse_snap.x,mouse_snap.y,GRID_SIZE,GRID_SIZE),
#			Color.white,true
#		)
		var cursor_color:=Color(1,1,1,0.4)
		if mouse_can_place_notes():
			draw_texture_rect_region(
				note_atlas.texture,
				Rect2(mouse_snap.x,mouse_snap.y,GRID_SIZE,GRID_SIZE),
				note_atlas.get_frame_region(str(int(mouse_snap.x/GRID_SIZE)%4),0),
				cursor_color
			)
		elif mouse_can_place_events():
			draw_texture_rect_region(
				event_image,
				Rect2(mouse_snap.x,mouse_snap.y,GRID_SIZE,GRID_SIZE),
				Rect2(0,0,128,128),
				cursor_color
			)
	
	for i in 2:
		var sep_x=i*(GRID_SIZE*4)
		draw_line(
			Vector2(sep_x,0),
			Vector2(sep_x,(16*GRID_SIZE*4)*get_chart_zoom()),
			Color.black,2
		)

func save_song():
	var song_path:String="res://assets/songs/"+tabs.song.name.text+"/"+tabs.song.difficulty.text+".json"
	var f:=File.new()
	f.open(song_path,File.WRITE)
	f.store_string(to_json(chart))
	f.close()
	printt("Chart saved at: ",song_path)

func load_song(song_name=tabs.song.name.text,difficulty=tabs.song.difficulty.text):
	var song_path:String="res://assets/songs/"+song_name+"/"
	var f=File.new()
	f.open(song_path+difficulty+".json",File.READ)
	chart=parse_json(f.get_as_text())
	f.close()
	
	inst.stream=load(song_path+"Inst.ogg") if ResourceLoader.exists(song_path+"Inst.ogg") else null
	voices.stream=load(song_path+"Voices.ogg") if ResourceLoader.exists(song_path+"Voices.ogg") else null
	Conductor.length=inst.stream.get_length() if inst.stream!=null else 0.0
	
	for i in tabs.song.name.get_item_count():
		if tabs.song.name.get_item_text(i)==chart.name:
			tabs.song.name.select(i)
			break
			
	cur_section=0
	update_song_tab()
	update_section_tab()
		
func place_note(time=0.0,column=0,length=0.0,type=tabs.note.type.text,auto_delete=true):
	var data:Array=[time,column,length,type]
	var exists:int=-1
	for i in chart.sections[cur_section].notes.size():
		var n=chart.sections[cur_section].notes[i]
		if round(get_strum_y(n[0]))==round(get_strum_y(data[0])) and n[1]==data[1]:
			exists=i
			break
	if exists==-1:
		chart.sections[cur_section].notes.append(data)
		print(chart.sections[cur_section].notes.size())
		cur_note=chart.sections[cur_section].notes.size()-1
		update_note_tab()
		return
	else:
		if !Input.is_action_pressed("ui_ctrl") and auto_delete:
			chart.sections[cur_section].notes.remove(exists)
			cur_note=-1
			return
		else:
			cur_note=exists
			update_note_tab()
			return

func place_event(time=0.0):
	var data:Array=[time,[[tabs.event.type.text,tabs.event.arg1.text,tabs.event.arg2.text]]]
	var exists:int=-1
	for i in chart.sections[cur_section].events.size():
		var e=chart.sections[cur_section].events[i]
		if round(get_strum_y(e[0]))==round(get_strum_y(data[0])):
			exists=i
			break
	if exists==-1:
		chart.sections[cur_section].events.append(data)
		cur_event=chart.sections[cur_section].events.size()-1
		cur_subevent=0
		update_event_tab()
	else:
		if !Input.is_action_pressed("ui_ctrl"):
			chart.sections[cur_section].events.remove(exists)
			cur_event=-1
			cur_subevent=0
		else:
			cur_event=exists
			cur_subevent=0
			update_event_tab()
		

func add_section(bpm=100,change_bpm=false,length_in_steps=16,must_hit=false):
	var data={
		"bpm":bpm,
		"change_bpm":change_bpm,
		"length_in_steps":length_in_steps,
		"must_hit":must_hit,
		"notes":[],
		"events":[]
	}
	chart.sections.append(data)

func add_subevent():
	var data:Array=[tabs.event.type.text,tabs.event.arg1.text,tabs.event.arg2.text]
	if cur_event!=-1:
		chart.sections[cur_section].events[cur_event][1].append(data)
		cur_subevent+=1
		update_event_tab()

func remove_subevent():
	if cur_event!=-1:
		if chart.sections[cur_section].events[cur_event][1].size()>1:
			chart.sections[cur_section].events[cur_event][1].remove(cur_subevent)
			cur_subevent-=1
			update_event_tab()

func update_song_tab():
	tabs.song.bpm.value=chart.bpm
	tabs.song.speed.value=chart.speed
	
	for a in ["bf","gf","dad","stage","ui_skin"]:
		for i in tabs.song[a].get_item_count():
			if tabs.song[a].get_item_text(i)==chart[a]:
				tabs.song[a].select(i)
				break	
	
func update_note_tab():
	var data:Array=chart.sections[cur_section].notes[cur_note]
	tabs.note.type.select(0)
	for i in tabs.note.type.get_item_count():
		if tabs.note.type.get_item_text(i)==data[3]:
			tabs.note.type.select(i)
			break
	tabs.note.time.value=data[0]
	tabs.note.length.value=data[2]

func update_event_tab():
	var data:Array=chart.sections[cur_section].events[cur_event][1][cur_subevent]
	for i in tabs.event.type.get_item_count():
		if tabs.event.type.get_item_text(i)==data[0]:
			tabs.event.type.select(i)
			break
	tabs.event.arg1.text=data[1]
	tabs.event.arg2.text=data[2]
	tabs.event.slot_label.text=str(cur_subevent+1," / ",chart.sections[cur_section].events[cur_event][1].size())

func update_section_tab():
	var data:Dictionary=chart.sections[cur_section]
	tabs.section.bpm.value=data.bpm
	tabs.section.change_bpm.pressed=data.change_bpm
	tabs.section.length.value=data.length_in_steps
	tabs.section.must_hit.pressed=data.must_hit

func get_section_id(time):
	var da_bpm=chart.bpm
	var da_pos=0
	for i in range(0,chart.sections.size()):
		da_bpm=chart.bpm
		if (chart.sections[i].change_bpm):
			da_bpm=chart.sections[i].bpm
		var da_len=chart.sections[i].length_in_steps*((60.0/da_bpm)/4.0)
		if da_pos+da_len>time:
			return i
		da_pos+=da_len
	return 0

func get_section_start(index):
	var da_bpm=chart.bpm
	var da_pos=0.0
	for i in range(0,index):
		da_bpm=chart.bpm
		if (chart.sections[i].change_bpm):
			da_bpm=chart.sections[i].bpm
		var da_len=chart.sections[i].length_in_steps*((60.0/da_bpm)/4.0)
		da_pos+=da_len
	return da_pos

func mouse_can_place_notes():
	return mouse_snap.x/GRID_SIZE>-1 and mouse_snap.x/GRID_SIZE<4*2 and mouse_snap.y/GRID_SIZE>-1 and mouse_snap.y/GRID_SIZE<16

func mouse_can_place_events():
	return mouse_snap.x/GRID_SIZE>-2 and mouse_snap.x/GRID_SIZE<0 and mouse_snap.y/GRID_SIZE>-1 and mouse_snap.y/GRID_SIZE<16

func get_strum_y(time):
	return Math.remap_range(time,0,16*Conductor.step_crochet,0,0+(16*GRID_SIZE)*get_chart_zoom())

func get_strum_time(y):
	return Math.remap_range(y,0,0+(16*GRID_SIZE)*get_chart_zoom(),0,16*Conductor.step_crochet)

func get_chart_zoom():
	return zoom_list[cur_zoom]

func get_note_type_number(type:String):
	var types=Globals.get_note_type_list()
	if type in types:
		for i in types.size():
			if type==types[i]:
				return i
	return ""
	
func on_bpm_changed():
	tabs.note.time.step=Conductor.step_crochet/32
	tabs.note.length.step=Conductor.step_crochet/32

func on_song_speed_changed(value):
	chart.speed=value

func on_note_type_selected(index):
	if cur_note!=-1:
		chart.sections[cur_section].notes[cur_note][3]=tabs.note.type.get_item_text(index)

func on_note_time_changed(value):
	if cur_note!=-1:
		chart.sections[cur_section].notes[cur_note][0]=value

func on_note_length_changed(value):
	if cur_note!=-1:
		chart.sections[cur_section].notes[cur_note][2]=value

func on_section_musthit_toggled(toggle):
	chart.sections[cur_section].must_hit=toggle

func on_section_changebpm_toggled(toggle):
	chart.sections[cur_section].change_bpm=toggle
	Conductor.set_bpm(chart.sections[cur_section].bpm if toggle else chart.bpm)

func on_section_bpm_changed(value):
	chart.sections[cur_section].bpm=value
	Conductor.set_bpm(chart.sections[cur_section].bpm if chart.sections[cur_section].change_bpm else chart.bpm)

func on_section_length_changed(value):
	chart.sections[cur_section].length_in_steps=value
	print(value)

func on_event_type_selected(index):
	if cur_event!=-1:
		chart.sections[cur_section].events[cur_event][1][cur_subevent][0]=tabs.event.type.get_item_text(index)
	tabs.event.manual_label.text=events_desc[tabs.event.type.get_item_text(index)]
		
func on_event_arg1_changed(new_text):
	if cur_event!=-1:
		chart.sections[cur_section].events[cur_event][1][cur_subevent][1]=new_text

func on_event_arg2_changed(new_text):
	if cur_event!=-1:
		chart.sections[cur_section].events[cur_event][1][cur_subevent][2]=new_text

func on_event_page_next():
	if cur_event!=-1:
		cur_subevent=min(cur_subevent+1,chart.sections[cur_section].events[cur_event][1].size()-1)
		update_event_tab()

func on_event_page_prev():
	if cur_event!=-1:
		cur_subevent=max(cur_subevent-1,0)
		update_event_tab()

func on_toggletabs_pressed():
	show_tabs=!show_tabs
	tween.interpolate_property(self.tabs.parent,"rect_global_position:x",tabs.parent.rect_global_position.x,883 if show_tabs else 1280+24,0.8,Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
	tween.start()

func clear_section():
	chart.sections[cur_section].notes=[]
	chart.sections[cur_section].events=[]
	chart.sections[cur_section].must_hit=false
	chart.sections[cur_section].change_bpm=false
	chart.sections[cur_section].bpm=chart.bpm
	update_section_tab()

func swap_section_notes():
	var notes:Array=chart.sections[cur_section].notes
	for i in notes.size():
		notes[i][1]=int(notes[i][1]+4)%int(4*2)
	cur_note=-1
	
func duet_section_notes():
	var duet_notes:Array=[]
	for note in chart.sections[cur_section].notes:
		var fixed_column:int=note[1]
		if (fixed_column>4-1):
			fixed_column-=4
		else:
			fixed_column+=4

		var copied_note:Array=[note[0],fixed_column,note[2],note[3]]
		duet_notes.append(copied_note)
	
	for i in duet_notes:
		place_note(i[0],i[1],i[2],i[3],false)
	cur_note=-1
	
func mirror_section_notes():
	for note in chart.sections[cur_section].notes:
		var fixed_column:int=(int(4)-1)-(int(note[1])%int(4))
		if note[1]>=4:
			fixed_column+=4;
		note[1]=fixed_column;
	cur_note=-1

func copy_section_notes():
	if tabs.section.section_to_copy.value==-1:
		copied_section=chart.sections[cur_section].duplicate(true)
	else:
		var section_index:int=clamp(tabs.section.section_to_copy.value,0,chart.sections.size()-1)
		copied_section=chart.sections[section_index].duplicate(true)

func paste_section_notes():
	chart.sections[cur_section]=copied_section.duplicate(true)
