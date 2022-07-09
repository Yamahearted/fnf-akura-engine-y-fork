extends Node2D

const COMBO_PARTICLE=preload("res://scenes/ComboParticle.tscn")

var numbers_offset=104
var bump_force=1.1
var grav=0.3
var jump_height=3
var visible_time=0.0
var scale_to=Vector2(1,1)

onready var rating=$"Rating"
onready var numbers=$"Numbers"
onready var ms_label=$"MsLabel"

func on_ready():
	match Globals.ui_skin:
		"pixel":
			numbers.position.y=24*4
			numbers_offset=8
		_:
			numbers.position.y=105
			numbers_offset=90
	ms_label.rect_position.y=120
	
func _physics_process(delta):
	for i in ["x","y"]:
		scale[i]=lerp(scale[i],scale_to[i],0.1)
	visible_time=lerp(visible_time,0.0,0.12)
	modulate.a=clamp(visible_time,0.0,1.0)
	
	if modulate.a<0.05:
		rating.texture=null if rating.texture!=null else rating.texture
		rating.set_physics_process(false)
		for nmb in numbers.get_children():
			nmb.texture=null if nmb.texture!=null else nmb.texture
		
func spawn(missed:bool=false):
	if missed or not Settings.show_combo_text:
		return
	
	scale=scale_to*bump_force
	visible_time=5
	
	for nmb in numbers.get_children():
		nmb.texture=null
		nmb.set_physics_process(false)
		nmb.hide()
	
	rating.scale=Vector2(8,8) if Globals.ui_skin=="pixel" else Vector2(1,1)
	numbers.scale=Vector2(6,6) if Globals.ui_skin=="pixel" else Vector2(0.7,0.77)
	
	rating.position=Vector2()
	rating.grav=0.12
	rating.jump_height=rand_range(2,4)
	rating.velocity.y=-rating.jump_height
	rating.texture=load("res://assets/images/ui-skins/"+Globals.ui_skin+"/"+Status.rating+".png")
	rating.set_physics_process(true)
	
	var padded_combo=str(Status.combo).pad_zeros(3)
	for i in len(padded_combo):
		var nmb=COMBO_PARTICLE.instance()
		randomize()
		nmb.texture=load("res://assets/images/ui-skins/"+Globals.ui_skin+"/"+"num"+str(padded_combo)[i]+".png")
		nmb.position.x=i*numbers_offset
		nmb.jump_height=rand_range(2,4)*(1.0 if !Globals.ui_skin=="pixel" else 0.1)
		nmb.grav=0.12 if !Globals.ui_skin=="pixel" else 0.012
		numbers.add_child(nmb)
	numbers.position.x=-((len(padded_combo)*numbers_offset)/2)*numbers.scale.x
	
	if Settings.show_note_ms:
		ms_label.modulate=Color.white
		ms_label.modulate=Color.red if Status.rating=="shit" else ms_label.modulate
		ms_label.modulate=Color.tomato if Status.rating=="bad" else ms_label.modulate
		ms_label.modulate=Color.sandybrown if Status.rating=="good" else ms_label.modulate
		ms_label.modulate=Color.lightyellow if Status.rating=="sick" else ms_label.modulate
		ms_label.text=str(stepify(Status.pressed_ms*100,0.01),"ms")
		if Status.botplay:
			ms_label.text=str("0.0ms")
