extends Sprite

var grav=0.12
var velocity=Vector2()
var jump_height=8

func _ready():
	velocity.y=-jump_height

func _physics_process(delta):
	velocity.y+=grav
	position.y+=velocity.y
