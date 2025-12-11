extends Node

var circle_scene = preload("res://Pinball/circle.tscn")
var ball_scene = preload("res://Pinball/ball.tscn")

var cash_multiplier = 1.2

var ball = null

var num_circles = 5
var base_radius = 500
var radius_decrease = 80.0

signal on_score_change(cashin_by_bounce)
signal game_finished(next_step)

func _ready() -> void:
	spawn_circles()
	spawn_ball()

	
func spawn_circles():
	for i in range(num_circles):
		var circle = circle_scene.instantiate()
		circle.position = Vector2(960, 540)
		# ADD TO SCENE FIRST so _ready() runs
		add_child(circle)
		
		# THEN set properties (now particle_effect is initialized)
		var current_radius = base_radius - ((i + 0.25) * radius_decrease)
		var random_aperture = randf_range(0.025, 0.075)
		var random_top = randf_range(3, 4)
		var random_bottom = randf_range(-4.0, -3)
		var sides = [random_bottom, random_top]
		var random_speed = sides.pick_random()
		
		circle.set_circle_properties(current_radius, random_aperture, random_speed)
		circle.rotation = randf_range(0, TAU)

func spawn_ball():
	ball = ball_scene.instantiate()
	ball.position = Vector2(960, 540)  # Start position above circles
	ball.escaped_through_gap.connect(_on_ball_escaped)
	ball.touched_a_wall.connect(_on_wall_touched)
	add_child(ball)

func _on_ball_escaped(circle_node):
	print("Ball escaped through circle!")
	on_score_change.emit(cash_multiplier)
	circle_node.destroy_with_effect()  # circle_node should be the Node2D

func _on_wall_touched():

	print("Funciona")


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball"):
		game_finished.emit(2)
		queue_free()

func add_circles(quantity):
	num_circles += quantity

func get_num_circles():
	return num_circles
