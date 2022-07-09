extends Node2D

onready var icon=$"Icon"
onready var title=$"Title"
onready var desc=$"Desc"
onready var images_scroll=$"Scroll/Images"

func add_image(tex):
	var texrect=TextureRect.new()
	images_scroll.add_child(texrect)
	texrect.rect_min_size=Vector2(550,390)
	texrect.expand=true
	texrect.texture=tex
	texrect.rect_size=Vector2(550,390)
