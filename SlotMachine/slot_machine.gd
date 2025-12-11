extends Node2D

@onready var reel1 = $Reel1Mask/Reel1Container
@onready var reel2 = $Reel2Mask/Reel2Container
@onready var reel3 = $Reel3Mask/Reel3Container
@onready var reel4 = $Reel4Mask/Reel4Container
@onready var reel5 = $Reel5Mask/Reel5Container
@onready var mask4 = $Reel4Mask
@onready var mask5 = $Reel5Mask

signal on_score_change(cashin_by_match)
signal take_score(percent)
signal game_finished(next_step)

var cash_multiplier = 1.3
var percentage_bet = 0.1
var max_wins = 2
var wins = 0
var reels = 3

# Rigged win system variables
var spins_since_last_win = 0
var max_spins_before_win = 10  # Default value, will be randomized

func _ready():
	if reels > 3:
		reel4.process_mode = Node.PROCESS_MODE_INHERIT
		reel5.process_mode = Node.PROCESS_MODE_INHERIT
		mask4.visible = true
		mask5.visible = true
	else:
		reel4.process_mode = Node.PROCESS_MODE_DISABLED
		reel5.process_mode = Node.PROCESS_MODE_DISABLED
		mask4.visible = false
		mask5.visible = false

	# Initialize the rigged win system
	_randomize_max_spins()
	
	# Loop spins until max_wins is reached
	while wins < max_wins:
		await spin_once()
		await get_tree().create_timer(1.0).timeout  # Brief pause between spins
	
	print("Reached max wins! Total wins: ", wins)
	game_finished.emit(3)
	queue_free()

func _randomize_max_spins():
	# Set a random number of spins before guaranteeing a win (between 5-15)
	max_spins_before_win = randi_range(3, 6)
	print("New rigged win target: ", max_spins_before_win, " spins")

func spin_once():
	take_score.emit(percentage_bet)
	spins_since_last_win += 1
	
	# Determine if we should force a win
	var should_force_win = spins_since_last_win >= max_spins_before_win
	
	# Start all reels spinning
	var random_1 = randi_range(0, 8)
	var random_2 = randi_range(0, 8)
	var random_3 = randi_range(0, 8)
	var random_4 = randi_range(0, 8)
	var random_5 = randi_range(0, 8)
	
	# If we should force a win, make all numbers the same
	if should_force_win:
		var win_symbol = randi_range(0, 8)
		random_1 = win_symbol
		random_2 = win_symbol
		random_3 = win_symbol
		if reels > 3:
			random_4 = win_symbol
			random_5 = win_symbol
		print("FORCED WIN! Numbers ", random_1, random_2, random_3, random_4, random_5, " after ", spins_since_last_win, " spins")
	else:
		print("Numbers ", random_1, random_2, random_3, random_4, random_5, " Spins since last win: ", spins_since_last_win, "/", max_spins_before_win)
	
	reel1.start_spin(random_1)
	reel2.start_spin(random_2)
	reel3.start_spin(random_3)
	if reels > 3:
		reel4.start_spin(random_4)
		reel5.start_spin(random_5)
	
	# Stop them with delays
	var random_time_1 = randf_range(2, 2.5)
	await get_tree().create_timer(random_time_1).timeout
	reel1.stop_spin_on_symbol()  # Stop on symbol index 2
	
	var random_time_2 = randf_range(2, 2.5)
	await get_tree().create_timer(random_time_2).timeout  # Delay before next reel
	reel2.stop_spin_on_symbol()  # Same symbol
	
	var random_time_3 = randf_range(2, 2.5)
	await get_tree().create_timer(random_time_3).timeout
	reel3.stop_spin_on_symbol()  # Same symbol = WIN!
	
	if reels > 3:
		var random_time_4 = randf_range(2, 2.5)
		await get_tree().create_timer(random_time_4).timeout
		reel4.stop_spin_on_symbol()
		var random_time_5 = randf_range(2, 2.5)
		await get_tree().create_timer(random_time_5).timeout
		reel5.stop_spin_on_symbol()

	# Check if all 3 match
	await get_tree().create_timer(2.75).timeout
	print("Checking for win...")

	if reels <= 3:
		if random_1 == random_2 and random_1 == random_3:
			_win_round()
		else:
			print("No win. Current wins: ", wins)
	else:
		if random_1 == random_2 and random_1 == random_3 and random_1 == random_4 and random_1 == random_5:
			_win_round()
		else:
			print("No win. Current wins: ", wins)

func _win_round():
	wins += 1
	on_score_change.emit(cash_multiplier)
	print("WIN! Total wins: ", wins)
	# Reset the rigged win system after any win (natural or forced)
	spins_since_last_win = 0
	_randomize_max_spins()

func add_reels(quantity):
	reels += quantity
