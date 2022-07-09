extends Node2D

const ARROW:PackedScene=preload("res://scenes/Arrow.tscn")

var is_player:bool=false

func on_ready():
	scale*=0.7
	for i in 4:
		var arrow=ARROW.instance()
		arrow.position.x=(i*(156 if Settings.note_skin=="notes" else 172))
		arrow.column=i
		add_child(arrow)

func get_arrows():
	return get_children()
