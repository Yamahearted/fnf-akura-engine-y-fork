extends ParallaxBackground
class_name Stage


export var bf:Vector3
export var gf:Vector3
export var dad:Vector3
export var camera_start:Vector2

func _ready():
	var layers=get_layers()
	
	if Settings.low_quality:
		layers[3].get_node("Curtains").texture=null
	
	if Settings.ultra_performance:
		layers[0].get_node("Back").texture=null
		layers[1].get_node("Front").texture=null
		layers[3].get_node("Curtains").texture=null
	
	if is_instance_valid(Ref.camera):
		Ref.camera.move_to=Vector2(0,0)
		Ref.camera.global_position=Vector2(0,0)
		Ref.camera.zoom_to=Vector2(1,1)
		Ref.camera.zoom=Vector2(1,1)
		
	yield(get_tree(),"idle_frame")
	Ref.camera.move_to=camera_start
	
func on_actors_created():
	if is_instance_valid(Ref.dad):
		Ref.dad.flip()
		
func get_layers():
	return get_children()
