class_name NPC extends Actor

@export var movement_layer: TileMapLayer
@export var movement_type: MovementType = MovementType.RANDOM
@export var movement_interval_min: float = 1.5
@export var movement_interval_max: float = 2.5
@export var start_direction: Enums.Direction = Enums.Direction.DOWN
@export_multiline var dialogue: Array[String]

@onready var move_timer: Timer = $MoveTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_ray_cast: RayCast2D = $CollisionRayCast

enum MovementType { NONE, RANDOM }

const INVALID_CELL: Vector2 = Vector2(-1, -1)
const SPEECH_BUBBLE = preload("res://Scenes/UI/speech_bubble.tscn")

var current_direction: Enums.Direction
var rng = RandomNumberGenerator.new()
var allowed_tile_id: Vector2
var can_move: bool = false

func _ready() -> void:
	current_direction = start_direction
	allowed_tile_id = _get_tile_id_at(position)
	_play_idle_animation()
	_queue_next_step()

func _get_tile_id_at(tile_pos: Vector2) -> Vector2:
	if movement_layer == null:
		return INVALID_CELL
	var local_pos = Vector2(tile_pos.x / Constants.TILE_SIZE, tile_pos.y / Constants.TILE_SIZE)
	return movement_layer.get_cell_atlas_coords(local_pos)

func _is_direction_blocked() -> bool:
	collision_ray_cast.force_raycast_update()
	return collision_ray_cast.is_colliding()

func _can_move_to(target_pos: Vector2) -> bool:
	if allowed_tile_id == INVALID_CELL:
		return false
	var tile_id = _get_tile_id_at(target_pos)
	return allowed_tile_id == tile_id

func _queue_next_step() -> void:
	var interval = rng.randf_range(movement_interval_min, movement_interval_max)
	move_timer.start(interval)

func _move_to(dir: Enums.Direction) -> bool:
	var dir_vec = get_direction_vector(dir)
	if dir_vec == Vector2.ZERO:
		return false
	collision_ray_cast.rotation = dir_vec.angle() - PI / 2
	if _is_direction_blocked():
		return false
	var target = position + dir_vec * Constants.TILE_SIZE
	if not _can_move_to(target):
		return false
	_play_walk_animation()
	var tween = create_tween()
	tween.tween_property(self, "position", target, .2)
	tween.tween_callback(_on_move_completed)
	return true

func _on_move_completed() -> void:
	_play_idle_animation()
	_queue_next_step()

func _on_move_timer_timeout() -> void:
	if not can_move:
		return
	current_direction = rng.randi_range(0, 3) as Enums.Direction
	if not _move_to(current_direction):
		_play_idle_animation()
		_queue_next_step()
		return

func _play_idle_animation() -> void:
	match current_direction:
		Enums.Direction.DOWN:
			animation_player.play("idle_down")
		Enums.Direction.UP:
			animation_player.play("idle_up")
		Enums.Direction.LEFT:
			animation_player.play("idle_left")
		Enums.Direction.RIGHT:
			animation_player.play("idle_right")

func _play_walk_animation() -> void:
	match current_direction:
		Enums.Direction.DOWN:
			animation_player.play("walk_down")
		Enums.Direction.UP:
			animation_player.play("walk_up")
		Enums.Direction.LEFT:
			animation_player.play("walk_left")
		Enums.Direction.RIGHT:
			animation_player.play("walk_right")

var the_player: Player


func interact(player: Player) -> void:
	if dialogue.size() == 0:
		return
	can_move = false
	the_player = player
	player.deactivate()
	current_direction = Enums.invert_direction(player.current_direction)
	_play_idle_animation()
	var speech_bubble = SPEECH_BUBBLE.instantiate()
	self.get_parent().add_child(speech_bubble)
	speech_bubble.show_text(self, current_direction, dialogue)
	speech_bubble.connect("closed", _on_speech_bubble_closed)

func _on_speech_bubble_closed() -> void:
	can_move = true;
	if the_player != null:
		the_player.activate()
	await get_tree().create_timer(0.025).timeout
	_queue_next_step()
