extends SceneTree

const HEROES := ["mage", "ranger", "assassin", "necromancer"]
const STATES := ["idle", "run", "attack", "guard", "hit"]
const OUTPUT_FRAME := 256

func _initialize() -> void:
	var failures := 0
	for hero_id in HEROES:
		var source_path := "res://assets/heroes/%s/source_atlas_pixel.png" % hero_id
		var source := Image.new()
		if source.load(source_path) != OK or source.get_width() < 1200 or source.get_height() < 1200:
			push_error("Invalid hero source atlas: %s" % source_path)
			failures += 1
			continue
		if not source.detect_alpha():
			push_error("Hero source atlas has no transparency: %s" % source_path)
			failures += 1
			continue
		var base := "res://assets/heroes/%s" % hero_id
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(base))
		var portrait := Image.create(OUTPUT_FRAME, OUTPUT_FRAME, false, Image.FORMAT_RGBA8)
		for state_index in STATES.size():
			var strip := Image.create(OUTPUT_FRAME * 4, OUTPUT_FRAME, false, Image.FORMAT_RGBA8)
			for frame in 4:
				var x0 := roundi(float(state_index) * source.get_width() / 5.0)
				var x1 := roundi(float(state_index + 1) * source.get_width() / 5.0)
				var y0 := roundi(float(frame) * source.get_height() / 4.0)
				var y1 := roundi(float(frame + 1) * source.get_height() / 4.0)
				var cell := Image.create(x1 - x0, y1 - y0, false, Image.FORMAT_RGBA8)
				cell.blit_rect(source, Rect2i(x0, y0, x1 - x0, y1 - y0), Vector2i.ZERO)
				var used := cell.get_used_rect()
				if used.size.x <= 0 or used.size.y <= 0:
					push_error("Empty %s frame %d: %s" % [STATES[state_index], frame, hero_id])
					failures += 1
					continue
				var cropped := Image.create(used.size.x, used.size.y, false, Image.FORMAT_RGBA8)
				cropped.blit_rect(cell, used, Vector2i.ZERO)
				var factor := minf(205.0 / float(cropped.get_width()), 240.0 / float(cropped.get_height()))
				var draw_width := maxi(1, roundi(cropped.get_width() * factor))
				var draw_height := maxi(1, roundi(cropped.get_height() * factor))
				cropped.resize(draw_width, draw_height, Image.INTERPOLATE_NEAREST)
				# Convert the high-resolution generated atlas into the same chunky
				# nearest-neighbour clusters used by the in-game Knight sprite sheets.
				var pixel_width := maxi(1, int(ceil(float(draw_width) / 2.0)))
				var pixel_height := maxi(1, int(ceil(float(draw_height) / 2.0)))
				cropped.resize(pixel_width, pixel_height, Image.INTERPOLATE_NEAREST)
				cropped.resize(draw_width, draw_height, Image.INTERPOLATE_NEAREST)
				var frame_image := Image.create(OUTPUT_FRAME, OUTPUT_FRAME, false, Image.FORMAT_RGBA8)
				frame_image.blit_rect(cropped, Rect2i(0, 0, draw_width, draw_height), Vector2i((OUTPUT_FRAME - draw_width) / 2, 240 - draw_height))
				strip.blit_rect(frame_image, Rect2i(0, 0, OUTPUT_FRAME, OUTPUT_FRAME), Vector2i(frame * OUTPUT_FRAME, 0))
				if state_index == 0 and frame == 0:
					portrait.blit_rect(frame_image, Rect2i(0, 0, OUTPUT_FRAME, OUTPUT_FRAME), Vector2i.ZERO)
			var output := "%s/%s.png" % [base, STATES[state_index]]
			if strip.save_png(ProjectSettings.globalize_path(output)) != OK:
				push_error("Failed to write %s" % output)
				failures += 1
		if portrait.save_png(ProjectSettings.globalize_path("%s/portrait.png" % base)) != OK:
			failures += 1
	print("OTHER HERO ATLAS CROPPING: ", "FAIL (%d)" % failures if failures else "PASS")
	quit(1 if failures else 0)
