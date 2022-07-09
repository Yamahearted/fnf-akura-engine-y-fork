extends ParallaxBackground

export var bf:Vector3
export var gf:Vector3
export var dad:Vector3

func _ready():
	var layers=get_layers()
	
	if Settings.low_quality:
		layers[3].get_node("Curtains").texture=null
	
	if Settings.ultra_performance:
		layers[0].get_node("Back").texture=null
		layers[1].get_node("Front").texture=null
		layers[3].get_node("Curtains").texture=null

func on_actors_created():
	if is_instance_valid(Ref.dad):
		Ref.dad.flip()
		
func get_layers():
	return get_children()
