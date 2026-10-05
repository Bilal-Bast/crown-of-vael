extends SceneTree

const ROOT := "res://assets/heroes/knight"
const FORMS := ["squire", "knight", "royal_knight", "paladin", "divine_paladin"]
const ROWS := ["idle", "run", "attack", "guard", "hit"]

func _initialize() -> void:
	var failures := 0
	for form in FORMS:
		var atlas_path := "%s/source_atlases/%s_atlas.png" % [ROOT, form]
		var image := Image.new()
		var error := image.load(atlas_path)
		if error != OK or image.get_width() != 1024 or image.get_height() != 1536:
			push_error("Invalid atlas: %s (%s, %dx%d)" % [atlas_path, error, image.get_width(), image.get_height()])
			failures += 1
			continue
		var folder := "%s/%s" % [ROOT, form]
		var absolute_folder := ProjectSettings.globalize_path(folder)
		DirAccess.make_dir_recursive_absolute(absolute_folder)
		for row in ROWS.size():
			var strip := Image.create(1024, 256, false, Image.FORMAT_RGBA8)
			for frame in 4:
				var cell := Image.create(256, 256, false, Image.FORMAT_RGBA8)
				cell.blit_rect(image, Rect2i(frame * 256, row * 256, 256, 256), Vector2i.ZERO)
				var lowest_opaque := -1
				for y in range(255, -1, -1):
					for x in 256:
						if cell.get_pixel(x, y).a > 0.12:
							lowest_opaque = y
							break
					if lowest_opaque >= 0:
						break
				var baseline_aligned := Image.create(256, 256, false, Image.FORMAT_RGBA8)
				var y_offset := 240 - lowest_opaque if lowest_opaque >= 0 else 0
				baseline_aligned.blit_rect(cell, Rect2i(0, 0, 256, 256), Vector2i(0, y_offset))
				strip.blit_rect(baseline_aligned, Rect2i(0, 0, 256, 256), Vector2i(frame * 256, 0))
			var filename: String = ROWS[row]
			if form == "squire":
				filename = "squire_%s" % filename
			var output := "%s/%s.png" % [folder, filename]
			if strip.save_png(ProjectSettings.globalize_path(output)) != OK:
				push_error("Failed to save %s" % output)
				failures += 1
		var portrait := Image.create(256, 256, false, Image.FORMAT_RGBA8)
		portrait.blit_rect(image, Rect2i(0, 1280, 256, 256), Vector2i.ZERO)
		var portrait_name := "squire_portrait.png" if form == "squire" else "portrait.png"
		var portrait_path := "%s/%s" % [folder, portrait_name]
		if portrait.save_png(ProjectSettings.globalize_path(portrait_path)) != OK:
			push_error("Failed to save %s" % portrait_path)
			failures += 1
	print("HERO ATLAS CROPPING: ", "FAIL (%d)" % failures if failures else "PASS")
	quit(1 if failures else 0)
