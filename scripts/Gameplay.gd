extends Node2D

signal note_pressed(note)
signal note_held(note)
signal note_missed(note)
signal note_missing(note)

const NOTE:PackedScene=preload("res://scenes/Note.tscn")
const ACTOR:PackedScene=preload("res://scenes/Actor.tscn")

var chart:Dictionary={}
var song_started:bool=false
var song_ended:bool=false
var cur_section:int=0
var tween:=Tween.new()

onready var ui=$"UI"
onready var inst=$"Inst"
onready var voices=$"Voices"
onready var pause_menu=$"PauseMenu"

func _ready():
	add_child(tween)
	
	Conductor.reset() # Clearing old song data stuff, so we can start nicely.
	Status.reset() # Clearing current player's combos, misses and etc.
	
	Conductor.connect("beat",self,"on_beat")
	Conductor.audio_player=inst
	
	Status.connect("enemy_died",self,"on_enemy_died")
	Status.connect("player_died",self,"on_player_died")
	
	inst.connect("finished",self,"on_song_finished")
	
	if Globals.is_storymode:
		Globals.song=Globals.songs_queue[0]
		
	load_song()
	Globals.ui_skin=chart.ui_skin
	Globals.timescale=1000*chart.speed
	
	Ref.countdown=$"UI/Countdown"
	Ref.countdown.connect("countdown_finished",self,"countdown_finished")
	Ref.countdown.call("on_ready")
	
	if len(chart.stage)>0:
		var stage_path="res://scenes/stages/"+chart.stage+".tscn"
		if Globals.file_exists(stage_path):
			Ref.stage=load(stage_path).instance()
			add_child(Ref.stage)
		else:
			get_tree().quit()
	else:
		get_tree().quit()
	
	Ref.health_bar=$"UI/HealthBar"
	Ref.health_bar.bump_score()
	Ref.time_bar=$"UI/TimeBar"
	
	Ref.combo=$"UI/Combo"
	Ref.combo.call("on_ready")
	
	Ref.camera=$"Camera"
	Ref.camera.zoom_to*=1.1

	Ref.strums.clear()
	Ref.strums.append($"UI/Strums/0")
	Ref.strums.append($"UI/Strums/1")
	Ref.strums[0].is_player=true
	
	for a in ["gf","bf","dad"]:
		Ref[a]=ACTOR.instance()
		Ref.stage.get_layers()[Ref.stage[a].z].add_child(Ref[a])
		Ref[a].set_actor(chart[a])
		Ref[a].global_position=Vector2(Ref.stage[a].x,Ref.stage[a].y)
	Ref.stage.call("on_actors_created")
		
	if Ref.dad.actor=="":
		Ref.dad=Ref.gf
	
	Conductor.set_bpm(chart.bpm)
	
	for strum in Ref.strums:
		strum.call("on_ready")
	
	for i in chart.sections.size():
		var section=chart.sections[i]
		var notes=section.notes.duplicate(true)
		notes.sort_custom(self,"sort_notes")
		
		for data in notes:
			var notes_per_player=4
			var fixed_column=int(data[1]) % notes_per_player

			var note=NOTE.instance() if str(data[3]) in [" ",""]  else load("res://scenes/notes/%s.tscn"%[data[3]]).instance()
			var strum=null
			
			if section.must_hit and data[1]<notes_per_player:
				strum=Ref.strums[0]
			elif section.must_hit and data[1]>=notes_per_player:
				strum=Ref.strums[1]
			elif !section.must_hit and data[1]<notes_per_player:
				strum=Ref.strums[1]
			elif !section.must_hit and data[1]>=notes_per_player:
				strum=Ref.strums[0]
			
			note.time=abs(section_get_start_time(i)+float(data[0]))+(Settings.ms_offset/1000.0)
			note.column=int(fixed_column)
			note.max_length=float(data[2])
			note.length=float(data[2])
			note.is_sustain=float(data[2])>0.0
			
			var arrow=strum.get_children()[fixed_column]
			arrow.add_note(note)
			
			note.slider_update()
			note.arrow=strum.get_children()[fixed_column]
			note.set_physics_process(false)
			note.hide()
			
	for i in Ref.strums.size():
		Ref.strums[i].position.x=[140,-490][i]
		
	if Settings.down_scroll:
		for strum in Ref.strums:
			strum.position.y=264
		Ref.combo.position.y=90
	else:
		for strum in Ref.strums:
			strum.position.y=-264
		Ref.combo.position.y=-90
	Ref.combo.position.x=-4
	
	if Settings.down_scroll:
		Ref.health_bar.position.y=-280
		Ref.time_bar.position.y=330
	else:
		Ref.health_bar.position.y=280
		Ref.time_bar.position.y=-345
		
	if Settings.middle_scroll:
		Ref.strums[0].position.x=-172
		Ref.strums[1].position.x=-506
		Ref.strums[1].modulate.a*=0.7
		
		if Settings.down_scroll:
			Ref.combo.position.x=460
			Ref.combo.position.y=-250
		else:
			Ref.combo.position.x=460
			Ref.combo.position.y=250

		for i in Ref.strums[1].get_arrows().size():
			var arrow=Ref.strums[1].get_arrows()[i]
			if i>1:
				arrow.position.x+=960
	
	if Settings.hide_ui:
		Ref.combo.hide()
		Ref.health_bar.hide()
	
	if not Settings.show_enemy_notes:
		Ref.strums[1].hide()
	
	Ref.combo.scale*=0.56
	Ref.combo.scale_to=Ref.combo.scale
	
	inst.volume_db=-80
	voices.volume_db=-80
	
	var script_path:String="res://assets/songs/"+Globals.song+"/Script.gd"
	var song_script:Node=(load(script_path) if Globals.file_exists(script_path) else load("res://scripts/Song.gd")).new()
	add_child(song_script)
	
	yield(get_tree(),"idle_frame")
	Conductor.paused=false
	inst.play(Conductor.time)
	if voices.stream!=null:
		voices.play(Conductor.time)
	
	pause_menu.can_pause=true
	
func _physics_process(_delta):
	if Input.is_action_just_pressed("ui_pause") and pause_menu.can_pause and not pause_menu.is_paused and pause_menu.pause_delay==0:
		pause_menu.call("pause_game")
	
	if chart.empty():
		return
	
	inst.pitch_scale=Conductor.pitch_scale
	voices.pitch_scale=Conductor.pitch_scale
	
	if cur_section!=section_get_id(Conductor.time):
		cur_section=section_get_id(Conductor.time)
		
		if chart.sections[cur_section].change_bpm:
			Conductor.set_bpm(chart.sections[cur_section].bpm)
		
		var target_actor=Ref.bf if chart.sections[cur_section].must_hit else Ref.dad
		Ref.camera.target=target_actor
	
	for strum in Ref.strums:
		for arrow in strum.get_arrows():
			var keybind:String=str("note_",arrow.column)
			var just_tap:bool=true
			for note in arrow.notes:
				var ms=(note.time)+((Conductor.crochet*Globals.countdown_max)+Settings.ms_offset/1000.0 if not song_started else Settings.ms_offset/1000.0)-Conductor.time;
				var dist=ms*Globals.timescale*(1.0 if Globals.ui_skin!="pixel" else 0.1)
				var slider_ms=(note.time+note.max_length)+((Conductor.crochet*Globals.countdown_max)+Settings.ms_offset/1000.0 if not song_started else Settings.ms_offset/1000.0)-Conductor.time
				
				if dist<=720+(64*4):
					if !note.is_spawned:
						if not arrow.get_owner().is_player:
							if Settings.show_enemy_notes:
								note.show()
								note.set_physics_process(true)
								note.slider_update()
						else:
							note.show()
							note.set_physics_process(true)
							note.slider_update()
						note.is_spawned=true
				else:
					continue
				
				if !note.is_held:
					note.position.y=dist*(1.0 if !Settings.down_scroll else -1.0)
				
				if ms>0.16:
					just_tap=true
					continue
				else:
					just_tap=false
					
				if song_started:
					note.length=note.max_length-((Conductor.time-Settings.ms_offset/1000.0)-note.time)
					
				if ms<=0.0 and song_started:
					if note.max_length>0.0:
						if !note.is_held:
							note.is_held=true
							note.position.y=0
							note.self_modulate.a=0.0
						
					if note.is_held and note.is_sustain:
						note.slider_update()
				
				if ms<-0.16:
					if !note.is_pressed and !note.is_missed:
						note.is_missed=true
						if note.must_hit:
							note.on_missed()
						emit_signal("note_missed",note)
						continue
				
				if slider_ms<-0.16 and note.is_missed:
					note.clear_cache()
					note.hide()
					note.set_physics_process(false)
					arrow.notes.erase(note)
					continue
				
				if note.length<=0.0 and note.max_length>0.0 and slider_ms<-0.4:
					note.clear_cache()
					note.hide()
					note.set_physics_process(false)
					arrow.notes.erase(note)
					continue

				if !Status.botplay and strum.is_player:
					if !note.is_pressed and Input.is_action_just_pressed(keybind):
						note.is_pressed=true
						note.pressed_time=(Conductor.time-Settings.ms_offset/1000.0)
						note.on_pressed()
						just_tap=false
						emit_signal("note_pressed",note)
						
						if note.max_length<=0.0:
							note.hide()
							note.position.y=0
							note.clear_cache()
							note.set_physics_process(false)
							arrow.notes.erase(note)
							break
						else:
							note.is_held=true
							note.position.y=0
							note.self_modulate.a=0.0
							note.slider_update()
							break
					
					if note.is_pressed and Input.is_action_pressed(keybind):
						note.on_held()
						emit_signal("note_held",note)
					
					if !Input.is_action_pressed(keybind):
						if note.length>0.1 and ms<-0.1 and note.must_hit:
							note.on_missing()
							emit_signal("note_missing",note)
							
				if Status.botplay and strum.is_player or !strum.is_player:
					if ms<=0.0:
						if note.is_pressed and note.length<=0.0:
							continue
						
						if !note.is_pressed:
							note.is_pressed=true
							note.pressed_time=(Conductor.time-Settings.ms_offset/1000.0)
							note.on_pressed()
							emit_signal("note_pressed",note)
							
							if note.max_length<=0.0:
								note.hide()
								note.position.y=0
								note.clear_cache()
								note.set_physics_process(false)
								arrow.notes.erase(note)
								break
							else:
								note.is_held=true
								note.position.y=0
								note.self_modulate.a=0.0
								note.slider_update()
								break
									
						if ms<=0.0 and note.is_held:
							note.on_held()
							emit_signal("note_held",note)
							
				if note.is_held and song_started:
					note.slider_update()
					if note.length<=0.0:
						note.hide()
						note.clear_cache()
						note.set_physics_process(false)
						arrow.notes.erase(note)
						break
					
			if !Status.botplay and just_tap and strum.is_player:
				if Input.is_action_just_pressed(keybind):
					arrow.play_animation("press",0)
					if not Settings.ghost_tapping:
						Ref.bf.play_animation("miss-"+["left","down","up","right"][int(arrow.column)%4],0)
						Status.combo=0
						Status.misses+=1
						Status.total_notes+=1
						Status.rating=""
						Status.subtract_hp(5)
						drown_out_song()
						
				elif Input.is_action_pressed(keybind) and arrow.animation=="press":
					if arrow.get_current_frame()>2:
						arrow.seek_animation(arrow.animation,2)
				elif !Input.is_action_pressed(keybind) and arrow.get_current_frame()>3 and arrow.animation=="press":
					arrow.play_animation("static",0)
	
	for i in ["x","y"]:
		ui.scale[i]=lerp(ui.scale[i],1.0,0.08)
	
	if Ref.camera.target:
		if Ref.camera.target.get_class() in ["Actor","AnimatedAtlas"]:
			Ref.camera.offset_to=Ref.camera.target.camera_offset
			if Settings.move_camera_with_actor:
				match Ref.camera.target.animation:
					"sing-left":
						Ref.camera.offset_to+=Vector2(-5,0)
					"sing-right":
						Ref.camera.offset_to+=Vector2(5,0)
					"sing-down":
						Ref.camera.offset_to+=Vector2(0,5)
					"sing-up":
						Ref.camera.offset_to+=Vector2(0,-5)
					_:
						Ref.camera.offset_to+=Vector2()
	
	if Input.is_action_just_pressed("ui_reset") and not Settings.disable_blueballed_button:
		Status.subtract_hp(10000000)
	
	if song_started:
		for i in chart.sections[cur_section].events.size():
			var data:Array=chart.sections[cur_section].events[i]
			if (section_get_start_time(cur_section)+data[0])<=Conductor.time:
				for sub_event in data[1]:
					var event_path="res://scripts/events/"+sub_event[0]+".gd"
					var event=load(event_path) if Globals.file_exists(event_path) else load("res://scripts/Event.gd")
					if event:
						event=event.new()
						add_child(event)
						event.call("on_event",sub_event[0],sub_event[1],sub_event[2])
				chart.sections[cur_section].events.remove(i)
			break
	
func load_song():
	var song_path="res://assets/songs/"+Globals.song+"/"
	var f=File.new()
	f.open(song_path+Globals.difficulty+".json",File.READ)
	chart=parse_json(f.get_as_text())
	f.close()
	inst.stream=load(song_path+"Inst.ogg") if ResourceLoader.exists(song_path+"Inst.ogg") else null
	voices.stream=load(song_path+"Voices.ogg") if ResourceLoader.exists(song_path+"Voices.ogg") else null
	Conductor.length=inst.stream.get_length() if inst.stream!=null else 0.0
	
func section_get_id(time):
	var da_bpm=chart.bpm
	var da_pos=0
	for i in range(0,chart.sections.size()):
		da_bpm=chart.bpm
		if (chart.sections[i].change_bpm):
			da_bpm=chart.sections[i].bpm
		var da_len=chart.sections[i].length_in_steps*((60.0/da_bpm)/4.0)
		if da_pos+da_len>time:
			return i
		da_pos+=da_len
	return 0

func section_get_start_time(index):
	var da_bpm=chart.bpm
	var da_pos=0.0
	for i in range(0,index):
		da_bpm=chart.bpm
		if (chart.sections[i].change_bpm):
			da_bpm=chart.sections[i].bpm
		var da_len=chart.sections[i].length_in_steps*((60.0/da_bpm)/4.0)
		da_pos+=da_len
	return da_pos

func on_beat():
	if !Conductor.paused:
		Ref.countdown.on_beat()
		if Conductor.beat_count%4==0 and Settings.bump_camera_at_beats:
			ui.scale*=1.015

func on_song_finished():
	if not song_ended:
		song_ended=true
		inst.stop()
		voices.stop()
		Conductor.reset()

		yield(get_tree().create_timer(Settings.ms_offset/1000.0),"timeout")
		
		if Status.score>Scores.get_song_score(Globals.song,Globals.difficulty):
			Scores.set_song_score(Globals.song,Globals.difficulty,Status.score)
		
		if Globals.is_storymode:
			Globals.songs_queue.pop_front()
			if not Globals.songs_queue.empty(): # We delete the previous song, and set the next song to play on the ready func.
				SceneManager.restart()
			else:
				SceneManager.change_to("StoryModeMenu")
		else:
			SceneManager.change_to("FreeplayMenu")		

func countdown_finished():
	if !song_started:
		song_started=true
		Conductor.time=0.0
		inst.seek(Conductor.time)
		voices.seek(Conductor.time)
		inst.volume_db=0
		voices.volume_db=0

func on_enemy_died():
	# This was made just for the sake of keeping the code consistency.
	pass 

func on_player_died():
	if !Status.died:
		Status.died=true
		Conductor.paused=true
		var player_data={
			"name":Ref.bf.actor,
			"global_position":Ref.bf.global_position,
			"rotation":Ref.bf.rotation,
			"scale":Ref.bf.scale
		} if is_instance_valid(Ref.bf) and Ref.bf!=null else {} 
		var camera_data={
			"global_position":Ref.camera.global_position,
			"rotation":Ref.camera.rotation,
			"offset":Ref.camera.offset,
			"zoom":Ref.camera.zoom,
		} if is_instance_valid(Ref.camera) and Ref.camera!=null else {} 
		
		Temp.set_data({
			"song_time":Conductor.time,
			"player":player_data,
			"camera":camera_data
		})
		
		Conductor.reset()
		SceneManager.change_to("GameOver",false)

func drown_out_song(miss_sound:bool=true):
	randomize()
	var snd_name:String="MissNote%s"%[str(int(rand_range(0,2)))]
	if miss_sound:
		SoundManager.play(snd_name,0.0)
	tween.interpolate_property(voices,"volume_db",-80,0,0.8,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	tween.start()

func sort_notes(a,b):
	return a[0]<b[0]
