class_name Player extends Actor

const FLOATING_TEXT_BUBBLE = preload("res://Scenes/UI/floating_text_bubble.tscn")

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var ray_cast_collision: RayCast2D = $RayCastCollision
@onready var ray_cast_interactibles: RayCast2D = $RayCastInteractibles
@onready var body: Area2D = $Body

signal change_map(target_map: String, target_x: float, target_y: float)

var current_direction: Enums.Direction = Enums.Direction.DOWN
var is_enabled: bool = true
var is_moving: bool = false

func deactivate() -> void:
	is_enabled = false

func activate() -> void:
	await get_tree().create_timer(0.025).timeout
	is_enabled = true

func _interact(obj: Interactible) -> void:
	if obj is Sign:
		is_enabled = false
		var floating_text_bubble = FLOATING_TEXT_BUBBLE.instantiate()
		self.add_child(floating_text_bubble)
		floating_text_bubble.show_text(obj.pages)
		floating_text_bubble.connect("closed", activate)

func _check_for_interaction() -> void:
	var target = get_direction_vector(current_direction)
	if target == Vector2.ZERO:
		return
	ray_cast_interactibles.rotation = target.angle() - PI / 2
	ray_cast_interactibles.force_raycast_update()
	if not ray_cast_interactibles.is_colliding():
		return
	var collider = ray_cast_interactibles.get_collider()
	if collider is Interactible:
		_interact(collider)
		return
	var parent = collider.get_parent()
	if parent is NPC:
		parent.interact(self)

func _process(_delta: float) -> void:
	if not is_enabled:
		return
	if Input.is_action_just_pressed("ui_accept"):
		_check_for_interaction()
		return
	if Input.is_action_pressed("ui_up"):
		move_in_direction(Enums.Direction.UP)
	elif Input.is_action_pressed("ui_down"):
		move_in_direction(Enums.Direction.DOWN)
	elif Input.is_action_pressed("ui_left"):
		move_in_direction(Enums.Direction.LEFT)
	elif Input.is_action_pressed("ui_right"):
		move_in_direction(Enums.Direction.RIGHT)

func set_direction(direction: Enums.Direction) -> void:
	if direction == current_direction:
		return
	current_direction = direction
	show_idle_animation()

func show_idle_animation() -> void:
	match current_direction:
		Enums.Direction.DOWN:
			animation_player.play("idle_down")
		Enums.Direction.UP:
			animation_player.play("idle_up")
		Enums.Direction.LEFT:
			animation_player.play("idle_left")
		Enums.Direction.RIGHT:
			animation_player.play("idle_right")

func show_walk_animation() -> void:
	match current_direction:
		Enums.Direction.DOWN:
			animation_player.play("walk_down")
		Enums.Direction.UP:
			animation_player.play("walk_up")
		Enums.Direction.LEFT:
			animation_player.play("walk_left")
		Enums.Direction.RIGHT:
			animation_player.play("walk_right")

func move_in_direction(direction: Enums.Direction) -> void:	
	if is_moving:
		return
	set_direction(direction)
	var target = get_direction_vector(direction)
	if target == Vector2.ZERO:
		return
	ray_cast_collision.rotation = target.angle() - PI / 2
	ray_cast_collision.force_raycast_update()
	if ray_cast_collision.is_colliding():
		return
	is_moving = true
	var tween = create_tween()
	tween.tween_property(self, "position", position + target * Constants.TILE_SIZE, .12)
	tween.tween_callback(_done_moving)
	show_walk_animation()

func _done_moving():
	is_moving = false
	show_idle_animation()
	check_for_triggers()

func check_for_triggers() -> void:
	if not body.has_overlapping_areas():
		return
	var areas = body.get_overlapping_areas()
	for area in areas:
		if area is Warp:
			change_map.emit(area.target_map, area.target_x, area.target_y)
