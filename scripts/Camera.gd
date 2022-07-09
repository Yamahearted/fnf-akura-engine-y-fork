extends Camera2D

var target:Object
var use_tween:bool=true

var move_to:=Vector2()
var offset_to:=Vector2()
var zoom_to:=Vector2()
var rot_to:float=0.0

var offset_spd:float=0.4
var move_spd:float=0.6
var zoom_spd:float=0.8
var rot_spd:float=0.8

var tween:=Tween.new()

func _ready():
	zoom_to=zoom
	move_to=global_position
	offset_to=offset
	add_child(tween)
	
func _physics_process(delta):
	if target!=null:
		if target.get("global_position"):
			move_to=target.global_position

	if use_tween:
		tween.interpolate_property(self,"global_position",global_position,move_to,move_spd,Tween.TRANS_SINE,Tween.EASE_OUT_IN)
		tween.interpolate_property(self,"zoom",zoom,zoom_to,zoom_spd,Tween.TRANS_SINE,Tween.EASE_OUT_IN)
		tween.interpolate_property(self,"offset",offset,offset_to,offset_spd,Tween.TRANS_SINE,Tween.EASE_OUT_IN)
		tween.interpolate_property(self,"rotation_degrees",rotation_degrees,rot_to,rot_spd,Tween.TRANS_SINE,Tween.EASE_OUT_IN)
		tween.start()
	
func set_target(target):
	self.target=target
	
