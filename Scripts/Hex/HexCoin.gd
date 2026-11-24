extends Control
## Vector coin: narrowing faces, alternating sides and a rising/falling arc.
signal flip_finished
var angle:=0.0
var lift:=0.0
var flip_tween: Tween
var flipping:=false
func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	custom_minimum_size=Vector2(190,230)
func _draw():
	var center=size/2
	draw_set_transform(center+Vector2(0,76),0,Vector2(1,0.16))
	draw_circle(Vector2.ZERO,48,Color(0,0,0,0.3))
	var width=maxf(0.045,absf(cos(angle)))
	draw_set_transform(center-Vector2(0,lift),0,Vector2(width,1))
	draw_circle(Vector2(5,4),69,Color("8c5420"))
	draw_circle(Vector2.ZERO,69,Color("dfb350"))
	draw_arc(Vector2.ZERO,65,0,TAU,96,Color("ffe5a0"),3,true)
	draw_circle(Vector2.ZERO,59,Color("b77a28") if cos(angle)<0 else Color("d29b39"))
	draw_arc(Vector2.ZERO,55,0,TAU,96,Color("f4d581"),1.5,true)
	for i in range(24):
		var point=Vector2.from_angle(i*TAU/24)
		draw_line(point*61,point*64,Color("966020"),1,true)
	if cos(angle)>=0:
		var star=PackedVector2Array()
		for i in range(12): star.append(Vector2.from_angle(-PI/2+i*PI/6)*(32 if i%2==0 else 16))
		draw_colored_polygon(star,Color("fff0b4"));star.append(star[0]);draw_polyline(star,Color("8b5c22"),2,true)
	else:
		draw_circle(Vector2(-4,0),31,Color("fff0b4"));draw_circle(Vector2(10,-8),28,Color("b77a28"))
	draw_arc(Vector2.ZERO,51,-2.8,-0.8,48,Color(1,0.95,0.7,0.45),4,true)
	draw_set_transform(Vector2.ZERO)
func show_face(face: String):
	stop();angle=PI if face=="tails" else 0.0;lift=0;queue_redraw()
func flip(face: String):
	stop();flipping=true
	var target=TAU*5+(PI if face=="tails" else 0.0)
	flip_tween=create_tween()
	flip_tween.tween_method(func(value):
		angle=lerpf(0,target,value);lift=sin(value*PI)*42;queue_redraw(),0.0,1.0,1.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	flip_tween.tween_callback(func():flipping=false;flip_finished.emit())
func stop():
	if flip_tween!=null: flip_tween.kill()
	flipping=false
