extends Node

@export var mob_scene: PackedScene
var score

# Dificultad progresiva
var difficulty_timer := 0.0
var mobs_per_spawn := 1             # cantidad inicial de mobs por spawn
@export var difficulty_increase_interval := 10.0  # segundos para aumentar dificultad
@export var max_mobs_per_spawn := 5

func _ready():
	$HUD.message_finished.connect(Callable(self, "_on_HUD_message_finished"))

func game_over() -> void:
	$Music.stop()
	$DeathSound.play()
	$ScoreTimer.stop()
	$MobTimer.stop()
	$HUD.show_game_over()
	$Player.can_move = false
	mobs_per_spawn = 1        # resetear dificultad
	difficulty_timer = 0.0

func new_game():
	score = 0
	$Music.play()
	$Player.start($StartPosition.position)
	$Player.can_move = false
	$HUD.show_message("Estas listo?")
	await get_tree().create_timer(1.0).timeout
	$HUD.show_message("3..")
	await get_tree().create_timer(0.75).timeout
	$HUD.show_message("2..")
	await get_tree().create_timer(0.75).timeout
	$HUD.show_message("1..")
	await get_tree().create_timer(0.75).timeout
	$HUD.show_message("Ya!!")
	$HUD.update_score(score)
	$StartTimer.start()
	get_tree().call_group("mobs", "queue_free")
	mobs_per_spawn = 1
	difficulty_timer = 0.0

func _process(delta: float) -> void:
	# Incrementa timer de dificultad
	if $MobTimer.is_stopped():
		return
	difficulty_timer += delta
	if difficulty_timer >= difficulty_increase_interval:
		difficulty_timer = 0
		if mobs_per_spawn < max_mobs_per_spawn:
			mobs_per_spawn += 1

func _on_mob_timer_timeout() -> void:
	for i in range(mobs_per_spawn):
		if mob_scene == null:
			return
		var mob = mob_scene.instantiate()
		var mob_spawn_location = $MobPath/MobSpawnLocation
		mob_spawn_location.progress_ratio = randf()
		mob.position = mob_spawn_location.position

		var direction = mob_spawn_location.rotation + PI / 2
		direction += randf_range(-PI / 4, PI / 4)

		var velocity = Vector2(randf_range(150.0, 250.0), 0.0)
		mob.linear_velocity = velocity.rotated(direction)

		add_child(mob)

func _on_score_timer_timeout() -> void:
	score += 1
	$HUD.update_score(score)

func _on_start_timer_timeout() -> void:
	$MobTimer.start()
	$ScoreTimer.start()

func _on_HUD_message_finished():
	$Player.can_move = true
