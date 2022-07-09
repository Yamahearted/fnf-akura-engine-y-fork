extends "res://scripts/Note.gd"
 
func _ready():
	must_hit=false

func on_pressed():
	on_missed()

func on_held():
	on_missing()
