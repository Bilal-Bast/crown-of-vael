class_name CloudSaveProvider
extends RefCounted

const SCHEMA_VERSION := 1
const MAX_SCHEMA_VERSION := 1

func save_cloud(_profile: SaveData) -> Dictionary:
	return {"ok": false, "error": "Cloud saves are unavailable"}

func load_cloud(_player_id: String) -> Dictionary:
	return {"ok": false, "error": "No cloud save found"}
