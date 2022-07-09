extends Stage

onready var girls=$"3/Girls"

func _ready():
	SceneManager.fade_out()
	girls.set_imageatlas("stages/senpai-school/girls")
	girls.add_animation("idle","BG girls",12,true)
	girls.play_animation("idle")
