class_name FloatingTextBubble extends CanvasLayer

@onready var container: MarginContainer = $Control/Container
@onready var label: Label = $Control/Container/NinePatchRect/Label
@onready var timer: Timer = $Timer

signal closed()

const BORDER_WIDTH: int = 16
const BORDER_HEIGHT: int = 16

const CHAR_WIDTH: int = 16
const CHAR_HEIGHT: int = 32

var wait_for_next_page: bool = false

var current_pages: Array[String]
var current_page: int = 0
var current_lines: PackedStringArray
var current_line_index: int = 0
var current_line: String = ""
var char_index: int = 0

func show_text(pages: Array[String]) -> void:
	current_pages = pages
	if current_pages.size() == 0:
		return;
	
	_show_page(0)

func _layout_bubble():
	var box_height = current_lines.size() * CHAR_HEIGHT + BORDER_HEIGHT * 2
	var box_width = 0
	for line in current_lines:
		var line_width = line.length() * CHAR_WIDTH + BORDER_WIDTH * 2
		if line_width > box_width:
			box_width = line_width


	container.size = Vector2(box_width, box_height)
	
	var w = container.size.x * container.scale.x
	var x = (get_viewport().size.x - w) / 2
	var y = 64
	
	container.position = Vector2(x, y)
	
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
