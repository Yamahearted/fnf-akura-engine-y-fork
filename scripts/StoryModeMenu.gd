extends Node2D

var weeks_data:Array=[]

var cur_week:int=0
var cur_diff:int=0
var cur_score:int=0

var has_confirmed:bool=false
var has_left:bool=false

var tween:=Tween.new()

onready var actors=$"Preview/Actors"
onready var weeks=$"Weeks"
onready var bg_sprite=$"Preview/Background"
onready var bg_window=$"Preview/Window"
onready var difficulty=$"Dificulty/Sprite"
onready var arrow_left=$"Dificulty/ArrowLeft"
onready var arrow_right=$"Dificulty/ArrowRight"
onready var tracks_label=$"TracksLabel"
onready var title_label=$"TitleLabel"
onready var score_label=$"ScoreLabel"

func _ready():
	add_child(tween)
	
	if not SoundManager.is_playing("Musics/FreakyMenu"):
		SoundManager.play("Musics/FreakyMenu")
	
	arrow_right.scale.x=-1
	for i in [arrow_left,arrow_right]:
		i.set_imageatlas("story-mode/arrow")
		i.add_animation("static","static")
		i.add_animation("confirm","confirm")
		i.set_play_next("confirm","static")
		i.play_animation("static")
	
	for week_name in Globals.get_week_list():
		var f:=File.new()
		f.open("res://assets/weeks/"+week_name+".json",File.READ)
		weeks_data.append(parse_json(f.get_as_text()))
		f.close()
	
	for data in weeks_data:
		var sprite:=Sprite.new()
		weeks.add_child(sprite)
		sprite.texture=load("res://assets/images/story-mode/weeks-titles/%s.png"%[data.logo])
		sprite.position.y=(weeks.get_child_count())*120
	
	# This is the most closiest thing about object pooling
	# We're preloading/creating all the possible characters and reusing them later
	# Since we're turning them off when not in use, they won't cause any lag
	var possible_actors:PoolStringArray=["bf","gf","dad"]
	for i in possible_actors:
		var actor:=AnimatedAtlas.new()
		actors.add_child(actor)
		match i:
			"bf":
				actor.set_imageatlas("story-mode/actors/boyfriend")
				actor.add_animation("idle","BF idle dance",24,true,-215,-366)
				actor.add_animation("taunt-hey","BF HEY!!",24,false,-215,-366)
				actor.play_animation("idle",0)
			"gf":
				actor.set_imageatlas("story-mode/actors/girlfriend")
				actor.add_animation("idle-1","GF Dancing Beat left0",24,false,-362,-650,"idle-2",true)
				actor.add_animation("idle-2","GF Dancing Beat right0",24,false,-362,-645,"idle-1",true)
				actor.play_animation("idle-1",0)
			"dad":
				actor.set_imageatlas("story-mode/actors/daddy")
				actor.add_animation("idle","Dad idle dance instance 1",24,true,-188,-726)
				actor.play_animation("idle",0)
		actor.name=i
		actor.set_physics_process(false)
		actor.hide()
		
	on_difficulty_changed()
	on_week_changed()
	on_score_changed()
	
func _physics_process(delta):
	var week_data:Dictionary=weeks_data[cur_week]
	var input_y:int=int(Input.is_action_just_pressed("ui_down"))-int(Input.is_action_just_pressed("ui_up"))
	var input_x:int=int(Input.is_action_just_pressed("ui_right"))-int(Input.is_action_just_pressed("ui_left"))
	
	if input_y!=0 and !has_confirmed and not has_left:
		var old_week:int=cur_week
		cur_week=clamp(cur_week+input_y,0,weeks_data.size()-1)
		if old_week!=cur_week:
			SoundManager.play("MenuScroll")
			on_week_changed()
		
	if input_x!=0 and !has_confirmed and not has_left:
		var old_difficulty:int=cur_diff
		var arrow:Object=[arrow_left,arrow_right][clamp(input_x,0,1)]
		arrow.play_animation("confirm",0)
		cur_diff=clamp(cur_diff+input_x,0,week_data.difficulties.size()-1)
		if cur_diff!=old_difficulty:
			SoundManager.play("MenuScroll")
			on_difficulty_changed()
			on_score_changed()
	
	if Input.is_action_just_pressed("ui_accept") and !has_confirmed and not has_left:
		Globals.is_storymode=true
		Globals.song=Globals.songs_queue[0]
		Globals.difficulty=week_data.difficulties[cur_diff]
		
		SoundManager.stop("Musics/FreakyMenu")
		SoundManager.play("MenuConfirm")
		
		has_confirmed=true
		
		for actor in actors.get_children():
			actor.play_animation("taunt-hey",0)
			
		yield(get_tree().create_timer(1.0),"timeout")
		SceneManager.change_to("Gameplay")
	
	if Input.is_action_just_pressed("ui_cancel") and !has_left:
		has_left=true
		SoundManager.play("MenuCancel")
		SceneManager.change_to("MainOptionsMenu")
	
	if has_confirmed and not has_left:
		var week_sprite:Sprite=weeks.get_child(cur_week)
		var color_index:int=int(OS.get_ticks_msec()/60)%2
		week_sprite.modulate=[Color.white,Color.cyan][color_index]
	
	score_label.text="WEEK SCORE: %s"%[cur_score]
		
func on_week_changed():
	var week_data:Dictionary=weeks_data[cur_week]
	var actors_data:Array=week_data.actors
	
	Globals.songs_queue=[]
	for j in week_data.songs:
		Globals.songs_queue.append(j.name)
	
	for i in weeks.get_child_count():
		var week_sprite:Sprite=weeks.get_child(i)
		tween.interpolate_property(week_sprite,"modulate:a",week_sprite.modulate.a,1.0 if i==cur_week else 0.24 ,0.48,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	
	# Hide all the possible actors, so we only need to set visible those that we're actualy going to use.
	hide_actors()
	
	if week_data.actors.size()>0:
		for data in week_data.actors:
			if actors.has_node(data[0]):
				var actor:Object=actors.get_node(data[0])
				if is_instance_valid(actor):
					actor.set_physics_process(true)
					actor.show()
					actor.scale.x=-1 if data[5] else 1
					actor.position=Vector2(data[1],data[2])	
					actor.scale=Vector2(actor.scale.x,1)*data[4]
					actor.z_index=data[3]
	
	bg_sprite.texture=load("res://assets/images/story-mode/backgrounds/"+week_data.bg+".png") if len(week_data.bg)>0 else null
	
	tracks_label.text=""
	for i in week_data.songs:
		if i.show_on_storymode:
			tracks_label.text+=i.name+"\n"
	
	title_label.text=week_data.title
	
	tween.interpolate_property(actors,"modulate",actors.modulate,Color(week_data.storymode_color),0.32,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	tween.interpolate_property(bg_window,"modulate",bg_window.modulate,Color(week_data.storymode_color),0.32,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	tween.interpolate_property(weeks,"position:y",weeks.position.y,(532)-(cur_week+1)*120,0.32,Tween.TRANS_SINE,Tween.EASE_OUT)
	tween.start()
	
	var old_diff:int=cur_diff
	cur_diff=clamp(cur_diff,0,week_data.difficulties.size()-1)
	
	if cur_diff!=old_diff:
		on_difficulty_changed()
	
	on_score_changed()
	
func on_difficulty_changed():
	var week_data:Dictionary=weeks_data[cur_week]
	difficulty.texture=load("res://assets/images/story-mode/difficulties/"+week_data.difficulties[cur_diff]+".png")
	tween.interpolate_property(difficulty,"position:y",490,509,0.18,Tween.TRANS_CIRC,Tween.EASE_OUT)
	tween.interpolate_property(difficulty,"modulate:a",0.0,1.0,0.18,Tween.TRANS_CIRC,Tween.EASE_OUT)
	tween.start()
	
func on_score_changed():
	var week_data:Dictionary=weeks_data[cur_week]
	var score_total:int=0
	
	for i in Globals.songs_queue:
		score_total+=Scores.get_song_score(i,week_data.difficulties[cur_diff])
	
	tween.interpolate_property(self,"cur_score",cur_score,score_total,0.5,Tween.TRANS_CIRC,Tween.EASE_OUT)

func hide_actors():
	for i in actors.get_children():
		i.hide()
		i.set_physics_process(false)
