extends Node

var player_stats: PlayerStats = null
var load_on_start: bool = false

func setup_session(load_game: bool):
	if load_game and SaveManager.has_save_file():
		player_stats = SaveManager.load_game()
	else:
		player_stats = PlayerStats.new()
	
	if player_stats == null:
		player_stats = PlayerStats.new()
	if not player_stats.stats_changed.is_connected(SaveManager.save_game):
		player_stats.stats_changed.connect(SaveManager.save_game.bind(player_stats))

func end_session():
	if player_stats != null and player_stats.stats_changed.is_connected(SaveManager.save_game):
		player_stats.stats_changed.disconnect(SaveManager.save_game)
	player_stats = null
