class_name SquireArt
extends RefCounted

const IDLE_PATH := "res://assets/heroes/knight/squire/squire_idle.png"
const ATTACK_PATH := "res://assets/heroes/knight/squire/squire_attack.png"
const GUARD_PATH := "res://assets/heroes/knight/squire/squire_guard.png"
const PORTRAIT_PATH := "res://assets/heroes/knight/squire/squire_portrait.png"

static func load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path, "Texture2D"):
		return null
	return ResourceLoader.load(path, "Texture2D") as Texture2D
