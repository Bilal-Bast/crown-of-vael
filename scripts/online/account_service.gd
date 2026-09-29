class_name AccountService
extends RefCounted

const MIN_NAME := 3
const MAX_NAME := 20
var profile: SaveData
var auth: AuthProvider
var cloud: CloudSaveProvider
var last_error := ""
var connection_state := OnlineState.DEVELOPMENT_ONLINE

func _init(value: SaveData, auth_provider: AuthProvider = null, cloud_provider: CloudSaveProvider = null) -> void:
	profile = value
	auth = auth_provider if auth_provider != null else DevelopmentAuthProvider.new()
	cloud = cloud_provider if cloud_provider != null else DevelopmentCloudSaveProvider.new()

func set_display_name(value: String) -> bool:
	var cleaned := value.strip_edges()
	if cleaned.length() < MIN_NAME or cleaned.length() > MAX_NAME or cleaned.contains("[") or cleaned.contains("]") or cleaned.contains("/") or cleaned.contains("\\") or cleaned.contains("\n") or cleaned.contains("\t"):
		last_error = "Name must be %d–%d characters and use plain text." % [MIN_NAME, MAX_NAME]
		return false
	# Uniqueness is intentionally local only; production identity must validate it server-side.
	profile.account_meta["display_name"] = cleaned
	profile.save()
	last_error = ""
	return true

func link(provider: String, resolution: String = "") -> Dictionary:
	var result := auth.link(provider, str(profile.account_meta.player_id))
	if not bool(result.get("ok", false)):
		connection_state = OnlineState.OFFLINE
		last_error = str(result.get("error", "Account linking failed."))
		return result
	var cloud_result := cloud.load_cloud(str(profile.account_meta.player_id))
	if bool(cloud_result.get("ok", false)):
		if resolution == "": return {"ok": true, "conflict": true, "cloud": cloud_result.cloud}
		if resolution == "Use Cloud":
			var restored := _restore_payload(cloud_result.cloud.payload)
			if not restored: return {"ok": false, "error": "Cloud restore failed. Local progress remains safe."}
		elif resolution != "Keep Local": return {"ok": false, "error": "Choose Keep Local or Use Cloud."}
	profile.account_meta["account_type"] = "Linked"
	profile.account_meta["provider"] = provider
	profile.save()
	connection_state = OnlineState.DEVELOPMENT_ONLINE
	last_error = ""
	return {"ok": true, "conflict": false}

func sync_now() -> Dictionary:
	if str(profile.account_meta.get("account_type", "Guest")) != "Linked": return {"ok": false, "error": "Link an account to enable cloud saves."}
	var result := cloud.save_cloud(profile)
	connection_state = OnlineState.CONNECTED if bool(result.get("ok", false)) else OnlineState.OFFLINE
	profile.cloud_meta["sync_status"] = "Synced" if bool(result.get("ok", false)) else str(result.get("error", "Sync failed"))
	if bool(result.get("ok", false)): profile.cloud_meta["last_cloud_sync"] = str(result.saved_at)
	profile.save()
	return result

func inspect_cloud() -> Dictionary:
	var result := cloud.load_cloud(str(profile.account_meta.player_id))
	if not bool(result.get("ok", false)): return result
	profile.save()
	var remote: Dictionary = result.cloud
	var local_summary := _summary(profile)
	var local_file := FileAccess.open(profile.save_path, FileAccess.READ)
	var local_payload: Variant = JSON.parse_string(local_file.get_as_text()) if local_file != null else {}
	var cloud_payload: Variant = remote.get("payload", {})
	var mismatch := not _same_progress(local_payload, cloud_payload) or int(remote.get("schema_version", 0)) > CloudSaveProvider.MAX_SCHEMA_VERSION
	return {"ok": true, "conflict": mismatch, "local": local_summary, "cloud": remote.summary, "saved_at": remote.saved_at, "schema_version": remote.schema_version, "cloud_envelope": remote}

func _same_progress(local_value: Variant, cloud_value: Variant) -> bool:
	if not local_value is Dictionary or not cloud_value is Dictionary: return false
	var local: Dictionary = local_value.duplicate(true)
	var remote: Dictionary = cloud_value.duplicate(true)
	for payload in [local, remote]:
		if payload.has("account_meta") and payload.account_meta is Dictionary: payload.account_meta.erase("last_local_save")
		if payload.has("cloud_meta") and payload.cloud_meta is Dictionary:
			payload.cloud_meta.erase("progression_timestamp")
			payload.cloud_meta.erase("last_cloud_sync")
			payload.cloud_meta.erase("sync_status")
	return local == remote

func resolve_cloud(resolution: String) -> Dictionary:
	if resolution == "Keep Local": return sync_now()
	if resolution != "Use Cloud": return {"ok": false, "error": "Choose Keep Local or Use Cloud."}
	var result := cloud.load_cloud(str(profile.account_meta.player_id))
	if not bool(result.get("ok", false)): return result
	if not _restore_payload(result.cloud.payload): return {"ok": false, "error": "Cloud data could not be restored safely."}
	profile.account_meta["account_type"] = "Linked"
	profile.cloud_meta["last_cloud_sync"] = str(result.cloud.saved_at)
	profile.cloud_meta["sync_status"] = "Restored"
	profile.save()
	return {"ok": true}

func restore_cloud() -> Dictionary:
	return resolve_cloud("Use Cloud")

func sign_out() -> bool:
	if str(profile.account_meta.get("account_type", "Guest")) == "Linked" and not auth.sign_out():
		last_error = "Sign out failed. Local progress remains available."
		return false
	profile.account_meta["account_type"] = "Guest"
	profile.account_meta["provider"] = ""
	profile.cloud_meta["sync_status"] = "Local only"
	profile.save()
	return true

func _restore_payload(payload: Dictionary) -> bool:
	if int(payload.get("phase11_version", 0)) > 1: return false
	var temp_path := "user://cloud_restore_temp.save"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(payload))
	file.close()
	var restored := SaveData.load_from(temp_path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
	var local_path := profile.save_path
	for property in restored.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var property_name := str(property.name)
			if property_name == "save_path": continue
			var value: Variant = restored.get(property_name)
			profile.set(property_name, value.duplicate(true) if value is Dictionary or value is Array else value)
	profile.save_path = local_path
	profile.save()
	return true

func _summary(value: SaveData) -> Dictionary:
	return {"level": value.level, "power": value.power(), "difficulty": CampaignData.DIFFICULTIES[value.campaign_difficulty], "region": value.region, "stage": value.stage, "last_save": value.account_meta.get("last_local_save", "")}
