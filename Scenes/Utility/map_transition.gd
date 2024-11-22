extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func fade_out() -> void:
	animation_player.play("fade_out")
	await animation_player.animation_finished

func fade_in() -> void:
	animation_player.play_backwards("fade_out")
	await animation_player.animation_finished
