extends Node2D

# /f+nmb = change text effect
# /c+nmb = change color
# /b toggle bold mode

export var text:String="/f2/bAight /f1/c1cool /f2/bswag !@#%"

var alphabet:String="abcdefghijklmnopqrstuvwxyz"
var numbers:String="1234567890"
var symbols:String="|~#$%()*+-:;<=>@[]^_.,'!?"

var effects:PoolStringArray=[
	"default",
	"shake",
	"wave"
]

var colors:Array=[
	Color.white,
	Color.yellow,
	Color.red,
	Color.tomato,
	Color.aqua,
	Color.violet,
	Color.white*0.6
]

var bold_atlas:=AnimatedAtlas.new()
var symb_atlas:=AnimatedAtlas.new()
var nmb_atlas:=AnimatedAtlas.new()
var capital_atlas:=AnimatedAtlas.new()
var lowercase_atlas:=AnimatedAtlas.new()

var shake_len:=Vector2(2,2)
var wave_len:=Vector2(2,2)
var wave_spd:float=120.0
var width:float=0.0

func _ready():
	for i in [capital_atlas,lowercase_atlas,bold_atlas,symb_atlas,nmb_atlas]:
		add_child(i)
		i.set_physics_process(false)
		i.hide()
		
	capital_atlas.set_imageatlas("alphabet/capital")
	lowercase_atlas.set_imageatlas("alphabet/lowercase")
	bold_atlas.set_imageatlas("alphabet/bold")
	symb_atlas.set_imageatlas("alphabet/symbols")
	nmb_atlas.set_imageatlas("alphabet/numbers")
	
	for i in len(alphabet):
		var letter:String=alphabet[i]
		lowercase_atlas.add_animation(letter,letter)
		capital_atlas.add_animation(letter,str(letter).to_upper())
		bold_atlas.add_animation(letter,str(letter).to_upper())
		
		if i>11:
			lowercase_atlas.add_offset(letter,0,35)
		else:
			lowercase_atlas.add_offset(letter,0,18)

		capital_atlas.add_offset(letter,0,12)	
	
	for i in len(numbers):
		var nmb:String=numbers[i]
		nmb_atlas.add_animation(nmb,nmb)
		nmb_atlas.add_offset(nmb,0,12)
		
	for i in len(symbols):
		var symb:String=symbols[i]
		match symb:
			".":
				symb_atlas.add_animation(symb,"period")
				symb_atlas.add_offset(symb,0,40)
			"'":
				symb_atlas.add_animation(symb,"apostraphie")
			"?":
				symb_atlas.add_animation(symb,"question mark")
				symb_atlas.add_offset(symb,0,-12)
			"!":
				symb_atlas.add_animation(symb,"exclamation point")
				symb_atlas.add_offset(symb,0,-10)
			",":
				symb_atlas.add_animation(symb,"comma")
				symb_atlas.add_offset(symb,0,40)
			_:
				symb_atlas.add_animation(symb,symb)
		symb_atlas.add_offset(symb,0,12)
	
	# I hate this, but it is necessary to have a good optimization
	symb_atlas.add_offset("!",0,0)
	symb_atlas.add_offset("#",0,8)
	symb_atlas.add_offset("-",0,30)
	lowercase_atlas.add_offset("a",0,10)
	lowercase_atlas.add_offset("c",0,15)
	lowercase_atlas.add_offset("s",0,-4)
	lowercase_atlas.add_offset("d",0,-5)
	lowercase_atlas.add_offset("f",0,0)
	lowercase_atlas.add_offset("n",0,0)
	lowercase_atlas.add_offset("s",0,0)
	lowercase_atlas.add_offset("e",0,12)
	lowercase_atlas.add_offset("g",0,18)
	lowercase_atlas.add_offset("i",0,4)
	lowercase_atlas.add_offset("l",0,0)
	lowercase_atlas.add_offset("x",0,0)
	lowercase_atlas.add_offset("r",0,0)
	lowercase_atlas.add_offset("t",0,-16)
	
	#bold_atlas.add_offset("f",8,0)
	
func _physics_process(_delta):
	update()

func _draw():
	var anim_name:String=""
	var color:=Color.white
	var effect:String=""
	var shake:=Vector2()
	var is_bold:bool=false
	var space_width:int=64
	var pos_x:int=-64
	var i:int=-1
	
	while i<len(text)-1:
		i+=1
		if text[i]==" ":
			pos_x+=space_width
			continue
		
		if text[i]=="/":
			if str(text[i+1]).to_lower()=="b":
				is_bold=!is_bold
				i+=1
			if str(text[i+1]).to_lower()=="f":
				effect=effects[int(text[i+2])] if int(text[i+2]) in range(0,effects.size()) else "default"
				i+=2
			elif str(text[i+1]).to_lower()=="c":
				color=colors[int(text[i+2])]if int(text[i+2]) in range(0,colors.size()) else Color.white
				i+=2
			continue
		
		anim_name=str(text[i]).to_lower()
		
		match effect:
			"default":
				shake=Vector2()
			"shake":
				randomize()
				shake=Vector2(rand_range(-shake_len.x,shake_len.x),rand_range(-shake_len.y,shake_len.y))
			"wave":
				shake.x=cos(i+OS.get_ticks_msec()/wave_spd)*wave_len.x
				shake.y=sin(i+OS.get_ticks_msec()/wave_spd)*wave_len.y
		
		if false: # This will show each letter origin
			draw_rect(Rect2(pos_x+shake.x,64,4,4),Color.red,true)
			
		var atlas:AnimatedAtlas=lowercase_atlas
		atlas=(lowercase_atlas if not text[i]==str(text[i]).to_upper() else capital_atlas) if !is_bold else bold_atlas
		atlas=symb_atlas if text[i] in symbols else atlas
		atlas=nmb_atlas if text[i] in numbers else atlas
		
		var letter_region:Rect2=atlas.get_frame_region(anim_name,int(OS.get_ticks_msec()/60)%4)

		draw_texture_rect_region(
			atlas.texture,
			Rect2(
				(pos_x+atlas.get_anim_offset(anim_name).x)+shake.x,(64+atlas.get_anim_offset(anim_name).y)+shake.y,
				letter_region.size.x,letter_region.size.y
			),
			letter_region,
			color
		)
		
		pos_x+=letter_region.size.x+2
	width=pos_x
	
	if false: # Just to check how allign everything is
		draw_line(Vector2(0,64),Vector2(pos_x,64),Color.red,4)
	
func clear_cache():
	for i in [lowercase_atlas,capital_atlas,bold_atlas,nmb_atlas,symb_atlas]:
		i.clear_cache()
	text=""
