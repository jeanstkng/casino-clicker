extends Node2D

var radius = 50
var aperture = 0.3
var rotation_speed = 1.0
var particle_effect: GPUParticles2D = null
var static_body: StaticBody2D = null

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	# Find children
	for child in get_children():
		if child is GPUParticles2D:
			particle_effect = child
			particle_effect.emitting = false
			particle_effect.one_shot = true
			
			# Duplicate material to make it unique
			if particle_effect.process_material:
				particle_effect.process_material = particle_effect.process_material.duplicate()
		elif child is StaticBody2D:
			static_body = child

func _process(delta: float) -> void:
	rotation += rotation_speed * delta

func set_circle_properties(new_radius: float, new_aperture: float, speed: float = 1):
	radius = new_radius
	aperture = new_aperture
	rotation_speed = speed
	
	# Update static body
	if static_body:
		static_body.set_properties(new_radius, new_aperture)
		static_body.create_ring_collision()
		static_body.create_detection_area()
	
	# Update particle size
	update_particle_size()

func update_particle_size():
	if not particle_effect or not particle_effect.process_material:
		return
	
	var material = particle_effect.process_material
	material.set("emission_ring_radius", radius)
	material.set("emission_ring_inner_radius", radius - 5)

func destroy_with_effect():
	# Destroy the static body (removes collision and visual)
	if static_body:
		static_body.queue_free()
	
	# Stop rotating
	set_process(false)
	
	# Play particle effect
	if particle_effect:
		particle_effect.emitting = true
		particle_effect.restart()
		
		# Wait for particle to finish, then destroy the whole node
		await get_tree().create_timer(particle_effect.lifetime).timeout
	
	# Destroy the parent node
	queue_free()
