extends Area2D

signal hit

@export var speed = 400
@export var death_animation_prefix := "death"
var screen_size
var last_direction := "down"
var facing_right := true
var is_dead := false
var can_move := false

func _ready() -> void:
	screen_size = get_viewport_rect().size
	hide()
	$AnimatedSprite2D.frame_changed.connect(self._on_frame_changed)
	_update_hitbox()

func _process(delta: float) -> void:
	if is_dead or not can_move:
		return
	
	var velocity = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1
	
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		if abs(velocity.x) > abs(velocity.y):
			last_direction = "sides"
			facing_right = velocity.x > 0
		else:
			last_direction = "down" if velocity.y > 0 else "up"
		$AnimatedSprite2D.animation = last_direction
		$AnimatedSprite2D.flip_h = last_direction == "sides" and not facing_right
		$AnimatedSprite2D.play()
	else:
		if last_direction == "sides":
			$AnimatedSprite2D.animation = "quiet_sides"
			$AnimatedSprite2D.flip_h = not facing_right
		else:
			$AnimatedSprite2D.animation = "quiet_" + last_direction
			$AnimatedSprite2D.flip_h = false
		$AnimatedSprite2D.play()
	
	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)

func _on_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	is_dead = true
	$CollisionShape2D.disabled = true
	_play_death_animation()
	hit.emit()

func _play_death_animation():
	var anim_name = death_animation_prefix + "_" + last_direction
	if $AnimatedSprite2D.sprite_frames.has_animation(anim_name):
		$AnimatedSprite2D.animation = anim_name
		$AnimatedSprite2D.play()
	
	var tween = create_tween()
	var duration := 1.0
	var flashes := 5
	var half_flash_time = duration / (flashes * 2)
	
	for i in range(flashes):
		# Apagar (alpha = 0)
		tween.tween_property(self, "modulate:a", 0.0, half_flash_time)
		# Prender (alpha = 1)
		tween.tween_property(self, "modulate:a", 1.0, half_flash_time)
	
	tween.tween_callback(Callable(self, "hide"))

func _on_death_finished():
	hide()
	emit_signal("hit")

func _on_frame_changed() -> void:
	_update_hitbox()

func _update_hitbox():
	var sprite = $AnimatedSprite2D
	if sprite.animation == "" or sprite.sprite_frames.get_frame_count(sprite.animation) == 0:
		return
	var frame_texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if frame_texture == null:
		return
	var size = frame_texture.get_size()
	if $CollisionShape2D.shape == null:
		$CollisionShape2D.shape = RectangleShape2D.new()
	if $CollisionShape2D.shape is RectangleShape2D:
		($CollisionShape2D.shape as RectangleShape2D).extents = size / 2
	elif $CollisionShape2D.shape is CircleShape2D:
		($CollisionShape2D.shape as CircleShape2D).radius = max(size.x, size.y) / 2

func start(pos):
	position = pos
	
	# 🔹 Corrección: asegurar visibilidad completa
	show()                        
	$AnimatedSprite2D.show()      
	$AnimatedSprite2D.modulate = Color(1,1,1,1)  # reset alpha
	modulate = Color(1,1,1,1)     # reset también en el nodo raíz

	$CollisionShape2D.disabled = false
	is_dead = false
	can_move = false
	
	# Reiniciar animación a quieta correspondiente
	if last_direction == "sides":
		$AnimatedSprite2D.animation = "quiet_sides"
		$AnimatedSprite2D.flip_h = facing_right
	else:
		$AnimatedSprite2D.animation = "quiet_" + last_direction
		$AnimatedSprite2D.flip_h = false
	$AnimatedSprite2D.play()
