extends Control

@onready var level_label = $MarginContainer/VBoxContainer/LevelLabel
@onready var start_button = $MarginContainer/VBoxContainer/StartButton
@onready var tutorial_button = $MarginContainer/VBoxContainer/TutorialButton
@onready var quit_button = $MarginContainer/VBoxContainer/QuitButton

var current_level = 1
var max_levels = 3

func _ready():
	update_level_label()

func _on_start_button_pressed():
	# Переход к игровой сцене с текущим уровнем
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	GameManager.current_level = current_level
	GameManager.level_data = get_level_data(current_level)

func _on_tutorial_button_pressed():
	get_tree().change_scene_to_file("res://scenes/tutorial.tscn")

func _on_quit_button_pressed():
	get_tree().quit()

func _on_left_button_pressed():
	if current_level > 1:
		current_level -= 1
		update_level_label()

func _on_right_button_pressed():
	if current_level < max_levels:
		current_level += 1
		update_level_label()

func update_level_label():
	level_label.text = "Уровень %d / %d" % [current_level, max_levels]
	# Блокируем кнопки навигации если достигнуты границы
	$MarginContainer/VBoxContainer/HBoxContainer/LeftButton.disabled = (current_level == 1)
	$MarginContainer/VBoxContainer/HBoxContainer/RightButton.disabled = (current_level == max_levels)

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
			return get_level_data(1)
