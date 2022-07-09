extends Node2D

const ALPHABET:PackedScene=preload("res://scenes/Alphabet.tscn")

var songs_data:Array=[]
var has_selected:bool=false

var cur_score:int=0
var cur_song:int=0
var cur_diff:int=0

var tween:=Tween.new()

onready var info_bg=$"Info/BG"
onready var personal_best_label=$"Info/PersonalBest"
onready var difficulty_label=$"Info/Difficulty"
onready var songs=$"Songs"
onready var bg=$"BG"

func _ready():
	add_child(tween)
	
	if not SoundManager.is_playing("Musics/FreakyMenu"):
		SoundManager.play("Musics/FreakyMenu")
	
	var songs_list:Array=[]

	for i in Globals.get_week_list():
		var week_data:Dictionary={}
		var f:=File.new()
		f.open("res://assets/weeks/%s.json"%[i],File.READ)
		week_data=parse_json(f.get_as_text())
		f.close()
		
		for j in week_data.songs:
			songs_data.append([j.name,j.color,j.icon,week_data.difficulties])


	for i in songs_data.size():
		var data:Array=songs_data[i]
		var song=ALPHABET.instance()
		
		song.text="/b "+data[0]
		songs.add_child(song)
		song.set_physics_process(false)
		song.hide()
		song.position.x=i*64
		song.position.y=i*160
		
		var icon:=Sprite.new()
		icon.texture=load("res://assets/images/icons/%s.png"%[data[2]])
		song.add_child(icon)
		icon.position.x=len("/b "+data[0])*46
		icon.position.y=92
		icon.hframes=2
		
	songs.position=Vector2(64,(720/2)-80)
	on_song_changed()
	
func _physics_process(delta):
	var y_input:int=int(Input.is_action_just_pressed("ui_down"))-int(Input.is_action_just_pressed("ui_up"))
	var x_input:int=int(Input.is_action_just_pressed("ui_right"))-int(Input.is_action_just_pressed("ui_left"))
	
	if Input.is_action_just_pressed("ui_accept") and !has_selected:
		var difficulties:Array=songs_data[cur_song][3]
		Globals.is_storymode=false
		Globals.song=songs_data[cur_song][0]
		Globals.difficulty=difficulties[cur_diff]
		SoundManager.play("MenuConfirm")
		SoundManager.stop("Musics/FreakyMenu")
		SceneManager.change_to("Gameplay")
		has_selected=true
	
	if Input.is_action_just_pressed("ui_cancel") and !has_selected:
		has_selected=true
		SoundManager.play("MenuCancel")
		SceneManager.change_to("MainOptionsMenu")
	
	if y_input!=0:
		on_song_changed(y_input)
		on_diff_changed(0)
		
	if x_input!=0:
		on_diff_changed(x_input)
		
	for i in songs.get_child_count():
		var sng=songs.get_child(i)
		if sng.global_position.y<0-160 or sng.global_position.y>720+160:
			sng.set_physics_process(false)
			sng.hide()
			continue
		else:
			sng.set_physics_process(true)
			sng.show()
		var color=Color.white if i==cur_song else (Color.white*0.6)
		tween.interpolate_property(sng,"modulate",sng.modulate,color,0.3,Tween.TRANS_CUBIC,Tween.EASE_OUT)
		tween.start()
		
	personal_best_label.text="PERSONAL BEST: %s"%[cur_score]
	personal_best_label.rect_position.x=(1280-personal_best_label.rect_size.x)-120
	info_bg.rect_position.x=1280-len(personal_best_label.text)*20
	info_bg.rect_size.x=800
	
func on_song_changed(change:int=0):
	var old_song:int=cur_song
	cur_song=clamp(cur_song+change,0,songs.get_child_count()-1)
	
	if cur_song!=old_song:
		SoundManager.play("MenuScroll")
	
	tween.interpolate_property(bg,"modulate",bg.modulate,Color(songs_data[cur_song][1]),0.8,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	tween.interpolate_property(songs,"position",songs.position,Vector2(64-cur_song*64,(720/2)-80-cur_song*160),0.4,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	tween.start()

func on_diff_changed(change:int=0):
	var difficulties:Array=songs_data[cur_song][3]
	var old_diff:int=cur_diff
	cur_diff=clamp(cur_diff+change,0,difficulties.size()-1)
	
	if cur_diff!=old_diff:
		SoundManager.play("MenuScroll")
	
	difficulty_label.text="<%s>"%[str(difficulties[cur_diff]).to_upper()]
	
	var score_total:int=Scores.get_song_score(songs_data[cur_song][0],difficulties[cur_diff])
	tween.interpolate_property(self,"cur_score",cur_score,score_total,0.5,Tween.TRANS_CIRC,Tween.EASE_OUT)
	tween.start()
	
