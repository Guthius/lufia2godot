class_name Actor extends Sprite2D

func get_direction_vector(direction: Enums.Direction) -> Vector2:
	match direction:
		Enums.Direction.UP:
			return Vector2(0, -1)
		Enums.Direction.DOWN:
			return Vector2(0, 1)
		Enums.Direction.LEFT:
			return Vector2(-1, 0)
		Enums.Direction.RIGHT:
			return Vector2(1, 0)
	return Vector2.ZERO
