extends Node

func open(path):
	var texture=null
	var atlas=null
	path="res://assets/images/"+path
	
	if ResourceLoader.exists(path+".png"):
		texture=load(path+".png")
		atlas=get_xml(path+".xml")
		
	return {"texture":texture,"atlas":atlas}
	
func get_xml(path):
	var entries:=["name","width","height","frameX","frameY","x","y"]
	var file=XMLParser.new()
	var result=[]
	file.open(path)
	while file.read()==OK:
		if file.get_named_attribute_value_safe("name")!="":
			var frame={};
			for entry in entries:
				frame[entry]=file.get_named_attribute_value_safe(entry)
			result.append(frame)
	return result
