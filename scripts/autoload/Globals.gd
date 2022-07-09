extends Node

const ENGINE_VERSION:String="0.1"

var week:String=""
var song:String=""
var difficulty:String=""
var is_storymode:bool=false
var songs_queue:Array=[]

var ui_skin:String="base"
var timescale:float=1640

var allow_mods:bool=true
var dev_mode:bool=true
var can_botplay:bool=true
var countdown_max:int=4

var ui_skins:PoolStringArray=[
	"base",
	"pixel"
]

var difficulties:PoolStringArray=[
	"easy",
	"normal",
	"hard"
]

func _init():
	pause_mode=Node.PAUSE_MODE_PROCESS
	
func _ready():
	SceneManager.layer=126
	DebugOverlay.layer=127
	VolumeManager.layer=128
	
func _process(delta):
	if Input.is_action_just_pressed("ui_fullscreen"):
		OS.window_fullscreen=!OS.window_fullscreen

func file_exists(path):
	var f=File.new()
	var result=f.file_exists(path)
	f.close()
	return result

func get_content_in_folder(path):
	var files=[]
	var dir=Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var file=dir.get_next()
		if file=="":
			break
		elif not file.begins_with("."):
			files.append(file)
	dir.list_dir_end()
	return files

func get_song_list():
	return get_content_in_folder("res://assets/songs/")

func get_actor_icon(actor_name:String):
	if len(actor_name)!=0:
		var data:Dictionary=get_actor_data(actor_name)
		var path="res://assets/images/icons/%s.png"%[data.icon]
		data.clear()
		if file_exists(path):
			return load(path)
		return null
	return null

func get_event_list():
	var list=get_content_in_folder("res://scripts/events/")
	for i in list.size():
		if str(list[i]).ends_with(".gd"):
			list[i]=str(list[i]).left(len(list[i])-3)
	list.push_front("")
	return list

func get_stage_list():
	var list=get_content_in_folder("res://scenes/stages/")
	for i in list.size():
		if str(list[i]).ends_with(".tscn"):
			list[i]=str(list[i]).left(len(list[i])-5)
	return list

func get_actor_list():
	var list=get_content_in_folder("res://assets/actors/")
	list.push_front("")
	for i in list.size():
		if str(list[i]).ends_with(".json"):
			list[i]=str(list[i]).left(len(list[i])-5)
	return list

func get_week_list():
	var list=get_content_in_folder("res://assets/weeks/")
	for i in list.size():
		if str(list[i]).ends_with(".json"):
			list[i]=str(list[i]).left(len(list[i])-5)
	return list

func get_actor_data(actor_name):
	var actor_path:String="res://assets/actors/"+actor_name+".json"
	if Globals.file_exists(actor_path):
		var f:=File.new()
		var data:Dictionary
		f.open(actor_path,File.READ)
		data=parse_json(f.get_as_text())
		f.close()
		return data
	return {}
		
func get_note_type_list():
	var list=get_content_in_folder("res://scripts/notes/")
	for i in list.size():
		if str(list[i]).ends_with(".gd"):
			var type_name=str(list[i]).left(len(list[i])-3)
			list[i]=type_name
	list.push_front(" ")
	return list

func get_mods_list():
	var list=get_content_in_folder("user://mods/")
	for i in list.size():
		if str(list[i]).ends_with(".pck"):
			var type_name=str(list[i]).left(len(list[i])-4)
			list[i]=type_name
	#list.push_front("")
	return list

func get_ui_skins_list():
	return ui_skins

func get_difficulties_list():
	return difficulties
