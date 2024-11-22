extends Sprite2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_open: bool = false

func _on_area_2d_area_entered(_area: Area2D) -> void:
	if is_open:
		return
	animation_player.play("open_door")
	is_open = true
