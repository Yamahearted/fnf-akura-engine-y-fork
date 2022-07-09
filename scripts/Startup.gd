extends Node2D

func _ready():
	yield(get_tree(),"idle_frame")
	SceneManager.change_to("TitleScreen")
