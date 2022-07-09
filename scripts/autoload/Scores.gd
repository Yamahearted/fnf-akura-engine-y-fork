extends Node

var scores:Dictionary={}

func _ready():
	load_scores()
	save_scores()

func set_song_score(song,diff,score=0):
	scores[song+"_"+diff]=score
	save_scores()
	
func get_song_score(song,diff):
	if not (song+"_"+diff) in scores.keys():
		set_song_score(song,diff,0)
	return scores[song+"_"+diff]

func save_scores():
	var f:=File.new()
	f.open("user://scores.json",File.WRITE)
	f.store_string(to_json(scores))
	f.close()

func load_scores():
	if Globals.file_exists("user://scores.json"):
		var f:=File.new()
		f.open("user://scores.json",File.READ)
		scores=parse_json(f.get_as_text())
		f.close()
