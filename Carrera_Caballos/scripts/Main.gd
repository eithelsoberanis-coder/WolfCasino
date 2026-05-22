extends Control

# ── Datos del juego ──────────────────────────────────────────────
var money: int = 1000
var race_number: int = 1
var bet_amount: int = 100
var bet_horse: int = -1
var racing: bool = false
var race_finished: bool = false

# ── Caballos ─────────────────────────────────────────────────────
const HORSE_NAMES  = ["Relampago", "Tornado", "Ceniza", "Dorado", "Nocturno"]
const HORSE_COLORS = [
	Color(0.95, 0.3,  0.3 ),
	Color(0.3,  0.6,  1.0 ),
	Color(0.75, 0.75, 0.75),
	Color(1.0,  0.8,  0.1 ),
	Color(0.55, 0.2,  0.85),
]
const ODDS = [2.5, 3.0, 4.0, 2.0, 5.0]

var horse_positions: Array = []
var horse_speeds:    Array = []
var horse_boost:     Array = []
var finish_order:    Array = []

const TRACK_START := 0.05
const TRACK_END   := 0.92
const TRACK_TOP   := 20.0
const LANE_H      := 50.0

# ── Nodos UI ──────────────────────────────────────────────────────
@onready var money_label     = $VBox/InfoBar/MoneyLabel
@onready var race_label      = $VBox/InfoBar/RaceLabel
@onready var status_label    = $VBox/InfoBar/StatusLabel
@onready var track_container = $VBox/TrackContainer
@onready var horse_buttons   = $VBox/BettingPanel/BettingVBox/HorseButtons
@onready var bet_input       = $VBox/BettingPanel/BettingVBox/BetRow/BetInput
@onready var start_button    = $VBox/BettingPanel/BettingVBox/BetRow/StartButton
@onready var result_label    = $VBox/ResultLabel

# Los sprites se obtienen directamente de la escena por nombre:
# Horse0, Horse1, Horse2, Horse3, Horse4 dentro de TrackContainer
var horse_sprites: Array = []
var name_labels:   Array = []
var btn_nodes:     Array = []
var finish_line:   ColorRect

# ── Ready ─────────────────────────────────────────────────────────
func _ready() -> void:
	_build_track_bg()
	_collect_horse_sprites()
	_build_horse_buttons()
	start_button.pressed.connect(_on_start_pressed)
	_reset_race()

# ── Fondo de pista (solo el decorado, sin caballos) ───────────────
func _build_track_bg() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.52, 0.35, 0.15)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.z_index = -1
	track_container.add_child(bg)

	for yy in [0.0, TRACK_TOP + LANE_H * HORSE_NAMES.size()]:
		var g := ColorRect.new()
		g.color = Color(0.15, 0.48, 0.15)
		g.position = Vector2(0, yy)
		g.size = Vector2(2000, TRACK_TOP if yy == 0.0 else 30)
		g.z_index = -1
		track_container.add_child(g)

	for i in HORSE_NAMES.size():
		var lane_y: float = TRACK_TOP + i * LANE_H
		var sep := ColorRect.new()
		sep.color = Color(0.38, 0.26, 0.08, 0.5)
		sep.position = Vector2(0, lane_y + LANE_H - 1)
		sep.size = Vector2(2000, 1)
		sep.z_index = -1
		track_container.add_child(sep)

		var num := Label.new()
		num.text = str(i + 1)
		num.position = Vector2(8, lane_y + 14)
		num.add_theme_font_size_override("font_size", 16)
		num.add_theme_color_override("font_color", Color(1, 1, 0.6))
		track_container.add_child(num)

		var lbl := Label.new()
		lbl.text = "%s  x%.1f" % [HORSE_NAMES[i], ODDS[i]]
		lbl.position = Vector2(88, lane_y + 14)
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", Color(1, 1, 0.85))
		track_container.add_child(lbl)
		name_labels.append(lbl)

	finish_line = ColorRect.new()
	finish_line.color = Color(1, 1, 1, 0.9)
	finish_line.size = Vector2(4, LANE_H * HORSE_NAMES.size())
	finish_line.position = Vector2(0, TRACK_TOP)
	track_container.add_child(finish_line)

# ── Recoger los AnimatedSprite2D definidos en la escena ───────────
func _collect_horse_sprites() -> void:
	for i in HORSE_NAMES.size():
		var node_name: String = "Horse%d" % i
		if track_container.has_node(node_name):
			var sprite: AnimatedSprite2D = track_container.get_node(node_name)
			horse_sprites.append(sprite)
		else:
			# Fallback: ColorRect de color si no existe el nodo en escena
			var rect := ColorRect.new()
			rect.color = HORSE_COLORS[i]
			rect.size = Vector2(50, 34)
			track_container.add_child(rect)
			horse_sprites.append(rect)

func _build_horse_buttons() -> void:
	for i in HORSE_NAMES.size():
		var btn := Button.new()
		btn.text = "%s\nx%.1f" % [HORSE_NAMES[i], ODDS[i]]
		btn.custom_minimum_size = Vector2(130, 55)
		btn.add_theme_font_size_override("font_size", 15)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_horse_selected.bind(i))
		horse_buttons.add_child(btn)
		btn_nodes.append(btn)

# ── Reset ─────────────────────────────────────────────────────────
func _reset_race() -> void:
	horse_positions.clear()
	horse_speeds.clear()
	horse_boost.clear()
	finish_order.clear()

	for i in HORSE_NAMES.size():
		horse_positions.append(0.0)
		horse_speeds.append(randf_range(0.003, 0.006))
		horse_boost.append(0.0)
		if horse_sprites[i] is AnimatedSprite2D:
			horse_sprites[i].play("idle")

	racing = false
	race_finished = false
	bet_horse = -1
	result_label.text = ""
	status_label.text = "Estado: Apostando"
	start_button.disabled = false
	bet_input.editable = true
	start_button.text = "CORRER!"

	for b in btn_nodes:
		b.modulate = Color.WHITE
	for i in name_labels.size():
		name_labels[i].text = "%s  x%.1f" % [HORSE_NAMES[i], ODDS[i]]

	_update_horse_visuals()
	_update_ui()

func _update_ui() -> void:
	money_label.text = "Dinero: $%d" % money
	race_label.text = "Carrera #%d" % race_number

func _on_horse_selected(idx: int) -> void:
	if racing:
		return
	bet_horse = idx
	for i in btn_nodes.size():
		btn_nodes[i].modulate = Color(1.5, 1.4, 0.3) if i == idx else Color.WHITE

func _on_start_pressed() -> void:
	if bet_horse == -1:
		result_label.text = "Elige un caballo primero!"
		result_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
		return
	bet_amount = int(bet_input.value)
	if bet_amount > money:
		result_label.text = "No tienes suficiente dinero"
		result_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
		return
	money -= bet_amount
	_update_ui()
	racing = true
	start_button.disabled = true
	bet_input.editable = false
	status_label.text = "Estado: CORRIENDO!"
	result_label.text = "Y arrancan los caballos!"
	result_label.add_theme_color_override("font_color", Color(1, 1, 0.4))
	for i in horse_sprites.size():
		if horse_sprites[i] is AnimatedSprite2D:
			horse_sprites[i].play("correr")

# ── Loop ──────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not racing or race_finished:
		return
	for i in HORSE_NAMES.size():
		horse_boost[i] = lerpf(horse_boost[i], randf_range(-0.002, 0.003), 0.12)
		var spd: float = clampf(horse_speeds[i] + horse_boost[i], 0.001, 0.01)
		horse_positions[i] += spd * delta * 60.0
		if horse_positions[i] >= 1.0 and not finish_order.has(i):
			horse_positions[i] = 1.0
			finish_order.append(i)
	_update_horse_visuals()
	if finish_order.size() == HORSE_NAMES.size():
		_finish_race()

func _update_horse_visuals() -> void:
	var tw: float = track_container.size.x
	if tw < 100.0:
		tw = 1200.0
	var x_start: float = tw * TRACK_START + 30.0
	var x_end: float   = tw * TRACK_END - 10.0
	finish_line.position.x = x_end + 10.0

	for i in horse_sprites.size():
		var px: float = x_start + horse_positions[i] * (x_end - x_start)
		var lane_y: float = TRACK_TOP + i * LANE_H + LANE_H / 2.0
		horse_sprites[i].position = Vector2(px, lane_y)
		name_labels[i].position = Vector2(px + 56.0, TRACK_TOP + i * LANE_H + 14.0)
		var pos_in_finish: int = finish_order.find(i)
		if pos_in_finish >= 0:
			name_labels[i].text = "%s [%d]" % [HORSE_NAMES[i], pos_in_finish + 1]

func _finish_race() -> void:
	race_finished = true
	racing = false
	# Volver a idle al terminar
	for i in horse_sprites.size():
		if horse_sprites[i] is AnimatedSprite2D:
			horse_sprites[i].play("idle")

	var winner: int = finish_order[0]
	if winner == bet_horse:
		var gain: int = int(bet_amount * ODDS[bet_horse])
		money += gain
		result_label.text = "GANASTE! %s llego 1ro  +$%d" % [HORSE_NAMES[winner], gain]
		result_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		status_label.text = "Estado: GANADOR!"
	else:
		var my_pos: int = finish_order.find(bet_horse) + 1
		result_label.text = "Perdiste. Gano %s. Tu caballo (%s) llego %do." % [
			HORSE_NAMES[winner], HORSE_NAMES[bet_horse], my_pos
		]
		result_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		status_label.text = "Estado: Perdiste"
	_update_ui()
	if money <= 0:
		result_label.text += "\nSin dinero! Juego terminado."
		start_button.text = "Reiniciar"
		start_button.disabled = false
		start_button.pressed.disconnect(_on_start_pressed)
		start_button.pressed.connect(_on_restart)
		return
	race_number += 1
	start_button.text = "Siguiente carrera ->"
	start_button.disabled = false
	start_button.pressed.disconnect(_on_start_pressed)
	start_button.pressed.connect(_on_next_race)

func _on_next_race() -> void:
	start_button.pressed.disconnect(_on_next_race)
	start_button.pressed.connect(_on_start_pressed)
	_reset_race()

func _on_restart() -> void:
	money = 1000
	race_number = 1
	start_button.pressed.disconnect(_on_restart)
	start_button.pressed.connect(_on_start_pressed)
	_reset_race()
