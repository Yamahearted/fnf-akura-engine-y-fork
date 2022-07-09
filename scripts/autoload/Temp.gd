extends Node

var data:Dictionary={}

func get_data(key):
	return data[key]

func set_data(new_data:Dictionary):
	data=new_data

func clear():
	data={}
