extends Node2D

@export_category("Start Location")
@export_file("*.tscn") var start_map: String
@export var start_x: float
@export var start_y: float 

@onready var player: Player = $Map/Player

var current_level: Node = null

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0, 0, 0))
	_change_to_map(start_map, start_x, start_y)
	pass

func _on_player_change_map(target_map: String, target_x: float, target_y: float) -> void:
	_change_to_map(target_map, target_x, target_y)

func _change_to_map(map_filename: String, x: float, y: float) -> void:
	get_tree().paused = true
	await MapTransition.fade_out()
	if current_level != null:
		current_level.queue_free()
	player.visible = true
	if map_filename != null:
		var scene = ResourceLoader.load(map_filename)
		if scene != null:
			current_level = scene.instantiate()
			$Map.add_child(current_level)
		else:
			print_debug("Failed to load target map: ", map_filename)
	player.position = Vector2(x, y)
	await MapTransition.fade_in()
	get_tree().paused = false
