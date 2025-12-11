extends Node

var pinball_scene = preload("res://Pinball/pinball.tscn")
var slot_machine_scene = preload("res://SlotMachine/SlotMachine.tscn")
var crash_plane_scene = preload("res://CrashPlane/CrashPlane.tscn")

var cash_value = 0
var cash_by_click = 1
var cash_multiplier = 2
var run_count = 0
var actual_step = 1
var pinball = null
var slot_machine = null
var crash_plane = null

func _ready() -> void:
	show_game_by_step(1)


func show_game_by_step(step):
	actual_step = step
	if step == 1:
		run_count += 1
		pinball = pinball_scene.instantiate()
		if run_count > 1:
			pinball.add_circles(2)
			pinball.base_radius += 50
			pinball.radius_decrease -= 40
		add_child(pinball)
		pinball.on_score_change.connect(_handle_score_change)
		pinball.game_finished.connect(show_game_by_step)


	elif step == 2:
		slot_machine = slot_machine_scene.instantiate()
		if run_count >= 2:
			slot_machine.add_reels(2)
		add_child(slot_machine)
		slot_machine.on_score_change.connect(_handle_score_change)
		slot_machine.take_score.connect(_take_score)
		slot_machine.game_finished.connect(show_game_by_step)

	elif step == 3:
		crash_plane = crash_plane_scene.instantiate()
		add_child(crash_plane)
		crash_plane.on_score_change.connect(_handle_score_change)
		crash_plane.take_score.connect(_take_score)
		crash_plane.game_finished.connect(show_game_by_step)


func _process(delta):
	if Input.is_action_just_pressed("touch"):
		cash_value += cash_by_click
		var cash_label = get_node("CenterContainer/Cash")
		cash_label.text = str("%0.2f" % cash_value)
		

func _handle_score_change(cashin_by_bounce):
	cash_value *= cashin_by_bounce
	var cash_label = get_node("CenterContainer/Cash")
	cash_label.text = str("%0.2f" % cash_value)
	
	var tween = create_tween()
	var random_scale = randf_range(1.2, 1.4)
	
	tween.tween_property(cash_label, "scale", Vector2(random_scale, random_scale), 0.2)
	tween.tween_property(cash_label, "scale", Vector2(1.0, 1.0), 0.2)
	

func _take_score(percent):
	var take_cash = cash_value * percent
	cash_value -= take_cash
	print("Taken Cash: ", cash_value)
	var cash_label = get_node("CenterContainer/Cash")
	cash_label.text = str("%0.2f" % cash_value)
	
	# Create tween animation for the cash label
	var tween = create_tween()
	var random_scale = randf_range(1.2, 1.4)
	
	# Scale up and then back to original
	tween.tween_property(cash_label, "scale", Vector2(random_scale, random_scale), 0.2)
	tween.tween_property(cash_label, "scale", Vector2(1.0, 1.0), 0.2)
	


func _on_return_button_up() -> void:
	if actual_step == 1:
		pinball.queue_free()
	elif actual_step == 2:
		slot_machine.queue_free()
	elif actual_step == 3:
		crash_plane.queue_free()
	
	get_tree().change_scene_to_file("res://gui/main_menu.tscn")
