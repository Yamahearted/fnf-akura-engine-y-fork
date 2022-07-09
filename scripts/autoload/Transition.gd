extends CanvasLayer

signal faded_in
signal faded_out

var is_fading_in:bool=false

var sent_signal:bool=false
var alpha:float=0.0
var alpha_to:float=0.0
var speed:float=1.0

var tween:=Tween.new()

onready var rect=$"Rect"

func _ready():
	add_child(tween)
	tween.connect("tween_completed",self,'tween_finished')
		
func _physics_process(delta):
	rect.material.set_shader_param("cutoff",alpha)
	
func fade_in():
	tween.interpolate_property(
		self,"alpha",1.0,0.0,speed,Tween.TRANS_CUBIC,Tween.EASE_OUT
	)
	is_fading_in=true
	tween.start()

func fade_out():
	tween.interpolate_property(
		self,"alpha",0.0,1.0,speed,Tween.TRANS_CUBIC,Tween.EASE_OUT
	)
	is_fading_in=false
	tween.start()

func tween_finished(node,method):
	if method==":alpha" and node==self:
		if is_fading_in:
			if alpha==0.0:
				emit_signal("faded_in")
				tween.remove(self,":alpha")
				print("fade in")
		else:
			if alpha==1.0:
				emit_signal("faded_out")
				tween.remove(self,":alpha")
				print("fade out")

func set_speed(speed=0.5):
	self.speed=speed

func set_mask(mask_name):
	var path="res://assets/images/transitions/"+mask_name+".png"
	if ResourceLoader.exists(path):
		rect.material.set_shader_param("mask",load(path))
