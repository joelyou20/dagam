extends Control
## Presentation only: the native rules engine remains authoritative.
signal impact(uid: String, amount, positive: bool)
const Card = preload("res://Scripts/Hex/HexCardUI.gd")
const RENDER_SCALE := 1.5
const SHADOW_SHADER = preload("res://Resources/Hex/Shaders/contact_shadow.gdshader")
const PORTRAIT_SHADER = preload("res://Resources/Hex/Shaders/card_portrait.gdshader")
var viewport: SubViewport
var world: Node3D
var camera: Camera3D
var pieces: Dictionary = {}
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
	screen.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	screen.texture = viewport.get_texture()
	world = Node3D.new()
	viewport.add_child(world)
	var image = Image.new()
	image.load_webp_from_buffer(FileAccess.get_file_as_bytes("res://Assets/Hex/back.hextex"))
	image.generate_mipmaps()
	back_texture = ImageTexture.create_from_image(image)
	_build_scenery()
	enemy_hand = Node3D.new()
	world.add_child(enemy_hand)
	resized.connect(_resize)
	_resize()


func _resize():
	if viewport == null:
		return
	viewport.size = Vector2i(
		maxi(2, int(ceil(size.x * RENDER_SCALE))), maxi(2, int(ceil(size.y * RENDER_SCALE)))
	)
	# Preserve all lanes on both narrow and wide windows.
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = maxf(17.5, 9.4 * size.x / maxf(1, size.y))
	camera.position = Vector3(1.35, 10, 12.65)
	camera.look_at(Vector3(1.35, 0, 0.65))


func project(point: Vector3) -> Vector2:
	return camera.unproject_position(point) * size / Vector2(viewport.size)


func set_active(value: bool):
	active = value
	if viewport:
		viewport.render_target_update_mode = (
			SubViewport.UPDATE_ALWAYS if value else SubViewport.UPDATE_DISABLED
		)
	set_process(value)


func material(color: Color, emission := false) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	if emission:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 1.8
	return m


func mesh(shape: Mesh, pos: Vector3, color: Color, parent: Node3D = world) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh = shape
	node.position = pos
	node.material_override = material(color)
	parent.add_child(node)
	return node


func box(pos: Vector3, dimensions: Vector3, color: Color, parent: Node3D = world):
	var shape = BoxMesh.new()
	shape.size = dimensions
	return mesh(shape, pos, color, parent)


func cylinder(pos: Vector3, radius: float, height: float, color: Color, parent: Node3D = world):
	var shape = CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius * 1.08
	shape.height = height
	shape.radial_segments = 12
	return mesh(shape, pos, color, parent)


func _build_scenery():
	var env = WorldEnvironment.new()
	var settings = Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("172c31")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("b5d8dc")
	settings.ambient_light_energy = 0.35
	settings.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.environment = settings
	world.add_child(env)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.light_color = Color("ffe5b5")
	sun.light_energy = 0.9
	sun.shadow_enabled = true
	world.add_child(sun)
	camera = Camera3D.new()
	camera.fov = 48
	camera.current = true
	world.add_child(camera)
	var earth = box(Vector3(0, -0.65, 0), Vector3(40, 0.5, 35), Color("56664c"))
	earth.material_override.albedo_texture = load("res://Assets/Textures/Dirt/Dirt_Albedo.tga")
	earth.material_override.uv1_scale = Vector3(8, 8, 8)
	var foundation = box(Vector3(0, -0.23, 0), Vector3(13.8, 0.7, 11.5), Color("839c8c"))
	foundation.material_override.albedo_texture = load(
		"res://Assets/Textures/Cliff Face Mossy/CliffFaceMossy_Albedo.tga"
	)
	foundation.material_override.uv1_scale = Vector3(3, 1, 3)
	box(Vector3(0, 0.14, 0), Vector3(13.4, 0.12, 11.1), Color("566268"))
	# Individual slate tiles and seams form the arena floor.
	var tiles = MultiMeshInstance3D.new()
	var instances = MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_colors = true
	var tile_shape = BoxMesh.new()
	tile_shape.size = Vector3(0.97, 0.08, 0.97)
	instances.mesh = tile_shape
	instances.instance_count = 143
	var tile_material = material(Color.WHITE)
	tile_material.vertex_color_use_as_albedo = true
	tiles.material_override = tile_material
	tiles.multimesh = instances
	world.add_child(tiles)
	var index = 0
	for x in range(-6, 7):
		for z in range(-5, 6):
			instances.set_instance_transform(
				index, Transform3D(Basis.IDENTITY, Vector3(x, 0.23, z))
			)
			instances.set_instance_color(index, Color("526966") if (x + z) % 3 else Color("617671"))
			index += 1
	for x in [-6.85, 6.85]:
		box(Vector3(x, 0.35, 0), Vector3(0.18, 0.5, 11.8), Color("82928a"))
	for z in [-5.75, 5.75]:
		box(Vector3(0, 0.35, z), Vector3(13.9, 0.5, 0.18), Color("82928a"))
	# Deterministic scenery: no random gameplay state is consumed.
	var rng = RandomNumberGenerator.new()
	rng.seed = 817
	for i in range(32):
		var x = rng.randf_range(-13, 13)
		var z = rng.randf_range(-11, 9)
		if absf(x) < 7.6 and absf(z) < 6.5 or z > 4 and absf(x) < 9:
			continue
		var height = rng.randf_range(1.8, 4.4)
		cylinder(Vector3(x, height / 2 - 0.4, z), 0.2, height, Color("57463a"))
		for tier in range(3):
			var crown = CylinderMesh.new()
			crown.top_radius = 0
			crown.bottom_radius = 1.4 - tier * 0.25
			crown.height = 2.1
			crown.radial_segments = 9
			mesh(
				crown,
				Vector3(x, height + tier * 0.65, z),
				Color("2d6753") if i % 2 else Color("3c7855")
			)
	for x in [-7.2, 7.2]:
		for z in [-4.8, 4.8]:
			cylinder(Vector3(x, 0.5, z), 0.45, 1.8, Color("788584"))
			var orb = SphereMesh.new()
			orb.radius = 0.22
			orb.height = 0.44
			var lamp = mesh(orb, Vector3(x, 1.6, z), Color("ffc884"))
			lamp.material_override = material(Color("ffc884"), true)
			var light = OmniLight3D.new()
			light.position = Vector3(x, 1.7, z)
			light.light_color = Color("ffbd73")
			light.light_energy = 2
			light.omni_range = 4
			world.add_child(light)
	# Carved lane dividers and center sigil.
	for x in [-0.7, 2.5]:
		box(Vector3(x, 0.3, 0), Vector3(0.025, 0.015, 9.6), Color("98b6a5"))
	box(Vector3(0.9, 0.3, 0), Vector3(9.5, 0.015, 0.035), Color("e3c88f"))
	# Broken stones and moss at the edge give the arena a place in the forest.
	for x in [-7.7, 7.7]:
		for z in [-3.0, 0.5, 3.5]:
			var rock = SphereMesh.new()
			rock.radius = 0.7
			rock.height = 0.9
			rock.radial_segments = 7
			rock.rings = 4
			mesh(rock, Vector3(x, 0, z), Color("64796b"))


func location(side: int, slot: int, zone := "board") -> Vector3:
	if zone == "artifact":
		return Vector3(-5.5 + slot * 1.4, 0.38, -2.5 if side == 1 else 2.5)
	if zone == "field":
		return Vector3(-4.7, 0.38, 0)
	return Vector3(
		-2.3 + (slot % 3) * 3.2, 0.52, (-1 if side == 1 else 1) * (1.4 if slot < 3 else 4.1)
	)


func key_for(side: int, slot: int, zone := "board") -> String:
	return "%s-%d-%d" % [zone, side, slot]


func slot_rect(side: int, slot: int, zone := "board") -> Rect2:
	var p = location(side, slot, zone)
	var half = Vector2(1.36, 1.18) if zone == "board" else Vector2(0.57, 0.8)
	var r = Rect2(project(p + Vector3(-half.x, 0, -half.y)), Vector2.ZERO)
	for v in [Vector3(half.x, 0, -half.y), Vector3(-half.x, 0, half.y), Vector3(half.x, 0, half.y)]:
		r = r.expand(project(p + v))
	return r


func sync(state: Dictionary):
	for side in [1, 0]:
		for zone in ["board", "artifact"]:
			var cards = (
				state.players[side].board if zone == "board" else state.players[side].artifacts
			)
			for slot in range(cards.size()):
				var c = cards[slot]
				var key = key_for(side, slot, zone)
				_update_piece(key, c, side, slot, zone, state)
	_update_piece(key_for(0, 0, "field"), state.field, 0, 0, "field", state)
	var count = mini(8, state.players[1].handCount)
	if enemy_hand.get_child_count() != count:
		for child in enemy_hand.get_children():
			enemy_hand.remove_child(child)
			child.queue_free()
		for i in range(count):
			var shape = PlaneMesh.new()
			shape.size = Vector2(0.6, 0.85)
			var card = MeshInstance3D.new()
			card.mesh = shape
			card.position = Vector3((i - (count - 1) * 0.5) * 0.5, 0.5, -5.55)
			card.rotation.y = (i - (count - 1) * 0.5) * 0.06
			var m = StandardMaterial3D.new()
			m.albedo_texture = back_texture
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			card.material_override = m
			enemy_hand.add_child(card)


func _update_piece(key: String, c, side: int, slot: int, zone: String, state: Dictionary):
	var id = "empty" if c == null else c.uid
	var old = pieces.get(key)
	if old != null and old.get_meta("uid") == id:
		_update_labels(old, c, state)
		return
	if old != null and old.get_meta("uid") == "empty":
		old.queue_free()
		old = null
	if old != null:
		pieces.erase(key)
		retired[str(old.get_meta("uid"))] = old
		var fade = create_tween()
		fade.tween_interval(0.5)
		fade.tween_property(old, "rotation:z", 0.09, 0.07)
		fade.tween_property(old, "rotation:z", -0.09, 0.07)
		fade.tween_method(
			func(value):
				for child in old.find_children("*", "GeometryInstance3D", true, false):
					child.transparency = value,
			0.0,
			1.0,
			0.3
		)
		fade.parallel().tween_property(old, "scale", Vector3(0.85, 0.85, 0.85), 0.3)
		fade.tween_callback(old.queue_free)
	var node = Node3D.new()
	world.add_child(node)
	node.position = location(side, slot, zone)
	node.set_meta("uid", id)
	node.set_meta("home", node.position)
	node.set_meta("side", side)
	node.set_meta("zone", zone)
	pieces[key] = node
	var visual = Node3D.new()
	visual.name = "Visual"
	node.add_child(visual)
	var dims = Vector3(2.72, 0.13, 2.36) if zone == "board" else Vector3(1.15, 0.08, 1.6)
	var rim = (
		mesh(
			hex_mesh(dims.x, dims.z, dims.y),
			Vector3.ZERO,
			Color("77b9bd") if side == 0 else Color("c59082"),
			visual
		)
		if zone == "board"
		else box(Vector3.ZERO, dims, Color("77b9bd") if side == 0 else Color("c59082"), visual)
	)
	rim.name = "Rim"
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if c == null:
		rim.material_override = material(Color("344b50") if side == 0 else Color("4e494c"))
		return
	var shadow = MeshInstance3D.new()
	shadow.name = "Shadow"
	var shadow_plane = PlaneMesh.new()
	shadow_plane.size = Vector2(dims.x * 1.16, dims.z * 1.18)
	shadow.mesh = shadow_plane
	shadow.position = Vector3(0.09, 0.29 - node.position.y, 0.12)
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(shadow)
	var shadow_material = ShaderMaterial.new()
	shadow_material.shader = SHADOW_SHADER
	shadow.material_override = shadow_material
	var surface = MeshInstance3D.new()
	if zone == "board":
		surface.mesh = hex_mesh(dims.x - 0.13, dims.z - 0.13, 0)
	else:
		var plane = PlaneMesh.new()
		plane.size = Vector2(dims.x - 0.08, dims.z - 0.08)
		surface.mesh = plane
	surface.position.y = dims.y / 2 + 0.01
	surface.name = "Art"
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	visual.add_child(surface)
	var m = ShaderMaterial.new()
	m.shader = PORTRAIT_SHADER
	m.set_shader_parameter("card_art", Card.art(c.id))
	surface.material_override = m
	_update_labels(node, c, state)
	# Cards rise above the arena and settle with a small overshoot.
	node.position += Vector3(0, 1.8, 0.45)
	node.scale = Vector3(0.7, 0.7, 0.7)
	var tween = create_tween().set_parallel()
	(
		tween
		. tween_property(node, "position", node.get_meta("home"), 0.48)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)
	tween.tween_property(node, "scale", Vector3.ONE, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(
		Tween.EASE_OUT
	)


func _update_labels(node: Node3D, c, state: Dictionary):
	if c == null:
		return
	node.set_meta(
		"ready",
		c.get("ready", false) and c.get("owner", 1) == state.active and state.phase == "combat"
	)


func find_piece(uid: String):
	for node in pieces.values():
		if node.get_meta("uid") == uid:
			return node
	var old = retired.get(uid)
	return old if is_instance_valid(old) else null


func effects(events: Array):
	for event in events:
		var target = event.get("target", {})
		var uid = str(event.get("uid", target.get("uid", "") if target is Dictionary else target))
		if event.kind == "attack":
			var attacker = find_piece(str(event.get("attacker", "")))
			var defender = find_piece(str(event.get("defender", "")))
			if attacker != null and defender != null:
				var home: Vector3 = attacker.get_meta("home")
				var tween = create_tween()
				(
					tween
					. tween_property(
						attacker,
						"position",
						home.lerp(defender.position, 0.45) + Vector3.UP * 0.4,
						0.18
					)
					. set_trans(Tween.TRANS_CUBIC)
				)
				(
					tween
					. tween_property(attacker, "position", home, 0.3)
					. set_trans(Tween.TRANS_BACK)
					. set_ease(Tween.EASE_OUT)
				)
			if defender != null:
				_impact(defender, event.get("damage", 0), false)
			if attacker != null and event.get("retaliation", 0) > 0:
				_impact(attacker, event.retaliation, false)
		elif event.kind in ["damage", "heal", "ward", "status"]:
			var node = find_piece(uid)
			if node == null:
				continue
			_impact(
				node,
				event.get("amount", event.get("text", event.kind.to_upper())),
				event.kind != "damage"
			)


func _impact(node: Node3D, amount, positive: bool):
	if str(amount) == "0":
		return
	impact.emit(str(node.get_meta("uid")), amount, positive)
	var shake = create_tween()
	shake.tween_interval(0.15)
	shake.tween_property(node, "rotation:z", 0.07, 0.06)
	shake.tween_property(node, "rotation:z", -0.07, 0.08)
	shake.tween_property(node, "rotation:z", 0.0, 0.12)


func select_attacker(uid: String, targets: Array):
	selected_uid = uid
	legal_targets = targets


func _process(delta):
	time += delta
	for id in retired.keys():
		if not is_instance_valid(retired[id]):
			retired.erase(id)
	for node in pieces.values():
		var visual = node.get_node("Visual")
		var rim = visual.get_node("Rim")
		var color = Color("77b9bd") if node.get_meta("side") == 0 else Color("c59082")
		var glow = (
			node.get_meta("ready", false)
			or node.get_meta("uid") == selected_uid
			or node.get_meta("uid") in legal_targets
		)
		if glow:
			color = (
				Color(0.8, 0.96, 1) * (0.9 + 0.1 * sin(time * 2.4))
				if node.get_meta("side") == 0
				else Color("f8bd72")
			)
		rim.material_override.albedo_color = (
			color if node.get_meta("uid") != "empty" else Color("344b50")
		)
		rim.material_override.emission_enabled = glow
		if glow:
			rim.material_override.emission = color * 0.5
		var desired = (
			0.07 + sin(time * 2.0 + float(node.get_meta("home").x)) * 0.035
			if node.get_meta("ready", false)
			else 0.0
		)
		visual.position.y = lerpf(visual.position.y, desired, minf(1, delta * 6))
		var shadow = node.get_node_or_null("Shadow")
		if shadow != null:
			shadow.position.y = 0.29 - node.position.y


func hex_mesh(width: float, depth: float, thickness: float) -> ArrayMesh:
	var points = [
		Vector2(-1, 0),
		Vector2(-0.5, -1),
		Vector2(0.5, -1),
		Vector2(1, 0),
		Vector2(0.5, 1),
		Vector2(-0.5, 1)
	]
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(6):
		var a = points[i]
		var b = points[(i + 1) % 6]
		var va = Vector3(a.x * width / 2, thickness / 2, a.y * depth / 2)
		var vb = Vector3(b.x * width / 2, thickness / 2, b.y * depth / 2)
		_hex_triangle(surface, Vector3(0, thickness / 2, 0), vb, va, Vector3.UP, width, depth)
		if thickness > 0:
			var ba = va - Vector3.UP * thickness
			var bb = vb - Vector3.UP * thickness
			_hex_triangle(
				surface, Vector3(0, -thickness / 2, 0), ba, bb, Vector3.DOWN, width, depth
			)
			var normal = Vector3((a + b).x, 0, (a + b).y).normalized()
			_hex_triangle(surface, va, vb, ba, normal, width, depth)
			_hex_triangle(surface, vb, bb, ba, normal, width, depth)
	return surface.commit()


func _hex_triangle(
	surface: SurfaceTool,
	a: Vector3,
	b: Vector3,
	c: Vector3,
	normal: Vector3,
	width: float,
	depth: float
):
	for vertex in [a, c, b]:
		surface.set_normal(normal)
		surface.set_uv(Vector2(vertex.x / width + 0.5, vertex.z / depth + 0.5))
		surface.add_vertex(vertex)


func piece_position(uid: String) -> Vector3:
	var node = find_piece(uid)
	return node.position + node.get_node("Visual").position if node != null else Vector3.ZERO
