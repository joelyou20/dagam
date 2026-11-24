extends Button
signal inspect(card: Dictionary)
signal picked(card: Dictionary)
signal dropped(data: Dictionary, destination: Dictionary)
var card: Dictionary={}
var destination: Dictionary={}
var draggable:=false
var is_attacker:=false
var texture: Texture2D
static var textures: Dictionary={}
static func art(id: String) -> Texture2D:
 if textures.has(id): return textures[id]
 var path: String="res://assets/cards/"+id+".hextex"
 if not FileAccess.file_exists(path): return null
 var image:=Image.new()
 if image.load_webp_from_buffer(FileAccess.get_file_as_bytes(path))!=OK: return null
 textures[id]=ImageTexture.create_from_image(image)
 return textures[id]
func configure(value: Dictionary,dest: Dictionary,size:=Vector2(112,148),glow:=false) -> void:
 card=value
 destination=dest
 custom_minimum_size=size
 mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 var style:=StyleBoxFlat.new()
 style.bg_color=Color("141c30")
 style.border_color=Color("66718b") if value.is_empty() else Color("7cb8ff") if value.get("owner",0)==0 else Color("e88f9c")
 style.set_border_width_all(2)
 style.set_corner_radius_all(8)
 if glow:
  style.shadow_color=Color(1,1,1,0.65)
  style.shadow_size=6
  style.border_color=Color.WHITE
  var pulse:=create_tween().set_loops()
  pulse.tween_property(style,"shadow_color",Color(1,1,1,0.15),1.1)
  pulse.tween_property(style,"shadow_color",Color(1,1,1,0.65),1.1)
 add_theme_stylebox_override("normal",style)
 var hover=style.duplicate()
 hover.border_color=Color("f0d499")
 add_theme_stylebox_override("hover",hover)
 add_theme_stylebox_override("focus",hover)
 if value.is_empty(): text=dest.get("label","Empty")
 else:
  texture=art(value.id)
  var image:=TextureRect.new()
  image.texture=texture
  image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  image.mouse_filter=Control.MOUSE_FILTER_IGNORE
  add_child(image)
  if value.has("hp"):
   var stats:=Label.new()
   stats.text="%s ATK  %s HP"%[value.get("attack",0),value.hp]
   if value.get("shield",0)>0: stats.text+=" ◇%s"%value.shield
   if value.get("ward",0)>0: stats.text+=" W%s"%value.ward
   stats.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
   stats.add_theme_font_size_override("font_size",14)
   stats.add_theme_color_override("font_shadow_color",Color.BLACK)
   stats.add_theme_constant_override("shadow_outline_size",6)
   stats.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
   stats.position.y=-23
   stats.mouse_filter=Control.MOUSE_FILTER_IGNORE
   add_child(stats)
 pressed.connect(func(): picked.emit(card))
 mouse_entered.connect(func():
  if not card.is_empty(): inspect.emit(card))
func _get_drag_data(_position: Vector2):
 if not draggable or card.is_empty(): return null
 var preview:=TextureRect.new()
 preview.texture=texture
 preview.custom_minimum_size=Vector2(100,148)
 preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 set_drag_preview(preview)
 return {"kind":"attack" if is_attacker else "hand","uid":card.uid}
func _can_drop_data(_position: Vector2,data) -> bool:
 return data is Dictionary and data.has("uid") and destination.get("accept",false)
func _drop_data(_position: Vector2,data) -> void:
 dropped.emit(data,destination)
