extends CanvasLayer

var y_to:float=0.0

onready var fill=$"Base/Visualizer/Fill"
onready var base=$"Base"
onready var timer=$"Timer"

func _ready():
	AudioServer.set_bus_volume_db(0,-40)
	base.position.x=(1280/2)-(116/2)
	base.position.y=-60
	y_to=-60

func _physics_process(delta):
	var input=int(Input.is_action_just_pressed("ui_volume_add"))-int(Input.is_action_just_pressed("ui_volume_sub"))
	base.position.y=lerp(base.position.y,y_to,0.4)
	
	if input!=0:
		var old_vol:int=Settings.master_volume
		Settings.master_volume=clamp(Settings.master_volume+sign(input),0,10)
		fill.region_rect.size.x=(Settings.master_volume*12)
		base.position.y=0
		timer.start()
		y_to=0
		
		if Settings.master_volume!=old_vol:
			SoundManager.play("MenuScroll")
			Settings.save_config()

	AudioServer.set_bus_volume_db(0,
		lerp(AudioServer.get_bus_volume_db(0),(-40+(Settings.master_volume/10.0)*40) if Settings.master_volume>0 else -80,0.24)
	)
	
func on_timeout():
	y_to=-60
