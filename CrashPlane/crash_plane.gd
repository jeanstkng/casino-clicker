extends Node2D

# Signals that must be emitted
signal on_score_change(cashin_by_match)
signal take_score(percent)
signal game_finished(next_step)

# Method to receive the actual bet amount from parent
func set_bet_amount(amount):
	current_bet = amount
	print("Bet amount set to: ", current_bet)

# Node references
@onready var multiplier_label = $Multiplier
@onready var bet_label = $Bet
@onready var airplane = $Airplane

# Trail system
var trail_points = []
var trail_dots = []
var trail_spacing = 20.0  # Distance between dots
var last_trail_position = Vector2.ZERO

# Game state variables
var current_round = 0
var total_rounds = 6
var current_multiplier = 0
var crash_point = 0.0
var is_round_active = false
var bet_percentage = 0.05  # 5% of current score
var current_bet = 0.0  # Store actual bet amount

# Game configuration
var multiplier_start = 0
var multiplier_end = 5.0
var multiplier_speed = 1.5  # How fast the multiplier increases
var airplane_start_position = Vector2(424, 622)
var airplane_movement_scale = 200.0  # How much the airplane moves per multiplier unit

func _ready():
	# Initialize the game when the scene loads
	start_game()

func _process(delta):
	if is_round_active:
		update_round(delta)

func start_game():
	print("Starting Crash Plane game with ", total_rounds, " rounds")
	current_round = 0
	start_round()

func start_round():
	current_round += 1
	current_bet = randf_range(0.1, multiplier_end)
	
	bet_label.text = "Bet: %.2fx" % current_bet
	if current_round > total_rounds:
		print("All rounds completed!")
		return
	
	# Reset round state
	current_multiplier = multiplier_start
	is_round_active = true
	
	# Generate random crash point between 1.0 and ~8.0
	crash_point = randf_range(0, multiplier_end)
	
	# Reset airplane position
	airplane.position = airplane_start_position
	
	# Emit signal to take 5% of player's score
	print("Round ", current_round, ": Taking ", bet_percentage * 100, "% of score")
	take_score.emit(bet_percentage)
	
	# Wait for parent to process the signal and update current_bet
	await get_tree().process_frame
	
	# Small delay before starting the round
	await get_tree().create_timer(1.0).timeout
	
	# Debug: Check if bet was set
	print("DEBUG: Starting round with bet amount: ", current_bet)
	

func update_round(delta):
	# Increase multiplier
	current_multiplier += multiplier_speed * delta
	
	# Update multiplier label
	multiplier_label.text = "Multiplier: %.2fx" % current_multiplier
	
	# Move airplane diagonally up based on multiplier
	var movement_offset = Vector2(
		(current_multiplier - multiplier_start) * airplane_movement_scale,
		-(current_multiplier - multiplier_start) * airplane_movement_scale * 0.25  # Slightly less vertical movement
	)
	airplane.position = airplane_start_position + movement_offset
	
	# Add trail dots
	update_trail()
	
	# Check if crash point is reached
	if current_multiplier >= crash_point:
		trigger_crash()

func trigger_crash():
	is_round_active = false
	
	print("Round ", current_round, ": Crashed at ", str("%0.2f" % current_multiplier), "x (crash point: ", str("%0.2f" % crash_point), "x)")
	
	# Check if multiplier passed 1.00x for cash-in
	if current_multiplier >= current_bet:
		print("Round ", current_round, " (bet: ", current_bet, " × ", str("%0.2f" % current_multiplier), "x)")
		on_score_change.emit(current_bet)
	else:
		print("Round ", current_round, ": No cash-in (multiplier did not pass 1.00x)")
	
	# Reset for next round after a short delay
	await get_tree().create_timer(2.0).timeout
	reset_round()

func reset_round():
	clear_trail()
	if current_round < total_rounds:
		start_round()
	else:
		game_finished.emit(1)
		print("Crash Plane game completed!")
		queue_free()

func update_trail():
	# Check if airplane has moved enough distance to place a new dot
	if last_trail_position.distance_to(airplane.position) >= trail_spacing:
		place_trail_dot(airplane.position)
		last_trail_position = airplane.position

func place_trail_dot(position):
	# Create a simple dot using a ColorRect node since we can't create new scenes
	var dot = ColorRect.new()
	dot.size = Vector2(4, 4)
	dot.position = position - Vector2(2, 2)  # Center the dot
	dot.color = Color.WHITE
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block mouse events
	
	# Add to scene
	add_child(dot)
	trail_dots.append(dot)

func clear_trail():
	# Remove all trail dots
	for dot in trail_dots:
		dot.queue_free()
	trail_dots.clear()
	trail_points.clear()
	last_trail_position = Vector2.ZERO

func _exit_tree():
	# Clean up when scene is removed
	pass
