extends Control

var spin_speed = 1200.0  # Pixels per second
var keep_spinning = false
var is_adjusting = false
var symbol_height = 130.0  # Height of each symbol
var symbols = []
var target_symbol_index = 0  # Which symbol to stop on (0 = first symbol)
var mask_height = 400.0  # Height of the mask
var mask_center_y = 200.0  # Center of the mask (400/2)
var initial_positions = []  # Store initial positions of symbols
var target_symbol = null
var symbol_order = []  # Tracks the current logical order of symbols (top to bottom)

func _ready():
	symbols = get_children()
	# Store initial positions and initialize symbol order
	for i in range(symbols.size()):
		initial_positions.append(symbols[i].position.y)
		symbol_order.append(symbols[i].name)  # Store symbol names
	print("Reel initialized with ", symbols.size(), " symbols")
	print("Container starts at position: ", position)
	print("Initial symbol order: ", symbol_order)

func _process(delta):
	if keep_spinning:
		# Move the container down
		#position.y += spin_speed * delta
		
		# Check each symbol to see if it needs to be recycled
		for i in range(symbols.size()):
			var symbol = symbols[i]
			# When a symbol goes below the visible area, move it to the top
			symbol.position.y += spin_speed * delta
			if symbol.position.y > mask_height + symbol_height:
				# Find the highest symbol position
				var min_y = symbols[0].position.y
				for other_symbol in symbols:
					if other_symbol.position.y < min_y:
						min_y = other_symbol.position.y
				
				# Position this symbol above the highest one
				symbol.position.y = min_y - symbol_height
				
				# Update symbol order: remove this symbol and insert it at the beginning
				var order_index = symbol_order.find(symbol.name)
				if order_index >= 0:
					symbol_order.remove_at(order_index)
					symbol_order.insert(0, symbol.name)
					# print("Recycled symbol ", symbol.name, " to position ", symbol.position.y, " - New order: ", symbol_order)
	elif not keep_spinning and not is_adjusting:
		if abs(target_symbol.position.y - 184) < 25:
			print("pasando el threshold", target_symbol.position.y, target_symbol.name)
			is_adjusting = true
			adjust_symbols()
			return
		for i in range(symbols.size()):
			var symbol = symbols[i]
			# When a symbol goes below the visible area, move it to the top
			symbol.position.y += spin_speed * delta
			if symbol.position.y > mask_height + symbol_height:
				# Find the highest symbol position
				var min_y = symbols[0].position.y
				for other_symbol in symbols:
					if other_symbol.position.y < min_y:
						min_y = other_symbol.position.y
				
				# Position this symbol above the highest one
				symbol.position.y = min_y - symbol_height
				
				# Update symbol order: remove this symbol and insert it at the beginning
				var order_index = symbol_order.find(symbol.name)
				if order_index >= 0:
					symbol_order.remove_at(order_index)
					symbol_order.insert(0, symbol.name)
					# print("Recycled symbol ", symbol.name, " to position ", symbol.position.y, " - New order: ", symbol_order)
		

func start_spin(symbol_index: int):
	if symbol_index < 0 or symbol_index >= symbols.size():
		print("Invalid symbol index: ", symbol_index)
		return
	target_symbol_index = symbol_index
	
	target_symbol = symbols[symbol_index]
	keep_spinning = true
	is_adjusting = false  # Reset adjusting flag
	print("Starting spin with symbol_order: ", symbol_order)
	print("Symbol positions before spin:")
	for s in symbols:
		print("  ", s.name, ": y=", s.position.y)

func stop_spin_on_symbol():
	#if symbol_index < 0 or symbol_index >= symbols.size():
		#print("Invalid symbol index: ", symbol_index)
		#return
		
	keep_spinning = false
	#target_symbol_index = symbol_index
	#
	#target_symbol = symbols[symbol_index]
	
	# Calculate the position needed to center the target symbol in the mask
	# The mask center is at y=200 relative to the mask
	# We need to adjust the container position so the target symbol's center aligns with the mask center
	var target_symbol_center = target_symbol.position.y + (symbol_height / 2)
	var target_container_y = mask_center_y - target_symbol_center
	
	#print("Stopping on symbol ", symbol_index, " at container position ", target_container_y)
	print("Target symbol position: ", target_symbol.position.y)
	
func adjust_symbols():
	print("Adjusting symbols with order: ", symbol_order)
	print("Symbol positions before adjustment:")
	for s in symbols:
		print("  ", s.name, ": y=", s.position.y)
	
	# Use the symbol_order array to assign symbols to their correct initial positions
	# symbol_order[i] tells us which symbol (by name) is in logical position i
	for i in range(symbol_order.size()):
		var symbol_name = symbol_order[i]
		# Find the symbol by name
		var symbol = null
		for s in symbols:
			if s.name == symbol_name:
				symbol = s
				break
		
		if symbol == null:
			print("Error: Symbol ", symbol_name, " not found!")
			continue
		
		var symbol_tween = create_tween()
		symbol_tween.set_ease(Tween.EASE_OUT)
		symbol_tween.set_trans(Tween.TRANS_QUAD)
		
		# Assign this symbol to the i-th initial position
		var final_position = initial_positions[i]
		
		#print("Symbol ", symbol_name, " moving to position ", i, " (y=", final_position, ")")
		
		# Animate the symbol to its final position with a small bounce effect
		symbol_tween.tween_property(symbol, "position:y", final_position, 0.8)
		symbol_tween.tween_property(symbol, "position:y", final_position - 5, 0.1)
		symbol_tween.tween_property(symbol, "position:y", final_position, 0.1)
	
	# After adjustment, reset symbol_order to match the new physical positions
	# We need to wait for the tween to finish before resetting
	await get_tree().create_timer(1.0).timeout
	
	# Now reset symbol_order based on actual symbol positions
	var position_to_name = {}
	for i in range(symbols.size()):
		position_to_name[initial_positions[i]] = symbols[i].name
	
	# Clear and rebuild symbol_order in the correct initial order
	symbol_order.clear()
	for pos in initial_positions:
		symbol_order.append(position_to_name[pos])
	
	#print("Symbol order reset to: ", symbol_order)
	#print("Symbol positions after adjustment:")
	for s in symbols:
		print("  ", s.name, ": y=", s.position.y)

func get_centered_symbol_index() -> int:
	return target_symbol_index
