extends Control

@onready var instruction_label = $MarginContainer/VBoxContainer/InstructionLabel
@onready var back_button = $MarginContainer/VBoxContainer/BackButton

var current_step = 0
var steps = [
	"Добро пожаловать в обучение!\n\nЗдесь вы узнаете, как играть в эту игру.",
	
	"Цель игры:\n\nНабирайте очки, собирая 3 или более одинаковых элемента в ряд или столбец.",
	
	"Как менять элементы:\n\n1. Кликните на элемент, чтобы выделить его.\n2. Кликните на соседний элемент, чтобы поменять их местами.",
	
	"Совпадения:\n\nЕсли после обмена образуется ряд из 3+ одинаковых элементов, они исчезнут и вы получите очки!",
	
	"Комбо:\n\nНесколько совпадений подряд дают больше очков!\nСледите за количеством ходов.",
	
	"Уровни:\n\nВ игре 3 уровня сложности.\nКаждый уровень имеет свою цель по очкам."
]

func _ready():
	update_instruction()

func update_instruction():
	if current_step < steps.size():
		instruction_label.text = steps[current_step]

func _on_next_button_pressed():
	if current_step < steps.size() - 1:
		current_step += 1
		update_instruction()

func _on_prev_button_pressed():
	if current_step > 0:
		current_step -= 1
		update_instruction()

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
