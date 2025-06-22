extends Node
const SAVE_PATH = "user://savegame.tres"

func save_game(stats: PlayerStats):
	ResourceSaver.save(stats, SAVE_PATH)
	print("Game Saved!")

func load_game() -> PlayerStats:
	if not FileAccess.file_exists(SAVE_PATH): return null
	var loaded_res = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CacheMode.CACHE_MODE_IGNORE)
	if loaded_res is PlayerStats:
		return loaded_res.duplicate()
	return null

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
