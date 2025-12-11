extends StaticBody2D

var radius = 50
var aperture = 0.3
var color = Color.html("#f9f2cb")
var thickness = 5.0
var gap_detector: Area2D = null
var bounce = 2  # Bounce value (0.0 to 1.0)

func _ready():
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_to_group("circle")
	
	# Create physics material with bounce
	var physics_material = PhysicsMaterial.new()
	physics_material.bounce = bounce
	physics_material.friction = 0
	physics_material_override = physics_material
	
	create_ring_collision()
	create_gap_detector()
	queue_redraw()

func _draw() -> void:
	var center = Vector2.ZERO
	var start_angle = 0
	var end_angle = TAU * (1 - aperture)
	
	draw_arc(center, radius, start_angle, end_angle, 128, color, thickness)

func set_properties(new_radius: float, new_aperture: float):
	radius = new_radius
	aperture = new_aperture
	create_gap_detector()
	queue_redraw()

func create_gap_detector():
	# Remove old detector
	if gap_detector:
		gap_detector.queue_free()
	
	# Create Area2D covering the gap with multiple small rectangles
	gap_detector = Area2D.new()
	
	# Set collision layers using named layers
	# Gap detector should be on "detector" layer and detect "ball" layer (layer 2)
	gap_detector.set_collision_mask_value(2, true)  # Detect ball layer (bit 1/layer 2)
	
	var gap_start_angle = TAU * (1.0 - aperture)
	var num_segments = 8  # More segments = better coverage
	var segment_angle = (TAU - gap_start_angle) / num_segments
	
	for i in range(num_segments):
		var angle = gap_start_angle + (i * segment_angle) + (segment_angle / 2)
		var position = Vector2(cos(angle), sin(angle)) * radius
		
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(radius * 0.1, radius * 0.05)
		collision.shape = shape
		collision.position = position
		collision.rotation = angle + PI/2
		
		gap_detector.add_child(collision)
	
	gap_detector.body_entered.connect(_on_gap_entered)
	add_child(gap_detector)
	gap_detector.add_to_group("detector")

func _on_gap_entered(body):
	print("Ya nada mi gente")
	if body.is_in_group("ball"):  # Or check by group
		print("Ball passed through gap!")
		var circle_parent = get_parent()
		
		# Tell the ball it escaped
		if body.has_signal("escaped_through_gap"):
			body.grow_and_escape(circle_parent)

func create_ring_collision():
	# Remove old collision if exists
	for child in get_children():
		if child is CollisionShape2D:
			child.queue_free()
	
	# Create ring using segments
	var num_segments = 32
	var segment_angle = TAU * (1.0 - aperture) / num_segments
	
	for i in range(num_segments):
		var angle = i * segment_angle
		var next_angle = (i + 1) * segment_angle
		
		var p1 = Vector2(cos(angle), sin(angle)) * radius
		var p2 = Vector2(cos(next_angle), sin(next_angle)) * radius
		
		var collision = CollisionShape2D.new()
		var shape = SegmentShape2D.new()
		

		shape.a = p1
		shape.b = p2
		collision.shape = shape
		add_child(collision)

func create_detection_area():
	# Remove old area
	for child in get_children():
		if child is Area2D and child != gap_detector:
			child.queue_free()
	
	# Create Area2D to detect when ball leaves circle bounds
	var area = Area2D.new()
	var area_collision = CollisionShape2D.new()
	var area_shape = CircleShape2D.new()
	area_shape.radius = radius
	area_collision.shape = area_shape
	area.add_child(area_collision)
	add_child(area)
