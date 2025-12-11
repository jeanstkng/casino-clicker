extends TextureRect

func _init() -> void:
	var meme_tween = create_tween()
	meme_tween.set_ease(Tween.EASE_OUT)
	meme_tween.set_trans(Tween.TRANS_QUAD)
	meme_tween.set_loops()
	
	meme_tween.tween_property(self, "scale", Vector2(1.6, 1.6), 1.0)
	meme_tween.tween_property(self, "scale", Vector2(1, 1), 1.0)

	#meme_tween.interpolate_property(memingo, "rect_scale", Vector2(1, 1), Vector2(1.5, 1.5), 1)
	
