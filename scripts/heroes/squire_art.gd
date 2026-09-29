class_name SquireArt
extends RefCounted

const IDLE_PATH := "res://assets/heroes/knight/squire/squire_idle.png"
const ATTACK_PATH := "res://assets/heroes/knight/squire/squire_attack.png"
const GUARD_PATH := "res://assets/heroes/knight/squire/squire_guard.png"
const PORTRAIT_PATH := "res://assets/heroes/knight/squire/squire_portrait.png"

static func load_texture(path: String) -> Texture2D:
	if path == IDLE_PATH: return HeroArtService.texture_for(0, "idle")
	if path == ATTACK_PATH: return HeroArtService.texture_for(0, "attack")
	if path == GUARD_PATH: return HeroArtService.texture_for(0, "guard")
	if path == PORTRAIT_PATH: return HeroArtService.texture_for(0, "portrait")
	if not ResourceLoader.exists(path, "Texture2D"):
		return null
	return ResourceLoader.load(path, "Texture2D") as Texture2D
