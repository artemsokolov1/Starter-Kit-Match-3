extends Node

var current_level: int = 1
var level_data: Dictionary = {}
var score: int = 0
var moves_left: int = 0
var is_game_over: bool = false

signal level_completed
signal game_over
signal score_changed(new_score: int)
signal moves_changed(moves_left: int)

func _ready():
	pass

func start_level(level: int):
	current_level = level
	level_data = get_level_data(level)
	score = 0
	moves_left = level_data.get("moves", 20)
	is_game_over = false
	score_changed.emit(score)
	moves_changed.emit(moves_left)

func add_score(points: int):
	score += points
	score_changed.emit(score)
	check_level_completion()

func decrease_moves():
	if not is_game_over:
		moves_left -= 1
		moves_changed.emit(moves_left)
		if moves_left <= 0:
			end_game()

func check_level_completion():
	var target = level_data.get("target_score", 1000)
	if score >= target and not is_game_over:
		level_completed.emit()

func end_game():
	is_game_over = true
	game_over.emit()

func get_level_data(level: int) -> Dictionary:
	match level:
		1:
			return {
				"width": 6,
				"height": 6,
				"tile_types": 3,
				"target_score": 1000,
				"moves": 20
			}
		2:
			return {
				"width": 7,
				"height": 7,
				"tile_types": 4,
				"target_score": 2500,
				"moves": 25
			}
		3:
			return {
				"width": 8,
				"height": 8,
				"tile_types": 5,
				"target_score": 5000,
				"moves": 30
			}
		_:
			return {
				"width": 8,
				"height": 8,
				"tile_types": 5,
				"target_score": 1000,
				"moves": 20
			}
