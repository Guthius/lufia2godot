class_name SpeechBubble extends Node2D

@onready var container: MarginContainer = $Container
@onready var label: Label = $Container/NinePatchRect/Label
@onready var timer: Timer = $Timer
@onready var stem: Sprite2D = $Container/NinePatchRect/Stem

signal closed()

const BORDER_WIDTH: int = 16
const BORDER_HEIGHT: int = 16

const CHAR_WIDTH: int = 16
const CHAR_HEIGHT: int = 32

const STEM_WIDTH: int = 32
const STEM_HEIGHT: int = 48

var wait_for_next_page: bool = false

var target_actor: Node2D
var target_facing:  Enums.Direction =  Enums.Direction.DOWN
var current_pages: Array[String]
var current_page: int = 0
var current_lines: PackedStringArray
var current_line_index: int = 0
var current_line: String = ""
var char_index: int = 0
	
func show_text(actor: Node2D, facing: Enums.Direction, pages: Array[String]) -> void:
	target_actor = actor
	target_facing = facing
	current_pages = pages
	if current_pages.size() == 0:
		return;
	
	_show_page(0)

func get_stem_sprite() -> int:
	match target_facing:
		Enums.Direction.UP:
			return 1
		Enums.Direction.RIGHT:
			return 2
		_:
			return 3

func _update_stem_position() -> void:
	var x = container.size.x / 2
	match target_facing:
		Enums.Direction.RIGHT:
			x = x - 48
		_:
			x = x + 16
	
	var y = container.size.y - BORDER_HEIGHT
	if target_facing == Enums.Direction.UP:
		y = 0 - STEM_HEIGHT + BORDER_HEIGHT
	
	stem.frame = get_stem_sprite()
	stem.position = Vector2(x, y)

func _update_position():
	if target_actor == null:
		stem.visible = false
		return
		
	var x = target_actor.position.x - container.size.x / 2
	var y = target_actor.position.y - container.size.y - 24
	if target_facing == Enums.Direction.UP:
		y = target_actor.position.y + 24
	
	container.position = Vector2(x, y)
	_update_stem_position()

func _layout_bubble():
	var box_height = current_lines.size() * CHAR_HEIGHT + BORDER_HEIGHT * 2
	var box_width = 0
	for line in current_lines:
		var line_width = line.length() * CHAR_WIDTH + BORDER_WIDTH * 2
		if line_width > box_width:
			box_width = line_width
	container.size = Vector2(box_width, box_height)
	_update_position()

func _show_page(page_index: int):
	char_index = 0
	current_page = page_index
	current_lines = current_pages[page_index].split('\n')
	current_line_index = 0
	current_line = current_lines[0]
	_layout_bubble()
	label.text = ""
	_display_letter()

func _display_next_page():
	var next_page = current_page + 1
	if next_page >= current_pages.size():
		queue_free()
		closed.emit()
		return
	_show_page(next_page)

func _display_next_line():
	current_line_index += 1
	if current_line_index >= current_lines.size():
		wait_for_next_page = true
		return
	label.text += "\n"
	current_line = current_lines[current_line_index]
	char_index = 0
	timer.start(0.025)

func _display_letter():
	if char_index >= current_line.length():
		_display_next_line()
		return
	label.text += current_line[char_index]
	char_index += 1
	timer.start(0.025)

func _input(event: InputEvent) -> void:
	if not wait_for_next_page:
		return
	if event.is_action_pressed("ui_accept"):
		_display_next_page()

func _on_timer_timeout() -> void:
	_display_letter()
