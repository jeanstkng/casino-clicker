extends RigidBody2D

var radius = 10
var color = Color.html("#f6ee1b")
var collision_shape: CollisionShape2D = null

# Constant speed and force variables
var target_speed = 800  # Target speed to maintain
var energy_retention = 1  # How much energy to retain (0.95 = 95%)
var speed_check_interval = 0.2  # How often to check and correct speed (in seconds)
var time_since_last_check = 0
var initial_speed_set = false

signal escaped_through_gap(circle)
signal touched_a_wall()

func _ready():
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	name = "Ball"  # Set name so gap detector can identify it
	add_to_group("ball")  # Add to ball group for detection
	
	# Set collision layers using named layer (ball layer is bit 1, value 2)
	set_collision_layer_value(2, true)  # Ball is on the "ball" layer (layer 2)
	# Masks are configured in the editor
	
	# Add collision shape for physics
	collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	collision_shape.shape = shape
	add_child(collision_shape)
	
	# Physics properties
	# gravity_scale = 1
	mass = 1
	linear_damp = 0
	angular_damp = 0

	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = 3
	physics_material_override.friction = 0
	
	# Enable contact monitoring to detect collisions
	contact_monitor = true
	max_contacts_reported = 4
	
	# Connect collision signals
	body_entered.connect(_on_body_entered)
	body_shape_entered.connect(_on_body_shape_entered)
	
	queue_redraw()

func _physics_process(delta):
	# Track time for speed correction
	time_since_last_check += delta
	
	# Periodically check and correct speed to maintain constant velocity
	if time_since_last_check >= speed_check_interval:
		_correct_velocity()
		time_since_last_check = 0

func _correct_velocity():
	# Get current velocity
	var current_velocity = linear_velocity
	var current_speed = current_velocity.length()
	
	# Store initial speed if not set yet
	if not initial_speed_set and current_speed > 0:
		target_speed = 600
		initial_speed_set = true
		print("Initial speed set to: ", target_speed)
	
	# Only correct if we have significant movement (not when ball is nearly stopped)
	if current_speed > 50:
		# Calculate speed loss and restore some energy
		var speed_ratio = current_speed / target_speed
		
		# If speed dropped below our retention threshold, boost it back
		if speed_ratio < energy_retention:
			# Calculate the velocity direction (normalized)
			var velocity_direction = current_velocity.normalized()
			
			# Restore energy but don't exceed target speed
			var new_speed = min(target_speed, current_speed * 1.1)
			linear_velocity = velocity_direction * new_speed
			print("Energy restored - Speed: ", new_speed)

func grow_and_escape(circle_parent):
	print("Ball growing!")
	
	# Increase radius
	radius += 5 + (radius * 0.75)
	
	# Update collision shape
	if collision_shape and collision_shape.shape:
		collision_shape.shape.radius = radius
	
	# Redraw
	queue_redraw()
	
	escaped_through_gap.emit(circle_parent)




func _draw():
	draw_circle(Vector2.ZERO, radius, color)


func _on_body_entered(body):
	if body.is_in_group("circle"):
		print("Ball collided with circle body!")
		# Immediately correct velocity after collision to maintain energy
		_correct_velocity()



func _on_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	if body.is_in_group("circle"):
		# Get the collision point in the circle's local space
		var circle_body = body
		var collision_point = global_position - circle_body.global_position
		
		# Calculate the angle of collision on the circle
		var angle = atan2(collision_point.y, collision_point.x)
		var angle_degrees = rad_to_deg(angle)
		if angle_degrees < 0:
			angle_degrees += 360
		
		# Calculate which segment of the circle was hit
		var circle_radius = circle_body.radius if "radius" in circle_body else 50
		var distance_from_center = collision_point.length()
		
		touched_a_wall.emit()

		print("Ball touched circle at:")
		print("  - Angle: %.1f degrees" % angle_degrees)
		print("  - Distance from center: %.1f" % distance_from_center)
		print("  - Circle radius: %.1f" % circle_radius)
		print("  - Collision point (local): ", collision_point)
		
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball"):
		pass
