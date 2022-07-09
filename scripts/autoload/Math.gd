extends Node

func remap_range(value,min_a,max_a,min_b,max_b):
	return(value-min_a)/(max_a-min_a)*(max_b-min_b)+min_b;

func distance(x1,y1,x2,y2):
	return sqrt(pow(x2-x1,2)+pow(y2-y1,2))
	
