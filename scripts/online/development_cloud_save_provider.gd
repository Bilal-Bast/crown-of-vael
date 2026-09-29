class_name DevelopmentCloudSaveProvider
extends CloudSaveProvider

const CLOUD_DIR := "user://development_cloud"
var fail_next := false

func _path(player_id: String) -> String:
	return "%s/%s.json" % [CLOUD_DIR, player_id.validate_filename()]

func save_cloud(profile: SaveData) -> Dictionary:
	if fail_next:
		fail_next = false
		return {"ok": false, "error": "Cloud sync failed. Your local save is safe."}
	profile.save()
	var source := FileAccess.open(profile.save_path, FileAccess.READ)
	if source == null: return {"ok": false, "error": "Could not read the local save."}
	var directory := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CLOUD_DIR))
	if directory != OK and directory != ERR_ALREADY_EXISTS: return {"ok": false, "error": "Cloud storage is unavailable."}
	var envelope := {"schema_version": SCHEMA_VERSION, "player_id": str(profile.account_meta.player_id), "saved_at": Time.get_datetime_string_from_system(), "progression_timestamp": int(profile.cloud_meta.progression_timestamp), "summary": _summary(profile), "payload": JSON.parse_string(source.get_as_text())}
	var output := FileAccess.open(_path(str(profile.account_meta.player_id)), FileAccess.WRITE)
	if output == null: return {"ok": false, "error": "Could not write the development cloud save."}
	output.store_string(JSON.stringify(envelope))
	return {"ok": true, "saved_at": envelope.saved_at, "summary": envelope.summary, "schema_version": SCHEMA_VERSION}

func load_cloud(player_id: String) -> Dictionary:
	if fail_next:
		fail_next = false
		return {"ok": false, "error": "Cloud restore failed. Your local save is safe."}
	var path := _path(player_id)
	if not FileAccess.file_exists(path): return {"ok": false, "error": "No cloud save found for this player."}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {"ok": false, "error": "Cloud save could not be read."}
	var value: Variant = JSON.parse_string(file.get_as_text())
	if not value is Dictionary or int(value.get("schema_version", 0)) < 1 or int(value.get("schema_version", 0)) > MAX_SCHEMA_VERSION:
		return {"ok": false, "error": "This cloud save version is not supported."}
	if not value.get("payload", null) is Dictionary: return {"ok": false, "error": "Cloud save data is incomplete."}
	return {"ok": true, "cloud": value}

func _summary(profile: SaveData) -> Dictionary:
	return {"level": profile.level, "power": profile.power(), "difficulty": CampaignData.DIFFICULTIES[profile.campaign_difficulty], "region": profile.region, "stage": profile.stage}
