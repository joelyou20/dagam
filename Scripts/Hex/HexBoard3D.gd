extends Control
## Presentation only: the native rules engine remains authoritative.
const Card = preload("res://Scripts/Hex/HexCardUI.gd")
var viewport: SubViewport
var world: Node3D
var camera: Camera3D
var pieces: Dictionary = {}
var pile_nodes: Dictionary = {}
var enemy_hand: Node3D
var back_texture: Texture2D
var retired: Dictionary = {}
var selected_uid := ""
var legal_targets: Array = []
var time := 0.0
var active := false
func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var screen = TextureRect.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(screen)
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.transparent_bg = false
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	screen.texture = viewport.get_texture()
	world = Node3D.new()
	viewport.add_child(world)
	var image=Image.new()
	image.load_webp_from_buffer(FileAccess.get_file_as_bytes("res://Assets/Hex/back.hextex"))
	image.generate_mipmaps();back_texture=ImageTexture.create_from_image(image)
	_build_scenery()
	enemy_hand=Node3D.new();world.add_child(enemy_hand)
	resized.connect(_resize)
	_resize()
func _resize():
	if viewport == null: return
	viewport.size = Vector2i(maxi(2,int(size.x)),maxi(2,int(size.y)))
	# Preserve all lanes on both narrow and wide windows.
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect=Camera3D.KEEP_WIDTH
	camera.size=20.0
	camera.position = Vector3(0,10,12)
	camera.look_at(Vector3(0,0,0))
func set_active(value: bool):
	active = value
	if viewport: viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if value else SubViewport.UPDATE_DISABLED
	set_process(value)
func material(color: Color, emission := false) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	if emission: m.emission_enabled=true; m.emission=color; m.emission_energy_multiplier=1.8
	return m
func mesh(shape: Mesh, pos: Vector3, color: Color, parent: Node3D = world) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh=shape; node.position=pos; node.material_override=material(color)
	parent.add_child(node)
	return node
func box(pos: Vector3, dimensions: Vector3, color: Color, parent: Node3D = world):
	var shape=BoxMesh.new();shape.size=dimensions
	return mesh(shape,pos,color,parent)
func cylinder(pos: Vector3, radius: float, height: float, color: Color, parent: Node3D = world):
	var shape=CylinderMesh.new();shape.top_radius=radius;shape.bottom_radius=radius*1.08;shape.height=height;shape.radial_segments=12
	return mesh(shape,pos,color,parent)
func text3d(value: String, pos: Vector3, color: Color, parent: Node3D, font_size := 40):
	var label=Label3D.new()
	label.text=value;label.position=pos;label.font_size=font_size;label.pixel_size=0.008
	label.modulate=color;label.outline_size=7;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test=true
	parent.add_child(label)
	return label
func _build_scenery():
	var env=WorldEnvironment.new();var settings=Environment.new()
	settings.background_mode=Environment.BG_COLOR;settings.background_color=Color("172c31")
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_color=Color("b5d8dc");settings.ambient_light_energy=0.35
	settings.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	env.environment=settings;world.add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-52,-35,0);sun.light_color=Color("ffe5b5");sun.light_energy=0.9;sun.shadow_enabled=true;world.add_child(sun)
	camera=Camera3D.new();camera.fov=48;camera.current=true;world.add_child(camera)
	box(Vector3(0,-0.65,0),Vector3(40,0.5,35),Color("293e32"))
	box(Vector3(0,-0.23,0),Vector3(13.8,0.7,11.5),Color("35444a"))
	box(Vector3(0,0.14,0),Vector3(13.4,0.12,11.1),Color("566268"))
	# Individual slate tiles and seams form the arena floor.
	for x in range(-6,7):
		for z in range(-5,6):
			box(Vector3(x,0.23,z),Vector3(0.97,0.08,0.97),Color("4b5b60") if (x+z)%3 else Color("53696a"))
	for x in [-6.85,6.85]:
		box(Vector3(x,0.35,0),Vector3(0.18,0.5,11.8),Color("82928a"))
	for z in [-5.75,5.75]: box(Vector3(0,0.35,z),Vector3(13.9,0.5,0.18),Color("82928a"))
	# Deterministic scenery: no random gameplay state is consumed.
	var rng=RandomNumberGenerator.new();rng.seed=817
	for i in range(32):
		var x=rng.randf_range(-13,13);var z=rng.randf_range(-11,9)
		if absf(x)<7.6 and absf(z)<6.5 or z>4 and absf(x)<9: continue
		var height=rng.randf_range(1.8,4.4)
		cylinder(Vector3(x,height/2-0.4,z),0.2,height,Color("57463a"))
		for tier in range(3):
			var crown=CylinderMesh.new();crown.top_radius=0;crown.bottom_radius=1.4-tier*0.25;crown.height=2.1;crown.radial_segments=9
			mesh(crown,Vector3(x,height+tier*0.65,z),Color("2d6753") if i%2 else Color("3c7855"))
	for x in [-7.2,7.2]:
		for z in [-4.8,4.8]:
			cylinder(Vector3(x,0.5,z),0.45,1.8,Color("788584"))
			var orb=SphereMesh.new();orb.radius=0.22;orb.height=0.44
			var lamp=mesh(orb,Vector3(x,1.6,z),Color("ffc884"));lamp.material_override=material(Color("ffc884"),true)
			var light=OmniLight3D.new();light.position=Vector3(x,1.7,z);light.light_color=Color("ffbd73");light.light_energy=2;light.omni_range=4;world.add_child(light)
	# Carved lane dividers and center sigil.
	for x in [-1.15,1.15]: box(Vector3(x,0.3,0),Vector3(0.025,0.015,9.6),Color("98b6a5"))
	box(Vector3(0,0.3,0),Vector3(7,0.015,0.035),Color("e3c88f"))
	# Broken stones and moss at the edge give the arena a place in the forest.
	for x in [-7.7,7.7]:
		for z in [-3.0,0.5,3.5]:
			var rock=SphereMesh.new();rock.radius=0.7;rock.height=0.9;rock.radial_segments=7;rock.rings=4
			mesh(rock,Vector3(x,0,z),Color("64796b"))
func location(side: int, slot: int, zone := "board") -> Vector3:
	if zone=="artifact": return Vector3(-5.5+slot*1.4,0.38, -2.5 if side==1 else 2.5)
	if zone=="field": return Vector3(-4.7,0.38,0)
	return Vector3((slot%3-1)*2.3,0.38,(-1 if side==1 else 1)*(1.3 if slot<3 else 3.65))
func key_for(side: int, slot: int, zone := "board") -> String: return "%s-%d-%d"%[zone,side,slot]
func slot_rect(side: int, slot: int, zone := "board") -> Rect2:
	var p=location(side,slot,zone)
	var half=Vector2(1.03,0.87) if zone=="board" else Vector2(0.57,0.8)
	var r=Rect2(camera.unproject_position(p+Vector3(-half.x,0,-half.y)),Vector2.ZERO)
	for v in [Vector3(half.x,0,-half.y),Vector3(-half.x,0,half.y),Vector3(half.x,0,half.y)]: r=r.expand(camera.unproject_position(p+v))
	return r
func sync(state: Dictionary):
	var seen={}
	for side in [1,0]:
		for zone in ["board","artifact"]:
			var cards=state.players[side].board if zone=="board" else state.players[side].artifacts
			for slot in range(cards.size()):
				var c=cards[slot];var key=key_for(side,slot,zone);seen[key]=true
				_update_piece(key,c,side,slot,zone,state)
	_update_piece(key_for(0,0,"field"),state.field,0,0,"field",state)
	for side in [0,1]:
		for zone in ["deck","discard"]:
			var key="%s-%s"%[side,zone]
			var node=pile_nodes.get(key)
			if node==null:
				node=Node3D.new();world.add_child(node);pile_nodes[key]=node
				var shape=PlaneMesh.new();shape.size=Vector2(1.0,1.5)
				var art=MeshInstance3D.new();art.mesh=shape;art.name="Top";art.position.y=0.18;node.add_child(art)
				box(Vector3.ZERO,Vector3(1.06,0.28,1.55),Color("c2bfa5"),node)
				node.position=Vector3(4.4 if zone=="deck" else 6.0,0.45,-2.8 if side==1 else 2.8)
			var cards=state.players[side].discard
			var m=StandardMaterial3D.new();m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
			m.albedo_texture=back_texture if zone=="deck" or cards.is_empty() else Card.art(cards.back().id)
			node.get_node("Top").material_override=m
	var count=mini(8,state.players[1].handCount)
	if enemy_hand.get_child_count()!=count:
		for child in enemy_hand.get_children(): enemy_hand.remove_child(child);child.queue_free()
		for i in range(count):
			var shape=PlaneMesh.new();shape.size=Vector2(0.6,0.85)
			var card=MeshInstance3D.new();card.mesh=shape;card.position=Vector3((i-(count-1)*0.5)*0.5,0.5,-5.1);card.rotation.y=(i-(count-1)*0.5)*0.06
			var m=StandardMaterial3D.new();m.albedo_texture=back_texture;m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;card.material_override=m;enemy_hand.add_child(card)
func _update_piece(key: String, c, side: int, slot: int, zone: String, state: Dictionary):
	var id="empty" if c==null else c.uid
	var old=pieces.get(key)
	if old!=null and old.get_meta("uid")==id:
		_update_labels(old,c,state)
		return
	if old!=null:
		pieces.erase(key)
		retired[str(old.get_meta("uid"))]=old
		var fade=create_tween()
		fade.tween_interval(0.5)
		fade.tween_property(old,"rotation:z",0.09,0.07)
		fade.tween_property(old,"rotation:z",-0.09,0.07)
		fade.tween_method(func(value):
			for child in old.get_children():
				if child is GeometryInstance3D: child.transparency=value
				if child is Label3D: child.modulate.a=1-value,0.0,1.0,0.3)
		fade.parallel().tween_property(old,"scale",Vector3(0.85,0.85,0.85),0.3)
		fade.tween_callback(old.queue_free)
	var node=Node3D.new();world.add_child(node);node.position=location(side,slot,zone)
	node.set_meta("uid",id);node.set_meta("home",node.position);node.set_meta("side",side)
	pieces[key]=node
	var dims=Vector3(2.04,0.06,1.72) if zone=="board" else Vector3(1.15,0.06,1.6)
	var rim=box(Vector3.ZERO,dims,Color("77b9bd") if side==0 else Color("c59082"),node)
	rim.name="Rim"
	if c==null:
		rim.material_override=material(Color("344b50") if side==0 else Color("4e494c"))
		text3d(("FRONT" if slot<3 else "BACK") if zone=="board" else "ARTIFACT" if zone=="artifact" else "BATTLEFIELD",Vector3(0,0.08,0),Color("a7bab7"),node,22)
		return
	var plane=PlaneMesh.new();plane.size=Vector2(dims.x-0.08,dims.z-0.08)
	var surface=MeshInstance3D.new();surface.mesh=plane;surface.position.y=0.05;surface.name="Art";node.add_child(surface)
	var m=ShaderMaterial.new();var shader=Shader.new()
	shader.code="shader_type spatial; render_mode unshaded; uniform sampler2D card_art:filter_linear_mipmap; void fragment(){vec2 uv=UV; uv.y=0.16+uv.y*0.49; ALBEDO=texture(card_art,uv).rgb;}"
	m.shader=shader;m.set_shader_parameter("card_art",Card.art(c.id));surface.material_override=m
	var title=text3d("",Vector3(0,0.13,-0.55),Color("fff5dc"),node,28);title.name="Title"
	var stats=text3d("",Vector3(0,0.16,0.58),Color.WHITE,node,32);stats.name="Stats"
	_update_labels(node,c,state)
	# Cards rise above the arena and settle with a small overshoot.
	node.position+=Vector3(0,1.8,0.45);node.scale=Vector3(0.7,0.7,0.7)
	var tween=create_tween().set_parallel()
	tween.tween_property(node,"position",node.get_meta("home"),0.48).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node,"scale",Vector3.ONE,0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
func _update_labels(node: Node3D,c,state: Dictionary):
	if c==null: return
	var title=node.get_node_or_null("Title");var stats=node.get_node_or_null("Stats")
	if title: title.text=c.get("display_name",c.id)
	if stats: stats.text=("%d  /  %d"%[c.get("attack",0),c.hp])+ ("   ◇%d"%c.get("shield",0) if c.get("shield",0)>0 else "") if c.has("hp") else "ARTIFACT"
	node.set_meta("ready",c.get("ready",false) and c.get("owner",1)==0 and state.active==0 and state.phase=="combat")
func find_piece(uid: String):
	for node in pieces.values():
		if node.get_meta("uid")==uid: return node
	var old=retired.get(uid)
	return old if is_instance_valid(old) else null
func effects(events: Array):
	for event in events:
		var target=event.get("target",{})
		var uid=str(event.get("uid",target.get("uid","") if target is Dictionary else target))
		if event.kind=="attack":
			var attacker=find_piece(str(event.get("attacker","")));var defender=find_piece(str(event.get("defender","")))
			if attacker!=null and defender!=null:
				var home: Vector3=attacker.get_meta("home")
				var tween=create_tween()
				tween.tween_property(attacker,"position",home.lerp(defender.position,0.45)+Vector3.UP*0.4,0.18).set_trans(Tween.TRANS_CUBIC)
				tween.tween_property(attacker,"position",home,0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			if defender!=null: _impact(defender,event.get("damage",0),false)
			if attacker!=null and event.get("retaliation",0)>0: _impact(attacker,event.retaliation,false)
		elif event.kind in ["damage","heal","ward","status"]:
			var node=find_piece(uid)
			if node==null: continue
			_impact(node,event.get("amount",event.get("text",event.kind.to_upper())),event.kind!="damage")
func _impact(node: Node3D,amount,positive: bool):
	if str(amount)=="0": return
	var color=Color("94ffe1") if positive else Color("ffb0a3")
	var pop=text3d(("+" if positive else "−")+str(amount),Vector3(0,0.9,0),color,node,66)
	var tween=create_tween().set_parallel()
	tween.tween_property(pop,"position:y",2.0,0.75)
	tween.tween_property(pop,"modulate:a",0,0.35).set_delay(0.4)
	tween.chain().tween_callback(pop.queue_free)
	var shake=create_tween()
	shake.tween_interval(0.15)
	shake.tween_property(node,"rotation:z",0.07,0.06)
	shake.tween_property(node,"rotation:z",-0.07,0.08)
	shake.tween_property(node,"rotation:z",0.0,0.12)
func select_attacker(uid: String,targets: Array):
	selected_uid=uid;legal_targets=targets
func _process(delta):
	time+=delta
	for id in retired.keys():
		if not is_instance_valid(retired[id]): retired.erase(id)
	for node in pieces.values():
		var rim=node.get_node("Rim")
		var color=Color("77b9bd") if node.get_meta("side")==0 else Color("c59082")
		var glow=node.get_meta("ready",false) or node.get_meta("uid")==selected_uid or node.get_meta("uid") in legal_targets
		if glow: color=Color(0.8,0.96,1)*(0.9+0.1*sin(time*2.4)) if node.get_meta("side")==0 else Color("f8bd72")
		rim.material_override.albedo_color=color if node.get_meta("uid")!="empty" else Color("344b50")
		rim.material_override.emission_enabled=glow
		if glow: rim.material_override.emission=color*0.5
