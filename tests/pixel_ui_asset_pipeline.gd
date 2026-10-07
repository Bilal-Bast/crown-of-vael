extends SceneTree

const SOURCE := {
	"equipment": "res://assets/ui/icons/pixel/source/equipment_atlas.png",
	"artifacts": "res://assets/ui/icons/pixel/source/artifact_atlas.png",
	"skills": "res://assets/ui/icons/pixel/source/skill_atlas.png",
}
const ICONS := {
	"equipment": ["weapon", "helmet", "armor", "gloves", "boots", "necklace", "ring"],
	"artifacts": ["blood_crown", "hourglass_arkon", "dragon_heart", "dragon_fang", "dragon_eye", "guardian_sigil", "phoenix_feather"],
	"skills": ["shield_bash", "power_strike", "whirlwind_slash", "iron_guard", "quick_slash", "battle_cry", "piercing_strike", "healing_light"],
}
const OUTPUT_DIR := "res://assets/ui/icons/pixel"
const CANVAS_SIZE := 96
const ICON_SIZE := 86

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var failed := false
	for key in SOURCE:
		var image := Image.load_from_file(ProjectSettings.globalize_path(SOURCE[key]))
		if image == null:
			push_error("Could not load atlas " + key)
			failed = true
			continue
		image.convert(Image.FORMAT_RGBA8)
		var min_alpha := 255
		var max_alpha := 0
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var alpha := roundi(image.get_pixel(x, y).a * 255.0)
				min_alpha = mini(min_alpha, alpha)
				max_alpha = maxi(max_alpha, alpha)
		if min_alpha != 0 or max_alpha != 255:
			push_error("Atlas background is not transparent: " + key)
			failed = true
		var names: Array = ICONS[key]
		var saved := 0
		for index in names.size():
			var column := index % 4
			var row := index / 4
			var left := roundi(float(column) * image.get_width() / 4.0)
			var right := roundi(float(column + 1) * image.get_width() / 4.0)
			var top := roundi(float(row) * image.get_height() / 2.0)
			var bottom := roundi(float(row + 1) * image.get_height() / 2.0)
			var cell := image.get_region(Rect2i(left, top, right - left, bottom - top))
			var bounds := cell.get_used_rect()
			if bounds.size.x == 0 or bounds.size.y == 0:
				push_error("Empty cell %s/%s" % [key, names[index]])
				failed = true
				continue
			var sprite := cell.get_region(bounds)
			for y in sprite.get_height():
				for x in sprite.get_width():
					var color := sprite.get_pixel(x, y)
					color.a = 1.0 if color.a >= 0.5 else 0.0
					sprite.set_pixel(x, y, color)
			var factor := minf(float(ICON_SIZE) / sprite.get_width(), float(ICON_SIZE) / sprite.get_height())
			var scaled := sprite.duplicate()
			scaled.resize(maxi(1, roundi(sprite.get_width() * factor)), maxi(1, roundi(sprite.get_height() * factor)), Image.INTERPOLATE_NEAREST)
			var canvas := Image.create(CANVAS_SIZE, CANVAS_SIZE, false, Image.FORMAT_RGBA8)
			var dest := Vector2i((CANVAS_SIZE - scaled.get_width()) / 2, (CANVAS_SIZE - scaled.get_height()) / 2)
			canvas.blit_rect(scaled, Rect2i(Vector2i.ZERO, scaled.get_size()), dest)
			var path := "%s/%s/%s.png" % [OUTPUT_DIR, key, names[index]]
			if canvas.save_png(ProjectSettings.globalize_path(path)) != OK:
				push_error("Could not write " + path)
				failed = true
			else:
				saved += 1
		if saved != names.size():
			failed = true
		print("PROCESSED %s: %d transparent nearest-neighbor icons" % [key, saved])
	print("PIXEL UI ASSET PIPELINE: %s" % ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
