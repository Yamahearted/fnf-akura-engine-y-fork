extends Node

signal player_died
signal enemy_died

var accuracy_ratings:Array=[
	['You Suck!', 0.2],
	['Shit', 0.4],
	['Bad', 0.5],
	['Bruh', 0.6],
	['Meh', 0.69],
	['Nice', 0.7],
	['Good', 0.8],
	['Great', 0.9],
	['Sick!', 1.0]
]

var hp:float=50.0
var max_hp:float=100.0
var min_hp:float=0.0

var combo:int=0
var score:int=0
var misses:int=0
var rating:String="?"
var pressed_ms:float=0.0
var deaths:int=0

var can_take_damage:bool=true
var botplay:bool=false

var total_hit:float=0
var total_notes:int=0
var accuracy:float=0.0

var accuracy_rating:String="?"
var note_rating:String="shit"

var sicks:int=0
var goods:int=0
var bads:int=0
var shits:int=0

var died:bool=false

func _ready():
	pause_mode=Node.PAUSE_MODE_PROCESS

func _process(delta):
	if total_hit!=0 and total_notes!=0:
		accuracy=(total_hit/total_notes)
		if accuracy>=1.0:
			accuracy_rating=accuracy_ratings[accuracy_ratings.size()-1][0]
		else:
			for i in accuracy_ratings.size():
				if accuracy<accuracy_ratings[i][1]:
					accuracy_rating=accuracy_ratings[i][0]
					break
	else:
		accuracy_rating="?"
		
func add_hp(heal_amount):
	if hp+heal_amount>max_hp:
		emit_signal("enemy_died")
	hp=min(hp+heal_amount,max_hp)
	
func subtract_hp(dmg_amount):
	if hp-dmg_amount<min_hp:
		emit_signal("player_died")
	hp=max(hp-dmg_amount,min_hp)

func reset():
	hp=50.0
	max_hp=100.0
	min_hp=0.0
	combo=0
	score=0
	misses=0
	rating="?"
	total_hit=0
	total_notes=0
	accuracy=0
	accuracy_rating="?"
	note_rating="shit"
	sicks=0
	goods=0
	bads=0
	shits=0
	died=false
	botplay=false
	can_take_damage=true
