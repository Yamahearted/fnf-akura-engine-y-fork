extends Node

var chart={}

func _ready():
	if true:
		get_tree().connect("files_dropped",self,"parse_chart")

func parse_chart(files,screen):
	var data={}
	
	chart={
		"name":"",
		"difficulty":"easy",
		"ui_skin":"base",
		"bpm":100,
		"stage":"Stage",
		"speed":1.0,
		"sections":[],
		"bf":"bf",
		"gf":"gf",
		"dad":"dad",
		"arrows_count":4
	}
	
	if str(files[0]).ends_with(".json"):
		var f=File.new()
		f.open(files[0],File.READ)
		data=parse_json(f.get_as_text())
		f.close()
		
		chart.bpm=data.song.bpm
		chart.name=data.song.song
		
		for i in data.song.notes.size():
			var section=data.song.notes[i]
			var change_bpm=false if !section.has("ChangeBPM") else section.changeBPM
			var section_bpm=data.song.bpm if !section.has("bpm") else section.bpm
			add_section(section_bpm,change_bpm,section.lengthInSteps,section.mustHitSection)
			for note in section.sectionNotes:
				if float(note[1])>-1:
					add_note(float(note[1]),float(note[0])/1000.0-get_section_start_time(i),float(note[2])/1000.0,i)
	
		f.open("res://assets/songs/"+chart.name+".json",File.WRITE)
		f.store_string(to_json(chart))
		f.close()
		printt("New chart saved at songs:",chart.name)
	
func add_section(bpm=100,change_bpm=false,length_in_steps=16,must_hit=false):
	var data={
		"bpm":bpm,
		"change_bpm":change_bpm,
		"length_in_steps":length_in_steps,
		"must_hit":must_hit,
		"notes":[],
		"events":[]
	}
	chart.sections.append(data)

func add_note(column,time,length=0.0,section=0):
	var data:Array=[time,column,length,""]
	chart.sections[section].notes.append(data)

func get_section_id(time):
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

func get_section_start_time(index):
	var da_bpm=chart.bpm
	var da_pos=0.0
	for i in range(0,index):
		da_bpm=chart.bpm
		if (chart.sections[i].change_bpm):
			da_bpm=chart.sections[i].bpm
		var da_len=chart.sections[i].length_in_steps*((60.0/da_bpm)/4.0)
		da_pos+=da_len
	return da_pos
