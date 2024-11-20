extends CharacterBody2D

@onready var squirrel: CharacterBody2D = self
@onready var sprite_collision: CollisionShape2D = $SpriteCollision
@onready var area_collision: CollisionShape2D = $Area2D/AreaCollision
@onready var power_up_speed_timer: Timer = $PowerUpSpeedTimer
@onready var power_up_invisible_timer: Timer = $PowerUpInvisibleTimer
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var enter_timer: Timer = $EnterTimer
@onready var area_2d: Area2D = $Area2D

signal enemy_hit
signal level_done

var state: Globals.SquirrelState = Globals.SquirrelState.NORMAL
var exit_enter_in_progress = true

const COLLISION_LAYER_ENEMY = 3
const COLLISION_LAYER_PLAYER = 2

func _ready() -> void:
	await get_tree().create_timer(2.2).timeout
	exit_enter_in_progress = false
	
func _input(event):
	if exit_enter_in_progress:
		return
		
	if state != Globals.SquirrelState.NORMAL:
		return
	
	var can_power_up_speed_pick_up: bool = event.is_action_pressed("power_up_speed") && Globals.power_up_speed_available
	
	if can_power_up_speed_pick_up:
		activate_power_up_speed()
		
	var can_power_up_invis_pick_up: bool = event.is_action_pressed("power_up_invisible") && Globals.power_up_invis_available
	
	if can_power_up_invis_pick_up:
		activate_power_up_invisible()
		
func activate_power_up_speed():
	state = Globals.SquirrelState.SPEEDY
	power_up_speed_timer.start()
	Globals.power_up_speed_available = false
	add_power_up_progressbar()
	Globals.speed = Globals.speed * 2
	
func activate_power_up_invisible():
	state = Globals.SquirrelState.INVISIBLE
	power_up_invisible_timer.start()
	Globals.power_up_invis_available = false
	add_power_up_progressbar()
	area_2d.set_collision_mask_value(COLLISION_LAYER_ENEMY, false)
	area_2d.set_collision_layer_value(COLLISION_LAYER_PLAYER, false)
	squirrel.set_collision_mask_value(COLLISION_LAYER_ENEMY, false)
	squirrel.set_collision_layer_value(COLLISION_LAYER_PLAYER, false)
	
func add_power_up_progressbar():
	progress_bar.visible = true
	progress_bar.value = 100
	var tween = get_tree().create_tween()
	tween.tween_property(progress_bar,"value",0,2.0)	
		
func _physics_process(_delta: float) -> void:
	if exit_enter_in_progress:
		return
	
	handle_hiding()
	handle_evacuation()
	handle_movement()
		
func handle_hiding() -> void:
	sprite_collision.disabled = Globals.hiding
	area_collision.disabled = Globals.hiding
	squirrel.visible = not Globals.hiding
	
	if Input.is_action_just_pressed("hide") and Globals.able_to_hide:
		print("hiding")
		Globals.hiding = true
	if Input.is_action_just_released("hide"):
		print("stopped hiding")
		Globals.hiding = false
		
func handle_evacuation() -> void:
	if Input.is_action_just_pressed("evacuate") and Globals.ready_to_evacuate and Globals.in_start_area:
		exit_enter_in_progress = true
		animated_sprite_2d.play("evacuate")
		sprite_collision.disabled = true
		area_collision.disabled = true
		await get_tree().create_timer(2.2).timeout
		level_done.emit()
		
func handle_movement() -> void:
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction:
		play_movement_anim(direction, state)

		velocity = velocity.move_toward(direction * Globals.speed, Globals.acceleration)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, Globals.friction)
		if (!exit_enter_in_progress):
			match state:
				Globals.SquirrelState.NORMAL:
					animated_sprite_2d.play("idle")
				Globals.SquirrelState.SPEEDY:
					animated_sprite_2d.play("idle_speedy")
				Globals.SquirrelState.INVISIBLE:
					animated_sprite_2d.play("idle_invis")
	if (!Globals.hiding):
		move_and_slide()

func play_movement_anim(direction: Vector2, state: Globals.SquirrelState):
	match state:
		Globals.SquirrelState.NORMAL:
			match direction:
				Vector2.UP:
					animated_sprite_2d.play("run_up")
				Vector2.DOWN:
					animated_sprite_2d.play("run_down")
				Vector2.RIGHT:
					animated_sprite_2d.flip_h = false
					animated_sprite_2d.play("run")
				Vector2.LEFT:
					animated_sprite_2d.flip_h = true
					animated_sprite_2d.play("run")
		Globals.SquirrelState.SPEEDY:
			match direction:
				Vector2.UP:
					animated_sprite_2d.play("run_up_speedy")
				Vector2.DOWN:
					animated_sprite_2d.play("run_down_speedy")
				Vector2.RIGHT:
					animated_sprite_2d.flip_h = false
					animated_sprite_2d.play("run_speedy")
				Vector2.LEFT:
					animated_sprite_2d.flip_h = true
					animated_sprite_2d.play("run_speedy")	
		Globals.SquirrelState.INVISIBLE:
			match direction:
				Vector2.UP:
					animated_sprite_2d.play("run_up_invis")
				Vector2.DOWN:
					animated_sprite_2d.play("run_down_invis")
				Vector2.RIGHT:
					animated_sprite_2d.flip_h = false
					animated_sprite_2d.play("run_invis")
				Vector2.LEFT:
					animated_sprite_2d.flip_h = true
					animated_sprite_2d.play("run_invis")	

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		Globals.lose_nut()
		enemy_hit.emit()
	if area.is_in_group("nut"):
		Globals.collect_nut()

func _on_power_up_speed_timer_timeout() -> void:
	progress_bar.visible = false
	state = Globals.SquirrelState.NORMAL
	Globals.power_up_speed_available = true
	Globals.speed = Globals.speed / 2


func _on_power_up_invisible_timer_timeout() -> void:
	progress_bar.visible = false
	state = Globals.SquirrelState.NORMAL
	Globals.power_up_invis_available = true
	area_2d.set_collision_mask_value(3,true)
	area_2d.set_collision_layer_value(2,true)
	squirrel.set_collision_mask_value(3,true)
	squirrel.set_collision_layer_value(2,true)
	
