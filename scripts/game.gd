extends Node2D

@export_subgroup("Properties")
@export var width: int = 8
@export var height: int = 8
@export var offset: int = 68
@export var tile_types_count: int = 5

@export_subgroup("Scenes")
@export var tile_scene: PackedScene 
@export var sparkles_scene: PackedScene

@export_subgroup("Tiles")
@export var textures: Array[Texture2D] 

@export_subgroup("Cursors")
@export var open_hand_cursor: Texture2D
@export var closed_hand_cursor: Texture2D

@onready var container = $Board
@onready var score_label = $UI/ScoreLabel
@onready var moves_label = $UI/MovesLabel
@onready var level_label = $UI/LevelLabel
@onready var game_over_panel = $UI/GameOverPanel
@onready var level_complete_panel = $UI/LevelCompletePanel

# State
var grid = []
var selected_tile = Vector2i(-1, -1)
var is_swapping = false
var combo_count: int = 0
var current_score: int = 0

func _ready():
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.game_over.connect(_on_game_over)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.moves_changed.connect(_on_moves_changed)
	
	# Инициализация уровня из GameManager
	var level = GameManager.current_level
	var level_data = GameManager.get_level_data(level)
	
	width = level_data.get("width", 8)
	height = level_data.get("height", 8)
	tile_types_count = min(level_data.get("tile_types", 5), textures.size())
	
	GameManager.start_level(level)
	
	level_label.text = "Уровень %d" % level
	
	set_cursor(open_hand_cursor)
	randomize()
	setup_grid_array() 
	process_board_state()
	center_grid_on_screen()
	get_viewport().size_changed.connect(center_grid_on_screen)

func center_grid_on_screen():
	container.position = get_viewport_rect().size / 2.0 - Vector2(width - 1, height - 1) * offset / 2.0

func setup_grid_array():
	grid = []
	for x in width:
		grid.append([])
		grid[x].resize(height)
		grid[x].fill(null)
		
	for x in width:
		for y in height:
			spawn_at(x, y)

func spawn_at(x, y):
	var created_piece = tile_scene.instantiate() 
	var random_index = randi_range(0, tile_types_count - 1)
	
	container.add_child(created_piece) 
	created_piece.set_tile_type(str(random_index), textures[random_index]) 
	created_piece.tile_pressed.connect(_on_tile_pressed) 
	created_piece.grid_position = Vector2i(x, y) 
	created_piece.position = grid_to_pixel(x, y) 
	
	grid[x][y] = created_piece

func _on_tile_pressed(grid_position: Vector2i):
	if is_swapping or GameManager.is_game_over:
		return
	
	if selected_tile == Vector2i(-1, -1):
		selected_tile = grid_position
		set_cursor(closed_hand_cursor)
		grid[selected_tile.x][selected_tile.y].set_selected(true)
	else:
		var first = selected_tile
		grid[first.x][first.y].set_selected(false)
		
		if first == grid_position:
			selected_tile = Vector2i(-1, -1)
			set_cursor(open_hand_cursor)
			return
		
		selected_tile = Vector2i(-1, -1)
		set_cursor(open_hand_cursor)
		
		var diff = grid_position - first
		if abs(diff.x) + abs(diff.y) == 1:
			handle_swap_logic(first, grid_position)
			GameManager.decrease_moves()
		else:
			selected_tile = grid_position
			set_cursor(closed_hand_cursor)
			grid[selected_tile.x][selected_tile.y].set_selected(true)

func handle_swap_logic(pos_a: Vector2i, pos_b: Vector2i):
	is_swapping = true
	swap_pieces(pos_a, pos_b)
	Audio.play("res://sounds/tile-swap.ogg", false, randf_range(0.8, 1.2), 0.3)
	
	await get_tree().create_timer(0.3).timeout
	
	if find_matches().size() > 0:
		process_board_state()
	else:
		swap_pieces(pos_a, pos_b)
		Audio.play("res://sounds/tile-swap.ogg", false, 2, 0.3)
		await get_tree().create_timer(0.3).timeout
		is_swapping = false

func swap_pieces(a: Vector2i, b: Vector2i):
	var piece_a = grid[a.x][a.y]
	var piece_b = grid[b.x][b.y]
	
	if piece_a and piece_b:
		grid[a.x][a.y] = piece_b
		grid[b.x][b.y] = piece_a
		
		piece_a.grid_position = b
		piece_b.grid_position = a
		
		piece_a.move_to(grid_to_pixel(b.x, b.y), false)
		piece_b.move_to(grid_to_pixel(a.x, a.y), false)

func find_matches() -> Array:
	var matched_dict = {}

	for y in height:
		for x in range(width - 2):
			var p1 = grid[x][y]; var p2 = grid[x+1][y]; var p3 = grid[x+2][y]
			if p1 and p2 and p3 and p1.type == p2.type and p1.type == p3.type:
				for p in [p1, p2, p3]: matched_dict[p] = true

	for x in width:
		for y in range(height - 2):
			var p1 = grid[x][y]; var p2 = grid[x][y+1]; var p3 = grid[x][y+2]
			if p1 and p2 and p3 and p1.type == p2.type and p1.type == p3.type:
				for p in [p1, p2, p3]: matched_dict[p] = true

	return matched_dict.keys()

func process_board_state():
	combo_count = 0 
	var matches = find_matches()
	
	while matches.size() > 0:
		combo_count += 1
		Audio.play("res://sounds/tile-match.ogg", true, 1.0 + (combo_count * 0.1))
		
		var points = matches.size() * 10 * combo_count
		GameManager.add_score(points)
		
		for piece in matches:
			var effect = sparkles_scene.instantiate()
			effect.position = piece.position
			container.add_child(effect)
			
			grid[piece.grid_position.x][piece.grid_position.y] = null
			
			var tween = piece.create_tween()
			tween.tween_property(piece, "scale", Vector2.ZERO, 0.2)
			tween.finished.connect(piece.queue_free)
		
		await get_tree().create_timer(0.3).timeout
		await collapse_columns()
		await refill_board()
		
		matches = find_matches()
	
	is_swapping = false

func collapse_columns():
	for x in width:
		for y in range(height - 1, -1, -1):
			if grid[x][y] == null:
				for k in range(y - 1, -1, -1):
					if grid[x][k] != null:
						grid[x][y] = grid[x][k]
						grid[x][k] = null
						grid[x][y].grid_position = Vector2i(x, y)
						grid[x][y].move_to(grid_to_pixel(x, y))
						break
	await get_tree().create_timer(0.3).timeout

func refill_board():
	for x in width:
		for y in height:
			if grid[x][y] == null:
				spawn_at(x, y)
				grid[x][y].position.y -= offset * 2 
				grid[x][y].move_to(grid_to_pixel(x, y))
	await get_tree().create_timer(0.3).timeout

func grid_to_pixel(column: int, row: int) -> Vector2:
	return Vector2(offset * column, offset * row)

func is_within_grid(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height

func set_cursor(cursor_texture: Texture2D):
	Input.set_custom_mouse_cursor(cursor_texture, Input.CURSOR_ARROW, Vector2(16, 16))

func _on_score_changed(new_score: int):
	current_score = new_score
	score_label.text = "Очки: %d" % current_score

func _on_moves_changed(moves_left: int):
	moves_label.text = "Ходы: %d" % moves_left

func _on_level_completed():
	level_complete_panel.visible = true
	get_tree().paused = true

func _on_game_over():
	game_over_panel.visible = true
	get_tree().paused = true

func _on_restart_button_pressed():
	get_tree().paused = false
	game_over_panel.visible = false
	level_complete_panel.visible = false
	get_tree().reload_current_scene()

func _on_menu_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_next_level_button_pressed():
	GameManager.current_level += 1
	if GameManager.current_level > 3:
		GameManager.current_level = 1
	get_tree().paused = false
	get_tree().reload_current_scene()
