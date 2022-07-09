extends Node2D
class_name Stage

export var bf:Vector3
export var gf:Vector3
export var dad:Vector3
export var camera_start:Vector2
export var camera_zoom:=Vector2(1,1)

func _ready():
	var layers=get_layers()
	
	if Settings.low_quality:
		layers[3].get_node("Curtains").texture=null
	
	if Settings.ultra_performance:
		layers[0].get_node("Back").texture=null
		layers[1].get_node("Front").texture=null
		layers[3].get_node("Curtains").texture=null
	
	if is_instance_valid(Ref.camera):
		Ref.camera.move_to=camera_start
		Ref.camera.global_position=camera_start
		Ref.camera.zoom_to=camera_zoom
		Ref.camera.zoom=camera_zoom

func _process(delta):
	if is_instance_valid(Ref.camera):
		for i in get_layers():
			i.global_position=((Ref.camera.global_position+Ref.camera.offset)*i.factor)+i.offset

func on_actors_created():
	if is_instance_valid(Ref.dad):
		Ref.dad.flip()
		
func get_layers():
	return get_children()
