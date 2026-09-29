class_name DevelopmentAuthProvider
extends AuthProvider

var fail_next := false

func link(provider: String, player_id: String) -> Dictionary:
	if fail_next:
		fail_next = false
		return {"ok": false, "error": "Account linking is unavailable right now."}
	if provider not in ["Google", "Apple"]: return {"ok": false, "error": "Unsupported sign-in provider."}
	return {"ok": true, "provider": provider, "player_id": player_id}

func sign_out() -> bool:
	if fail_next:
		fail_next = false
		return false
	return true
