extends RigidBody2D

func _ready() -> void:
	var mob_types = Array($AnimatedSprite2D.sprite_frames.get_animation_names())
	$AnimatedSprite2D.animation = mob_types.pick_random()
	$AnimatedSprite2D.play()

# Cada frame ajustamos la orientación visual
func _process(float) -> void:
	# El mob ya tiene su velocidad (linear_velocity) gracias a Main
	if linear_velocity.length() > 0:
		# Si va hacia la izquierda -> flip horizontal
		$AnimatedSprite2D.flip_h = linear_velocity.x < 0

		# Evitar que el sprite se "acueste" o rote de cabeza
		rotation = 0

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
