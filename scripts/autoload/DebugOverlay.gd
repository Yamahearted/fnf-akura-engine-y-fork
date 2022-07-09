extends CanvasLayer

onready var label=get_node("Label")

func _ready():
	label.hide()

func _physics_process(delta):
	label.visible=Settings.show_fps_counter
	
	var advanced_text:String="Scene: %s\nPrevScene: %s"%[Ref.scene.get("name") if is_instance_valid(Ref.scene) else "",Ref.previous_scene_name]
	if not Settings.advanced_debug:
		advanced_text=""
	
	label.text=str(
		"Fps: ",Engine.get_frames_per_second(),"\n",
		advanced_text
	)
