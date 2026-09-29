class_name AuthProvider
extends RefCounted

func link(_provider: String, _player_id: String) -> Dictionary:
	return {"ok": false, "error": "Authentication unavailable"}

func sign_out() -> bool:
	return false
