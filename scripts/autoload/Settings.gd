extends Node

var default_keybinds:Dictionary={
	"ui_accept":[KEY_ENTER,KEY_UNKNOWN],
	"ui_cancel":[KEY_ESCAPE,KEY_UNKNOWN],
	"ui_left":[KEY_LEFT,KEY_UNKNOWN],
	"ui_down":[KEY_DOWN,KEY_UNKNOWN],
	"ui_up":[KEY_UP,KEY_UNKNOWN],
	"ui_right":[KEY_RIGHT,KEY_UNKNOWN],
	"ui_reset":[KEY_R,KEY_UNKNOWN],
	"ui_pause":[KEY_ENTER,KEY_UNKNOWN],
	"ui_volume_add":[KEY_KP_ADD,KEY_UNKNOWN],
	"ui_volume_sub":[KEY_KP_SUBTRACT,KEY_UNKNOWN],
	"note_0":[KEY_A,KEY_LEFT],
	"note_1":[KEY_S,KEY_DOWN],
	"note_2":[KEY_W,KEY_UP],
	"note_3":[KEY_D,KEY_RIGHT],
}
var note_skins:Array=[
	"notes"
]
var countdown_skins:Array=[
	"base",
	"timer"
]
var timer_styles:Array=[
	"time-elapsed",
	"time-left",
	"song-name",
	"dont-show"
]

var framerate:int=60
var master_volume:int=10

var keybinds:Dictionary=default_keybinds.duplicate(true)

var note_skin:String="notes"
var countdown_skin:String="base"
var timer_style:String="time-elapsed"

var advanced_ui:bool=true
var advanced_debug:bool=true
var middle_scroll:bool=false
var down_scroll:bool=true
var ms_offset:float=0.0
var dev_mode:bool=true
var can_botplay:bool=true
var ghost_tapping:bool=true

var ultra_performance:bool=false
var low_quality:bool=false
var antialiasing:bool=true

var hide_ui:bool=false
var bump_camera_at_beats:bool=true

var show_flashing_lights:bool=true
var show_note_splashes:bool=true
var show_combo_text:bool=true
var show_note_ms:bool=true
var show_fps_counter:bool=false
var update_checker:bool=false
var show_enemy_notes:bool=true

var animate_enemy_arrows:bool=false
var disable_blueballed_button:bool=false
var move_camera_with_actor:bool=false

var mod:String=""
var allow_mods:bool=true

func _ready():
	pause_mode=Node.PAUSE_MODE_PROCESS
	
	var d:=Directory.new()
	if not d.dir_exists("user://mods"):
		d.make_dir("user://mods")
	
	if not Globals.file_exists("user://settings-default.json"):
		save_config(true)
	
	load_config()
	save_config()
	
	if Settings.mod!="": # Autoload previously added mod
		ModsManager.load_mods()
	
func save_config(default:bool=false):
	var data:Dictionary={}
	for entry in get_script().get_script_property_list():
		var key:String=entry.name
		var value=get(key)
		data[key]=value
	var f:=File.new()
	f.open("user://%s.json"%["settings-default" if default else "settings"],File.WRITE)
	f.store_string(to_json(data))
	f.close()
	print("User settings are saved!")
	Engine.set_target_fps(framerate)
	
func load_config(default:bool=false):
	var data:Dictionary={}
	var path:String="user://%s.json"%["settings-default" if default else "settings"]
	if Globals.file_exists(path):
		var f:=File.new()
		f.open(path,File.READ)
		data=parse_json(f.get_as_text())
		f.close()

	if !data.empty():
		for entry in data.keys():
			var value=data[entry]
			set(entry,value)
			
		for action in keybinds.keys():
			var scancodes:Array=keybinds[action]
			InputMap.action_erase_events(action)
			for a in scancodes:
				var key:=InputEventKey.new()
				key.set_scancode(a)
				InputMap.action_add_event(action,key)
		
		print("User settings fully loaded!")
	else:
		print("No User settings file to load!")
	
	Engine.set_target_fps(framerate)
	
func reset_keybinds():
	keybinds=default_keybinds.duplicate(true)
	save_config()
	SceneManager.restart()

func reset_all():
	load_config(true)
	save_config()
	SceneManager.restart()
