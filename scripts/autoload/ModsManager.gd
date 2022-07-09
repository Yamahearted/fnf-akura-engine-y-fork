extends Node

func load_mods():
	if not OS.has_feature("editor"):
		if Globals.allow_mods and Settings.allow_mods:
			for mod in Globals.get_mods_list():
				var pck_path:String="user://mods/%s/%s"%[mod,"mod.pck"]
				var scene_path:String="user://mods/%s/%s"%[mod,"mod_scene.tscn"]
				printt(pck_path,scene_path)
				if mod==Settings.mod:
					var sucess=ProjectSettings.load_resource_pack(pck_path)
					if sucess:
						printt(mod,"was found and initialized!")
					
				#ProjectSettings.load_resource_pack()
				
func run_mod(pck_path:String):
	var result=ProjectSettings.load_resource_pack(pck_path)
	return result
	
