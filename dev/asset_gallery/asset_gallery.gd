extends Control

const CampaignDataScript = preload("res://scripts/campaign/campaign_data.gd")
const EnemyArtServiceScript = preload("res://scripts/combat/enemy_art_service.gd")
const EffectPreviewScript = preload("res://dev/asset_gallery/effect_preview.gd")

const CATEGORIES := ["Heroes", "Enemies", "Bosses", "Backgrounds", "UI Icons", "Effects"]
const REGION_LABELS := ["All Regions", "Greenvale Outskirts", "Whispering Forest", "Ashen Highlands", "Frostfang Mountains", "Sunken Marshes", "Crimson Desert", "Ruined Kingdom", "Shadowlands", "Dragon Peaks", "Demon Realm", "Menu Backgrounds"]

var category_picker: OptionButton
var region_picker: OptionButton
var scroll: ScrollContainer
var gallery_content: VBoxContainer
var selected_category := "Heroes"
var selected_region := "All Regions"

func _ready() -> void:
	_build_interface()
	_refresh_gallery()

func _build_interface() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "GalleryBackdrop"
	backdrop.color = Color("0b1728")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var margin := MarginContainer.new()
	margin.name = "GalleryMargins"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		margin.add_theme_constant_override("margin_%s" % ["left" if edge == SIDE_LEFT else "top" if edge == SIDE_TOP else "right" if edge == SIDE_RIGHT else "bottom"], 24)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.name = "GalleryLayout"
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "ASSET GALLERY"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("ffd166"))
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Production art previews · idle strips animate when their frame layout is clear"
	subtitle.add_theme_color_override("font_color", Color("b8cbe2"))
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(subtitle)

	var filters := HBoxContainer.new()
	filters.name = "GalleryFilters"
	filters.add_theme_constant_override("separation", 12)
	layout.add_child(filters)

	category_picker = OptionButton.new()
	category_picker.name = "CategoryPicker"
	category_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for category in CATEGORIES:
		category_picker.add_item(category)
	category_picker.item_selected.connect(_on_category_selected)
	filters.add_child(category_picker)

	region_picker = OptionButton.new()
	region_picker.name = "RegionPicker"
	region_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for region_label in REGION_LABELS:
		region_picker.add_item(region_label)
	region_picker.item_selected.connect(_on_region_selected)
	filters.add_child(region_picker)

	scroll = ScrollContainer.new()
	scroll.name = "AssetScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)

	gallery_content = VBoxContainer.new()
	gallery_content.name = "AssetSections"
	gallery_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gallery_content.add_theme_constant_override("separation", 22)
	scroll.add_child(gallery_content)

func _on_category_selected(index: int) -> void:
	selected_category = CATEGORIES[index]
	_refresh_gallery()

func _on_region_selected(index: int) -> void:
	selected_region = REGION_LABELS[index]
	_refresh_gallery()

func _refresh_gallery() -> void:
	if gallery_content == null:
		return
	for child in gallery_content.get_children():
		child.queue_free()
	region_picker.visible = selected_category in ["Enemies", "Bosses", "Backgrounds"]
	var items := _items_for_category(selected_category)
	var sections: Dictionary = {}
	for item in items:
		var region_label := str(item.get("region", ""))
		if not _matches_region(region_label):
			continue
		var section := _section_for_item(item)
		if not sections.has(section):
			sections[section] = []
		(sections[section] as Array).append(item)

	var section_names: Array = sections.keys()
	section_names.sort()
	if section_names.is_empty():
		var empty := Label.new()
		empty.text = "No matching assets in this category yet."
		empty.add_theme_color_override("font_color", Color("b8cbe2"))
		gallery_content.add_child(empty)
		return
	for section_name in section_names:
		var heading := Label.new()
		heading.text = str(section_name).to_upper()
		heading.add_theme_font_size_override("font_size", 27)
		heading.add_theme_color_override("font_color", Color("ffd166"))
		gallery_content.add_child(heading)
		var grid := GridContainer.new()
		grid.name = "AssetGrid_%s" % str(section_name).replace(" ", "_")
		grid.columns = 4
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		gallery_content.add_child(grid)
		var section_items: Array = sections[section_name]
		section_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("label", "")) < str(b.get("label", "")))
		for item in section_items:
			grid.add_child(_make_asset_card(item))

func _matches_region(region_label: String) -> bool:
	if selected_region == "All Regions":
		return true
	if selected_region == "Menu Backgrounds":
		return region_label == "Menu Backgrounds"
	return region_label.is_empty() or region_label == selected_region

func _section_for_item(item: Dictionary) -> String:
	var category := str(item.get("kind", selected_category))
	var path := str(item.get("path", ""))
	var region_label := str(item.get("region", ""))
	if category in ["Enemies", "Bosses", "Backgrounds"]:
		return region_label if not region_label.is_empty() else "Other Backgrounds"
	if category == "Heroes":
		return "Pixel Battle Sprites" if "/pixel/" in path else "Standard Hero Art"
	if category == "UI Icons":
		if "/navigation/" in path:
			return "Navigation"
		if "/pixel/" in path:
			return "Pixel UI"
		return "Panels and Buttons"
	return "Procedural Combat Effects"

func _items_for_category(category: String) -> Array[Dictionary]:
	match category:
		"Heroes":
			var heroes: Array[Dictionary] = []
			for path in _png_files("res://assets/characters/heroes"):
				var file_name := path.get_file().to_lower()
				if file_name == "idle.png" or file_name == "squire_idle.png":
					heroes.append(_asset_item(path, "Heroes"))
			return heroes
		"Enemies":
			var enemies: Array[Dictionary] = []
			for path in _png_files("res://assets/characters/enemies"):
				if path.get_file().to_lower() == "idle.png":
					enemies.append(_asset_item(path, "Enemies"))
			return enemies
		"Bosses":
			return _boss_items()
		"Backgrounds":
			var backgrounds: Array[Dictionary] = []
			for path in _png_files("res://assets/environments"):
				backgrounds.append(_asset_item(path, "Backgrounds"))
			return backgrounds
		"UI Icons":
			var icons: Array[Dictionary] = []
			for path in _png_files("res://assets/ui/icons"):
				icons.append(_asset_item(path, "UI Icons"))
			for path in _png_files("res://assets/ui/panels"):
				icons.append(_asset_item(path, "UI Icons"))
			for path in _png_files("res://assets/ui/buttons"):
				icons.append(_asset_item(path, "UI Icons"))
			return icons
		"Effects":
			var effects: Array[Dictionary] = []
			for path in _png_files("res://assets/effects"):
				effects.append(_asset_item(path, "Effects"))
			for definition in [
				{"label": "Shield Bash · Shockwave", "skill": "shield_bash", "color": Color("9de8f2")},
				{"label": "Power Strike · Slash", "skill": "power_strike", "color": Color("ffe6a0")},
				{"label": "Whirlwind · Spin", "skill": "whirlwind_slash", "color": Color("d5e6ea")},
				{"label": "Iron Guard", "skill": "iron_guard", "color": Color("9bbbd1")},
				{"label": "Healing Light", "skill": "healing_light", "color": Color("a9efae")},
				{"label": "Battle Cry · Pulse", "skill": "battle_cry", "color": Color("edca79")},
			]:
				effects.append({"kind": "Effects", "label": str(definition["label"]), "skill": str(definition["skill"]), "color": definition["color"], "path": ""})
			return effects
	return []

func _boss_items() -> Array[Dictionary]:
	var bosses: Array[Dictionary] = []
	for region_index in CampaignDataScript.REGIONS.size():
		var region_id := region_index + 1
		var region_info: Dictionary = CampaignDataScript.REGIONS[region_index]
		var boss_name := str(region_info["boss"])
		var region_folder := str(EnemyArtServiceScript.ENEMY_REGION_FOLDERS[region_id])
		var enemy_folder := EnemyArtServiceScript.enemy_folder(boss_name, region_id)
		for style in ["standard", "pixel"]:
			var path := "res://assets/characters/enemies/%s/%s/%s/idle.png" % [style, region_folder, enemy_folder]
			if ResourceLoader.exists(path, "Texture2D"):
				bosses.append({"kind": "Bosses", "label": "%s · %s" % [boss_name, "Pixel" if style == "pixel" else "Standard"], "region": str(region_info["name"]), "path": path, "animate": style == "pixel"})
	return bosses

func _asset_item(path: String, category: String) -> Dictionary:
	var label := path.get_file().get_basename()
	if label in ["idle", "battle", "battle_bg", "boss_bg"]:
		label = path.get_base_dir().get_file()
	return {
		"kind": category,
		"label": _humanize(label),
		"region": _region_for_path(path),
		"path": path,
		"animate": category in ["Heroes", "Enemies"] and path.get_file().to_lower() in ["idle.png", "squire_idle.png"],
	}

func _region_for_path(path: String) -> String:
	if "/menus/" in path:
		return "Menu Backgrounds"
	for index in CampaignDataScript.REGIONS.size():
		var region_id := index + 1
		var region_name := str(CampaignDataScript.REGIONS[index]["name"])
		for folder in [str(EnemyArtServiceScript.ENEMY_REGION_FOLDERS[region_id]), str(EnemyArtServiceScript.BACKGROUND_REGION_FOLDERS[region_id])]:
			if "/%s/" % folder in path:
				return region_name
	return ""

func _make_asset_card(item: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 194)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("172941")
	style.border_color = Color("355576")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)

	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 6)
	card.add_child(contents)
	var preview: Control
	if str(item.get("kind", "")) == "Effects" and str(item.get("path", "")).is_empty():
		preview = EffectPreviewScript.new()
		preview.custom_minimum_size = Vector2(0, 124)
		preview.call("configure", str(item.get("skill", "shield_bash")), item.get("color", Color.WHITE))
	else:
		var texture_preview := TextureRect.new()
		texture_preview.custom_minimum_size = Vector2(0, 124)
		texture_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texture_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var texture := ResourceLoader.load(str(item.get("path", "")), "Texture2D") as Texture2D
		if texture != null:
			texture_preview.texture = _idle_animation(texture) if bool(item.get("animate", false)) else texture
		preview = texture_preview
	contents.add_child(preview)
	var label := Label.new()
	label.text = str(item.get("label", "Asset"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("f3f7ff"))
	label.add_theme_font_size_override("font_size", 17)
	label.clip_text = true
	contents.add_child(label)
	return card

func _idle_animation(source: Texture2D) -> Texture2D:
	var frame_count := roundi(float(source.get_width()) / float(source.get_height()))
	if frame_count < 2 or frame_count > 8 or source.get_width() % frame_count != 0:
		return source
	var frame_width := source.get_width() / frame_count
	var aspect := float(frame_width) / float(source.get_height())
	if aspect < 0.55 or aspect > 1.8:
		return source
	var animation := AnimatedTexture.new()
	animation.frames = frame_count
	for index in frame_count:
		var frame := AtlasTexture.new()
		frame.atlas = source
		frame.region = Rect2i(index * frame_width, 0, frame_width, source.get_height())
		animation.set_frame_texture(index, frame)
		animation.set_frame_duration(index, 0.14)
	return animation

func _png_files(root_path: String) -> Array[String]:
	var paths: Array[String] = []
	_collect_png_files(root_path, paths)
	paths.sort()
	return paths

func _collect_png_files(root_path: String, paths: Array[String]) -> void:
	var directory := DirAccess.open(root_path)
	if directory == null:
		return
	for file_name in directory.get_files():
		if file_name.get_extension().to_lower() == "png":
			paths.append("%s/%s" % [root_path.trim_suffix("/"), file_name])
	for directory_name in directory.get_directories():
		_collect_png_files("%s/%s" % [root_path.trim_suffix("/"), directory_name], paths)

func _humanize(value: String) -> String:
	return value.replace("_", " ").replace("-", " ").capitalize()
