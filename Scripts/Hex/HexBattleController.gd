extends Control
const Bridge=preload("res://Scripts/Hex/HexSession.gd")
const Card=preload("res://Scripts/Hex/HexCardUI.gd")
var engine: RefCounted
signal return_requested
var definitions: Dictionary={}
var selected:=""
var paused:=false
var ai_timer: Timer
var modal: Window
var board: Control
var stage: Control
var inspection: PanelContainer
var enemy_summary: Label
var player_summary: Label
var hand_snapshot: Dictionary = {}
var hand: HBoxContainer
var controls: VBoxContainer
var subtitle: Label
var notice: Label
var preview: TextureRect
var description: RichTextLabel
var overlay: Control
var positions: Dictionary={}
var phase_shown:=""
var announcement: Label
var announce_tween: Tween
var effect_sound: AudioStreamPlayer
var music: AudioStreamPlayer
var board_card_size := Vector2(140, 110)
var hand_card_size := Vector2(110, 160)
var hand_scroller: ScrollContainer
var new_game_button: Button

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	engine=HexManager.session
	paused=true
	_layout()
	engine.fault.connect(_error)
	resized.connect(_resize_battle)
	_resize_battle.call_deferred()
func set_battle_active(active: bool) -> void:
	if not active:
		paused=true
		ai_timer.stop()
		_close()
		HexManager.save_match()
		music.stop()
		stage.set_active(false)
		return
	if not HexManager.ensure_match():
		_error(engine.last_error)
		return
	paused=false
	stage.set_active(true)
	for c in engine.catalog.cards: definitions[c.id]=c
	notice.text=("Encounter · " + str(HexManager.encounter_metadata().get("name", "Enemy"))) if HexManager.is_encounter() else "20 cards · Draw 5 · Six creature defeats to win"
	_refresh()
	_schedule_ai()
	if engine.state.get("winner")==null and music.stream!=null: music.play()

func _button(parent: Node,text: String,callback: Callable) -> Button:
	var b:=Button.new()
	b.text=text
	b.custom_minimum_size.y=34
	parent.add_child(b)
	b.pressed.connect(callback)
	if text in ["Begin combat","Finish combat","End turn","Return to world"]:
		b.custom_minimum_size=Vector2(172,76)
		var style=StyleBoxFlat.new();style.bg_color=Color("3c715e");style.border_color=Color("e7ce91");style.set_border_width_all(3);style.set_corner_radius_all(36)
		b.add_theme_stylebox_override("normal",style)
		b.add_theme_font_size_override("font_size",19)
	return b
func _text(parent: Node,text: String) -> Label:
	var label:=Label.new()
	label.text=text
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x=160
	parent.add_child(label)
	return label
func _clear(node: Node) -> void:
	for child in node.get_children(): node.remove_child(child);child.queue_free()
func _layout() -> void:
	var app_theme=Theme.new()
	app_theme.default_font_size=16
	var normal=StyleBoxFlat.new()
	normal.bg_color=Color("203635");normal.border_color=Color("9eae89");normal.set_border_width_all(1);normal.set_corner_radius_all(9)
	normal.content_margin_left=12;normal.content_margin_right=12;normal.content_margin_top=6;normal.content_margin_bottom=6
	app_theme.set_stylebox("normal","Button",normal)
	var hover=normal.duplicate();hover.bg_color=Color("3e6152");hover.border_color=Color("f4db9d")
	app_theme.set_stylebox("hover","Button",hover);app_theme.set_stylebox("pressed","Button",hover)
	var panel_style=StyleBoxFlat.new();panel_style.bg_color=Color(0.06,0.13,0.13,0.94);panel_style.border_color=Color("6e8a74");panel_style.set_border_width_all(1);panel_style.set_corner_radius_all(12)
	panel_style.content_margin_left=10;panel_style.content_margin_right=10;panel_style.content_margin_top=10;panel_style.content_margin_bottom=10
	app_theme.set_stylebox("panel","PanelContainer",panel_style)
	theme=app_theme
	var background=ColorRect.new();background.color=Color("101e20");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);background.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(background)
	stage=preload("res://Scripts/Hex/HexBoard3D.gd").new()
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.offset_top=42;stage.offset_bottom=-145
	add_child(stage)
	board=Control.new()
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board.mouse_filter=Control.MOUSE_FILTER_IGNORE
	stage.add_child(board)
	var header=HBoxContainer.new()
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_left=18;header.offset_top=8;header.offset_right=-18
	header.add_theme_constant_override("separation",8)
	add_child(header)
	var logo=Label.new();logo.text="H E X  /  ELDER GROVE";logo.add_theme_color_override("font_color",Color("ead7ac"));header.add_child(logo)
	subtitle=Label.new();subtitle.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(subtitle)
	_button(header,"Deck",_starter)
	_button(header,"Chronicle",_log)
	_button(header,"Concede",_concede)
	new_game_button=_button(header,"New battle",_new_game)
	_button(header,"Leave",func(): return_requested.emit())
	_button(header,"♪",func(): AudioServer.set_bus_mute(0,not AudioServer.is_bus_mute(0)))
	enemy_summary=Label.new();enemy_summary.position=Vector2(22,56);add_child(enemy_summary)
	player_summary=Label.new();player_summary.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT);player_summary.position=Vector2(22,-176);add_child(player_summary)
	var turn_panel=PanelContainer.new()
	turn_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	turn_panel.position=Vector2(-202,-70);turn_panel.size=Vector2(184,170)
	add_child(turn_panel)
	controls=VBoxContainer.new();controls.add_theme_constant_override("separation",8);turn_panel.add_child(controls)
	inspection=PanelContainer.new();inspection.position=Vector2(16,100);inspection.size=Vector2(210,350);inspection.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(inspection)
	var inspect_box=VBoxContainer.new();inspect_box.mouse_filter=Control.MOUSE_FILTER_IGNORE;inspection.add_child(inspect_box)
	preview=TextureRect.new();preview.custom_minimum_size=Vector2(200,245);preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;preview.mouse_filter=Control.MOUSE_FILTER_IGNORE;inspect_box.add_child(preview)
	description=RichTextLabel.new();description.custom_minimum_size=Vector2(200,110);description.bbcode_enabled=true;description.mouse_filter=Control.MOUSE_FILTER_IGNORE;inspect_box.add_child(description)
	inspection.visible=false
	var hand_scroll=ScrollContainer.new();hand_scroller=hand_scroll
	hand_scroll.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hand_scroll.offset_left=210;hand_scroll.offset_right=-205;hand_scroll.offset_top=-145;hand_scroll.offset_bottom=-8
	hand_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	add_child(hand_scroll)
	hand=HBoxContainer.new();hand.add_theme_constant_override("separation",-14);hand.alignment=BoxContainer.ALIGNMENT_CENTER;hand.size_flags_horizontal=Control.SIZE_EXPAND_FILL;hand_scroll.add_child(hand)
	notice=Label.new();notice.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);notice.offset_left=22;notice.offset_top=-24;notice.offset_right= -22;notice.mouse_filter=Control.MOUSE_FILTER_IGNORE;notice.add_theme_font_size_override("font_size",13);add_child(notice)
	overlay=Control.new();overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(overlay)
	music=AudioStreamPlayer.new();music.volume_db=-24;add_child(music)
	if ResourceLoader.exists("res://Assets/Hex/battle.mp3"):
		music.stream=load("res://Assets/Hex/battle.mp3");music.finished.connect(func(): music.play())
	effect_sound=AudioStreamPlayer.new();add_child(effect_sound)
	ai_timer=Timer.new();ai_timer.one_shot=true;ai_timer.wait_time=0.85;ai_timer.timeout.connect(_ai_tick);add_child(ai_timer)

func _def(id: String) -> Dictionary:
	return definitions.get(id.replace("-FA","").replace("-IR",""),{})
func _inspect(c: Dictionary) -> void:
	if c.is_empty(): return
	inspection.visible=true
	preview.texture=Card.art(c.id)
	var d:=_def(c.id)
	var tags: Array=[]
	for k in d.get("keywords",[]):
		for entry in engine.catalog.keywords:
			if entry.id==k.id: tags.append(entry.name.replace(" X"," "+str(k.get("value",""))))
	description.text="[b]%s[/b]\n%s · %s\n[color=#e8d099]%s[/color]\n%s"%[d.get("name",c.id),d.get("card_type",""),d.get("subtype","")," · ".join(tags),d.get("rules","")]
func _card(parent: Node,c,dest: Dictionary,size:=board_card_size,glow:=false):
	var button=Card.new()
	parent.add_child(button)
	var display: Dictionary = c.duplicate() if c!=null else {}
	if c!=null: display["display_name"] = _def(c.id).get("name", c.id)
	button.configure(display,dest,size,glow)
	button.inspect.connect(_inspect)
	button.mouse_exited.connect(func(): inspection.visible=false)
	button.picked.connect(func(value): _clicked(value,dest))
	button.dropped.connect(_drop)
	if c!=null:
		button.draggable=dest.get("zone","")=="hand" or (c.get("owner",-1)==0 and c.get("ready",false))
		button.is_attacker=dest.get("zone","")=="board"
		button.tooltip_text=_def(c.id).get("name",c.id)
		positions[c.uid]=button
	return button
func _refresh() -> void:
	var g: Dictionary=engine.state
	if g.is_empty(): return
	new_game_button.disabled = HexManager.is_encounter()
	_clear(board);_clear(hand);_clear(controls)
	positions={}
	subtitle.text="  Turn %d · %s · %s"%[g.turn,"You" if g.active==0 else "Opponent",str(g.phase).capitalize()]
	var display=g.duplicate(true)
	for side in [0,1]:
		for c in display.players[side].board+display.players[side].artifacts:
			if c!=null: c["display_name"]=_def(c.id).get("name",c.id)
	if display.field!=null: display.field["display_name"]=_def(display.field.id).get("name",display.field.id)
	stage.sync(display)
	for side in [1,0]:
		var p: Dictionary=g.players[side]
		var summary=enemy_summary if side==1 else player_summary
		summary.text=("OPPONENT" if side==1 else "YOU")+"  ·  %d / 6 defeated  ·  %d in hand"%[p.losses,p.handCount]
		for zone in ["board","artifact"]:
			var cards=p.board if zone=="board" else p.artifacts
			for slot in range(cards.size()):
				var rect=stage.slot_rect(side,slot,zone)
				var button=_card(board,cards[slot],{"zone":zone,"side":side,"slot":slot,"accept":true},Vector2.ZERO)
				button.position=rect.position;button.size=rect.size
				button.modulate.a=0
		for zone in ["deck","discard"]:
			var count=p.deckCount if zone=="deck" else p.discard.size()
			var pile=_button(board,"%d · %s"%[count,zone.capitalize()],func(): _pile(side,zone))
			var point=stage.camera.unproject_position(Vector3(4.15 if zone=="deck" else 5.5,0.5,-2.8 if side==1 else 2.8))
			pile.position=point-Vector2(40,-28);pile.size=Vector2(80,32)
			pile.add_theme_font_size_override("font_size",13)
		if not p.exile.is_empty():
			var removed=_button(board,"Removed · %d"%p.exile.size(),func(): _pile(side,"exile"))
			removed.position=stage.camera.unproject_position(Vector3(4.4,0.5,-4.4 if side==1 else 4.4))
	var field_rect=stage.slot_rect(0,0,"field")
	var field=_button(board,"Battlefield",func():
		if g.field!=null: _inspect(g.field))
	field.position=field_rect.position;field.size=field_rect.size;field.modulate.a=0.02
	for c in g.players[0].hand: _card(hand,c,{"zone":"hand"},hand_card_size)
	if g.players[0].hand.is_empty(): _text(hand,"Your hand is empty")
	_animate_hand.call_deferred()
	_actions(g)
	var key:="%s-%s-%s"%[g.tick,g.phase,g.winner]
	if key!=phase_shown:
		phase_shown=key
		if g.winner!=null:
			music.stop()
			var track: String="res://Assets/Hex/victory.mp3" if g.winner==0 else "res://Assets/Hex/defeat.mp3"
			if ResourceLoader.exists(track): effect_sound.stream=load(track);effect_sound.play()
			_announce("Victory" if g.winner==0 else "Defeat" if g.winner==1 else "Draw",true)
		elif g.phase in ["pre","combat","post"]: _announce((("Your Turn\n" if g.active==0 else "Enemy’s Turn\n") if g.phase=="pre" else "")+{"pre":"Pre-Combat Phase","combat":"Combat Phase","post":"Post-Combat Phase"}[g.phase])
	if not paused and g.choice!=null and g.choice.player==0 and modal==null: _options(g.choice.label,g.choice.options,"choice")
	elif not paused and g.response!=null and g.response.priority==0 and not g.response.reactions.is_empty() and modal==null: _reaction(g.response)
func _actions(g: Dictionary) -> void:
	if paused: _button(controls,"Resume",func(): paused=false;notice.text="Game resumed.";_refresh();_schedule_ai());return
	if g.winner!=null:
		_text(controls,"Victory" if g.winner==0 else "Defeat" if g.winner==1 else "Draw")
		if g.reason=="emptyField": _text(controls,"A turn ended with no creatures while the opponent still had creatures.")
		if g.reason=="roundLimit": _text(controls,"60 complete rounds reached.")
		if HexManager.is_encounter(): _button(controls,"Return to world",func(): return_requested.emit())
		else: _button(controls,"Play again",_new_game)
	elif g.phase=="coin":
		_text(controls,"Call the coin")
		for call in ["heads","tails"]: _button(controls,call.capitalize(),func(): _command({"op":"coin","call":call}))
	elif g.phase=="coinResult":
		_text(controls,"%s · %s won the flip"%[g.coin.face,"You" if g.coin.winner==0 else "Opponent"])
		if g.coin.winner==0:
			_button(controls,"Go first",func(): _command({"op":"first","side":0}))
			_button(controls,"Go second",func(): _command({"op":"first","side":1}))
		else: _button(controls,"Continue",func(): _command({"op":"first","side":1}))
	elif g.phase=="opening":
		_button(controls,"Keep opening hand",func(): _command({"op":"keep"}))
		if not g.players[0].mulligan: _button(controls,"Redraw once",func(): _command({"op":"mulligan"}))
	elif g.active==0 and g.choice==null and g.response==null:
		_text(controls,{"pre":"Play cards from your hand.","combat":"Click a glowing creature, then an enemy. Or drag your creature to its target.","post":"Play cards and abilities, then end your turn."}.get(g.phase,"Resolve effects"))
		_button(controls,{"pre":"Begin combat","combat":"Finish combat","post":"End turn"}.get(g.phase,"Continue"),func(): _command({"op":"next"}))
		if not g.activeOptions.is_empty(): _button(controls,"Board abilities",func(): _options("Board abilities",g.activeOptions,"active"))
	else:
		_text(controls,"Opponent is thinking…" if g.choice==null or g.choice.player==1 else "Choose a target")
		if g.choice!=null and g.choice.player==0: _button(controls,"Choose target",func(): _options(g.choice.label,g.choice.options,"choice"))
		elif g.response!=null and g.response.priority==0: _button(controls,"Respond",func(): _reaction(g.response))

func _command(command: Dictionary) -> void:
	if paused: return
	if command.op=="new":
		ai_timer.stop()
		if announce_tween!=null: announce_tween.kill()
		if is_instance_valid(announcement): announcement.queue_free()
	var rects: Dictionary={}
	for uid in positions:
		if is_instance_valid(positions[uid]): rects[uid]=positions[uid].get_global_rect()
	var result: Dictionary=HexManager.request(command)
	if result.is_empty(): return
	if not result.get("ok",true): notice.text="That action isn't available now."
	selected=""
	stage.select_attacker("",[])
	HexManager.save_match()
	_refresh()
	_effects(engine.state.get("fx",[]),rects)
	engine.request({"op":"ack"})
	_schedule_ai()
func _ai_can_act() -> bool:
	if paused or engine.state.is_empty(): return false
	var g: Dictionary=engine.state
	if g.winner!=null or g.phase in ["coin","coinResult","opening"]: return false
	var side=g.choice.player if g.choice!=null else g.response.priority if g.response!=null else g.active
	return side==1
func _schedule_ai() -> void:
	if _ai_can_act() and ai_timer.is_stopped(): ai_timer.start()
func _ai_tick() -> void:
	if not _ai_can_act(): return
	var rects: Dictionary={}
	for uid in positions:
		if is_instance_valid(positions[uid]): rects[uid]=positions[uid].get_global_rect()
	var result: Dictionary=HexManager.request({"op":"ai"})
	if result.is_empty(): return
	HexManager.save_match()
	_refresh()
	_effects(engine.state.get("fx",[]),rects)
	engine.request({"op":"ack"})
	_schedule_ai()
func _clicked(c: Dictionary,dest: Dictionary) -> void:
	if not c.is_empty(): _inspect(c)
	if paused or engine.state.get("winner")!=null: return
	if dest.zone=="hand":
		var options: Array=engine.state.handOptions.get(c.uid,[])
		if options.is_empty(): notice.text="This card cannot be played right now.";return
		_options("Play "+_def(c.id).get("name",c.id),options,"play",c.uid)
	elif dest.zone=="board":
		if dest.side==0 and c.get("ready",false):
			selected=c.uid
			stage.select_attacker(selected,engine.state.targets.get(selected,[]))
			notice.text="Choose an enemy target for "+_def(c.id).get("name",c.id)
		elif dest.side==1 and not selected.is_empty(): _command({"op":"attack","attacker":selected,"target":c.get("uid","")})
func _drop(data: Dictionary,dest: Dictionary) -> void:
	if paused: return
	if data.kind=="attack" and dest.zone=="board" and dest.side==1:
		var c=engine.state.players[1].board[dest.slot]
		if c!=null: _command({"op":"attack","attacker":data.uid,"target":c.uid})
	elif data.kind=="hand":
		var options: Array=[]
		var target=""
		if dest.zone=="board" and engine.state.players[dest.side].board[dest.slot]!=null: target=engine.state.players[dest.side].board[dest.slot].uid
		for o in engine.state.handOptions.get(data.uid,[]):
			if not target.is_empty() and o.get("target","")==target: options.append(o)
			elif target.is_empty() and dest.get("side")==0 and o.get("slot",-1)==dest.get("slot",-2):
				var cards: Array=engine.state.players[0].hand.filter(func(c): return c.uid==data.uid)
				if not cards.is_empty():
					var d:=_def(cards[0].id)
					if (dest.zone=="board" and d.card_type=="Creature") or (dest.zone=="artifact" and d.subtype=="Artifact"): options.append(o)
		if options.size()==1: _command({"op":"play","uid":data.uid,"index":options[0].index})
		elif not options.is_empty(): _options("Choose effect",options,"play",data.uid)
		else: notice.text="That isn't a legal target for this card."
func _window(title_text: String,size:=Vector2i(780,620)) -> VBoxContainer:
	_close()
	modal=Window.new()
	modal.title=title_text
	modal.size=size
	modal.min_size=Vector2i(440,300)
	add_child(modal)
	modal.close_requested.connect(_close)
	var margin:=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","top","right","bottom"]: margin.add_theme_constant_override("margin_"+edge,16)
	modal.add_child(margin)
	var box:=VBoxContainer.new()
	margin.add_child(box)
	var heading:=_text(box,title_text)
	heading.add_theme_font_size_override("font_size",22)
	modal.popup_centered()
	return box
func _close() -> void:
	if inspection!=null: inspection.visible=false
	if modal!=null: modal.queue_free();modal=null
func _options(title_text: String,options: Array,op: String,uid:="") -> void:
	var box:=_window(title_text)
	var scroll:=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var grid:=GridContainer.new()
	grid.columns=3
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",12)
	scroll.add_child(grid)
	for o in options:
		var column:=VBoxContainer.new()
		column.custom_minimum_size.x=225
		grid.add_child(column)
		if o.get("card")!=null:
			var c: Dictionary=o.card
			var owner:=_text(column,"YOUR CARD" if c.owner==0 else "ENEMY'S CARD")
			owner.add_theme_color_override("font_color",Color("9ac8ff") if c.owner==0 else Color("f1a0ac"))
			var image=Card.new()
			column.add_child(image)
			image.configure(c,{},Vector2(150,205))
			image.inspect.connect(_inspect)
		var b:=_button(column,o.label,func():
			var command:={"op":op,"index":o.index}
			if not uid.is_empty(): command.uid=uid
			_close()
			_command(command))
		b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size.y=54
	_button(box,"Close" if op!="choice" else "Return to board",_close)
func _reaction(response: Dictionary) -> void:
	var box:=_window("Respond to opponent's card",Vector2i(760,550))
	var row:=HBoxContainer.new()
	row.alignment=BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	if response.trigger!=null: _card(row,response.trigger,{"zone":"inspect"},Vector2(190,270))
	for c in response.reactions:
		var column:=VBoxContainer.new()
		row.add_child(column)
		_card(column,c,{"zone":"inspect"},Vector2(180,260))
		_button(column,"Use "+_def(c.id).get("name",c.id),func(): _close();_options("Choose response",engine.state.handOptions.get(c.uid,[]),"play",c.uid))
	_button(box,"Skip response",func(): _close();_command({"op":"pass"}))
func _gallery(title_text: String,cards: Array) -> void:
	var box:=_window(title_text,Vector2i(900,700))
	var scroll:=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var grid:=GridContainer.new()
	grid.columns=4
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",12)
	scroll.add_child(grid)
	for c in cards: _card(grid,c,{"zone":"inspect"},Vector2(190,270))
	if cards.is_empty(): _text(grid,"No cards here.")
	_button(box,"Close",_close)
func _pile(side: int,zone: String) -> void:
	if zone=="deck":
		if side==1: notice.text="The opponent's deck is hidden.";return
		var saved: Dictionary=engine.request({"op":"save"})
		var cards: Array=saved.game.players[0].deck.duplicate()
		cards.sort_custom(func(a,b): return _def(a.id).get("name",a.id)<_def(b.id).get("name",b.id))
		_gallery("Your deck · unordered",cards)
	else: _gallery(("Your " if side==0 else "Enemy ")+zone,engine.state.players[side][zone])
func _starter() -> void:
	if not engine.catalog.is_empty(): _gallery("Your starter deck · 20 cards",engine.catalog.starter.map(func(id): return {"id":id,"owner":0,"uid":id}))
func _log() -> void:
	var box:=_window("Battle log")
	var log:=RichTextLabel.new()
	log.size_flags_vertical=Control.SIZE_EXPAND_FILL
	log.text="\n".join(engine.state.get("log",[]))
	box.add_child(log)
	_button(box,"Close",_close)
func _new_game() -> void:
	if HexManager.is_encounter(): return
	var box:=_window("New Standard battle",Vector2i(640,380))
	_text(box,"Your starter deck is ready. Select an opponent. Starting replaces the current saved match.")
	var select:=OptionButton.new()
	for enemy in engine.catalog.get("enemies",[]): select.add_item(enemy.name+" · "+enemy.rank)
	box.add_child(select)
	_button(box,"Start game",func():
		var enemy_id: String=engine.catalog.enemies[select.selected].id
		_close()
		paused=false
		_command({"op":"new","seed":int(Time.get_unix_time_from_system()),"enemy":enemy_id}))
	_button(box,"Cancel",_close)
func _concede() -> void:
	var box:=_window("Concede this game?",Vector2i(480,300))
	_button(box,"Concede",func(): _close();_command({"op":"concede"}))
	_button(box,"Keep playing",_close)
func _pause() -> void:
	paused=true
	ai_timer.stop()
	notice.text="Game saved. You can close the window safely." if HexManager.save_match() else "Unable to save the match."
	_refresh()
func _error(message: String) -> void:
	paused=true
	if notice!=null: notice.text=message
	push_error(message)
func _announce(message: String,persistent:=false) -> void:
	if announce_tween!=null: announce_tween.kill()
	if is_instance_valid(announcement): announcement.queue_free()
	var label:=Label.new()
	announcement=label
	label.text=message
	label.add_theme_font_size_override("font_size",46)
	label.add_theme_color_override("font_color",Color("f2dfb0"))
	label.add_theme_color_override("font_shadow_color",Color.BLACK)
	label.add_theme_constant_override("shadow_outline_size",8)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.position=Vector2(-350,-32)
	label.size=Vector2(700,80)
	label.pivot_offset=label.size/2
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	overlay.add_child(label)
	var tween:=create_tween().set_parallel()
	announce_tween=tween
	tween.tween_property(label,"scale",Vector2(1.15,1.15),1.6)
	if not persistent:
		tween.tween_property(label,"modulate:a",0,0.7).set_delay(0.9)
		tween.chain().tween_callback(label.queue_free)
func _effects(events: Array,rects: Dictionary) -> void:
	stage.effects(events)
	for event in events:
		var target_data=event.get("target",{})
		var uid: String=event.get("uid",target_data.get("uid","") if target_data is Dictionary else str(target_data))
		if event.kind in ["announcement","destroy","return"]: continue
		if event.kind in ["counter","ward"]:
			_paired_effect(event)
			continue
		if event.kind=="attack":
			for key in ["attacker","defender"]: _flash(event.get(key,""),Color("ff949c"))
		elif event.kind in ["damage","heal","status"]:
			_flash(uid,Color("ff949c") if event.kind=="damage" else Color("a2f4d0") if event.kind=="heal" else Color("eee2b0"))
		elif rects.has(uid) and event.kind in ["destroy","return"]:
			var ghost:=TextureRect.new()
			ghost.texture=Card.art(event.get("id",""))
			ghost.position=rects[uid].position
			ghost.size=rects[uid].size
			ghost.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			ghost.mouse_filter=Control.MOUSE_FILTER_IGNORE
			overlay.add_child(ghost)
			var tween:=create_tween()
			tween.tween_property(ghost,"position:x",ghost.position.x+6,0.06)
			tween.tween_property(ghost,"position:x",ghost.position.x-6,0.06)
			tween.tween_property(ghost,"modulate:a",0,0.4)
			tween.tween_callback(ghost.queue_free)
func _flash(uid: String,color: Color) -> void:
	var target=positions.get(uid)
	if not is_instance_valid(target) or target.destination.get("zone") in ["board","artifact"]: return
	target.modulate=color
	create_tween().tween_property(target,"modulate",Color.WHITE,0.5)
func _paired_effect(event: Dictionary) -> void:
	if event.kind=="ward" and ResourceLoader.exists("res://Assets/Hex/ward.wav"):
		effect_sound.stream=load("res://Assets/Hex/ward.wav")
		effect_sound.play()
	var row:=HBoxContainer.new()
	row.position=size/2-Vector2(180,145)
	row.mouse_filter=Control.MOUSE_FILTER_IGNORE
	overlay.add_child(row)
	for key in ["target","source"]:
		var c=event.get(key)
		if not c is Dictionary or not c.has("id"): continue
		var image:=TextureRect.new()
		image.texture=Card.art(c.id)
		image.custom_minimum_size=Vector2(175,260)
		image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.mouse_filter=Control.MOUSE_FILTER_IGNORE
		row.add_child(image)
		var tween:=create_tween()
		if event.kind=="ward" and key=="target":
			image.modulate=Color("a8e5ff")
			tween.tween_property(image,"scale",Vector2(1.05,1.05),0.12)
			tween.tween_property(image,"scale",Vector2.ONE,0.12)
		elif key=="target":
			tween.tween_property(image,"position:x",8,0.06)
			tween.tween_property(image,"position:x",-8,0.06)
		tween.tween_interval((0.7 if key=="target" else 0.25) if event.kind=="ward" else (0.25 if key=="target" else 0.6))
		tween.tween_property(image,"modulate:a",0,0.35)
	create_tween().tween_interval(1.3).finished.connect(row.queue_free)

func _exit_tree() -> void:
	paused=true
	if is_instance_valid(music): music.stop();music.stream=null
	if is_instance_valid(effect_sound): effect_sound.stop();effect_sound.stream=null

func _resize_battle() -> void:
	if not is_instance_valid(hand_scroller): return
	var h=clampf(size.y*0.23,125,200)
	hand_scroller.offset_top=-h
	stage.offset_bottom=-h+10
	hand_card_size=Vector2((h-14)*0.66,h-14)
	if engine != null and not engine.state.is_empty(): _refresh.call_deferred()

func _animate_hand():
	if not is_instance_valid(hand): return
	var next={}
	for card in hand.get_children():
		if not card is Button or card.card.is_empty(): continue
		var uid=card.card.uid;next[uid]=true
		if card.has_meta("animated"): continue
		card.set_meta("animated",true)
		if not hand_snapshot.has(uid):
			var ghost=TextureRect.new();ghost.texture=Card.art(card.card.id);ghost.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;ghost.mouse_filter=Control.MOUSE_FILTER_IGNORE;ghost.size=card.size;overlay.add_child(ghost)
			ghost.position=stage.position+stage.camera.unproject_position(Vector3(4.6,0.5,2.8));ghost.rotation=0.28
			card.modulate.a=0
			var card_ref=weakref(card)
			var tween=create_tween().set_parallel()
			tween.tween_property(ghost,"position",card.global_position-global_position,0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(ghost,"rotation",0.0,0.5)
			tween.chain().tween_callback(func():
				if card_ref.get_ref()!=null: card_ref.get_ref().modulate.a=1
				ghost.queue_free())
		card.mouse_entered.connect(func():
			card.z_index=20
			card.pivot_offset=card.size/2
			create_tween().tween_property(card,"scale",Vector2(1.12,1.12),0.14))
		card.mouse_exited.connect(func():
			card.z_index=0
			create_tween().tween_property(card,"scale",Vector2.ONE,0.14)
			inspection.visible=false)
	hand_snapshot=next

func confirm_leave_encounter() -> void:
	var box := _window("Leave this encounter?",Vector2i(520,320))
	_text(box,"Leaving counts as a defeat. The enemy stays in the world and no victory XP is awarded.")
	_button(box,"Concede and return",func():
		_close()
		_command({"op":"concede"})
		return_requested.emit())
	_button(box,"Keep playing",_close)
