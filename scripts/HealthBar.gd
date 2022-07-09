extends Node2D

onready var score=$"Score"
onready var score_label=$"Score/Label"
onready var icons=$"Icons"
onready var left_fill=$"Base/Left"
onready var right_fill=$"Base/Right"
onready var left_icon=$"Icons/Left"
onready var right_icon=$"Icons/Right"

func _ready():
	Conductor.connect("beat",self,"on_beat")
	bump_score()
	
func _physics_process(delta):
	for i in ["x","y"]:
		score.scale[i]=lerp(score.scale[i],1.0,0.3)
		for icon in icons.get_children():
			icon.scale[i]=lerp(icon.scale[i],1.0,0.12)
	
	if is_instance_valid(Ref.dad):
		left_fill.modulate=Ref.dad.hp_color
		left_icon.texture=Globals.get_actor_icon(Ref.dad.icon)
		
	if is_instance_valid(Ref.bf):
		right_fill.modulate=Ref.bf.hp_color
		right_icon.texture=Globals.get_actor_icon(Ref.bf.icon)
	
	var hp_percent=float(Status.hp)/float(Status.max_hp)
	left_fill.region_rect.size.x=lerp(left_fill.region_rect.size.x,600-(600*hp_percent),0.32)
	icons.position.x=lerp(icons.position.x,600-(600*hp_percent),0.32)
	
func bump_score():
	if Settings.advanced_ui:
		score_label.text=str(
			"Score: ",round(Status.score),
			" | Misses: ",Status.misses,
			" | Rating: ",Status.accuracy_rating,(" ("+str(stepify(Status.accuracy*100.0,0.01),"%)")) if Status.total_notes>0 and Status.total_hit>0 else "",
			(" | BOT " if Status.botplay else "")
		)
		score_label.rect_position.x=-300
		score_label.align=Label.ALIGN_CENTER
	else:
		score_label.text=str("Score: ",round(Status.score)," | (BOT) " if Status.botplay else "")
		score_label.rect_position.x=153 if not Status.botplay else 90
		score_label.align=Label.ALIGN_LEFT
		
	score.scale.x=1.05
	score.scale.y=1.05
	
func on_beat():
	for i in icons.get_children():
		randomize()
		i.scale=Vector2(1,1)*rand_range(1.06,1.12)
	
