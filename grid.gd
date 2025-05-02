@tool
extends GridContainer

@export var width := 5:
	set(value): 
		width = value
		_remove_grid()
		_create_grid()
@export var height := 5:
	set(value): 
		height = value
		_remove_grid()
		_create_grid()
@export var cellWidth := 100:
	set(value): 
		cellWidth = value
		_remove_grid()
		_create_grid()
@export var cellHeight := 100:
	set(value):
		cellHeight = value
		_remove_grid()
		_create_grid()

const GRID_CELL = preload("res://grid_cell.tscn")
const borderSize = 4

var selectedCharacter: CharacterBody2D
var aStar: AStarGrid2D
var occupiedTiles = {}  # Tracks occupied tiles
var validTiles = []  # Stores valid movement tiles

func _ready() -> void:
	aStar = AStarGrid2D.new()
	aStar.region = Rect2i(0, 0, width, height)
	aStar.cell_size = Vector2i(cellWidth + borderSize, cellHeight + borderSize)
	aStar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	aStar.update()
	for x in range(width):
		for y in range(height):
			aStar.set_point_solid(Vector2i(x, y), false)

	add_to_group("grid")
	_add_signals()
	_create_grid()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == 1 and event.is_pressed():
		_on_left_click()

func _on_left_click():
	var selectedNode = _get_selected_node()
	if selectedNode and selectedCharacter:
		_move_char(selectedNode)
	else:
		selectedCharacter = null
		_deselect_all()

func _move_char(targetNode):
	var targetGridPos = _get_grid_position(targetNode.get_center_position())

	if targetGridPos not in validTiles:
		print("Invalid move: Not a highlighted tile!")
		return
	if targetGridPos in occupiedTiles:
		print("Invalid move: Tile is already occupied!")
		return

	if selectedCharacter:
		var currentPos = _get_grid_position(selectedCharacter.global_position)
		occupiedTiles.erase(currentPos)

	occupiedTiles[targetGridPos] = selectedCharacter

	var positionSequence = _get_movement_sequence(targetNode.get_center_position())
	if positionSequence.is_empty():
		print("No valid path found!")
		return
	selectedCharacter.move_to(positionSequence)

	selectedCharacter = null
	_deselect_all()

func _get_movement_sequence(targetPosition) -> Array:
	var positionSequence = []
	if not selectedCharacter:
		print("No character selected")
		return positionSequence

	var startGridPos = _get_grid_position(selectedCharacter.global_position)
	var endGridPos = _get_grid_position(targetPosition)

	if not aStar.is_in_bounds(startGridPos.x, startGridPos.y) or not aStar.is_in_bounds(endGridPos.x, endGridPos.y):
		print("Invalid path: Out of grid bounds")
		return positionSequence

	return aStar.get_id_path(startGridPos, endGridPos)

func _get_grid_position(position: Vector2) -> Vector2i:
	var local_pos = position - global_position
	var grid_x = int(local_pos.x / (cellWidth + borderSize))
	var grid_y = int(local_pos.y / (cellHeight + borderSize))
	return Vector2i(grid_x, grid_y)

func _add_signals():
	await get_tree().current_scene.ready
	for char in get_tree().get_nodes_in_group("character"):
		char.character_selected.connect(_on_character_selected.bind(char))

func _create_grid():
	columns = width
	for i in width * height:
		var gridCellNode = GRID_CELL.instantiate()
		gridCellNode.custom_minimum_size = Vector2(cellWidth, cellHeight)
		add_child(gridCellNode.duplicate())

func _remove_grid():
	for node in get_children():
		node.queue_free()

func _on_character_selected(movement, char):
	selectedCharacter = char 
	_deselect_all()
	var selectedNode = _get_selected_node()
	selectedNode.highlight_cell()
	_select_possible_movement(movement)

func _deselect_all():
	validTiles.clear()
	for node in get_children():
		node.deselect_cell()

func _get_selected_node():
	for node in get_children():
		if node.get_global_rect().has_point(get_global_mouse_position()):
			return node

func _select_possible_movement(movement):
	var selectedNode = _get_selected_node()
	var stepX = cellWidth + borderSize
	var stepY = cellHeight + borderSize
	var directions = [
		Vector2(stepX, 0),
		Vector2(-stepX, 0),
		Vector2(0, stepY),
		Vector2(0, -stepY)
	]

	validTiles.clear()
	var selectNodes = []
	var checkNodes = [selectedNode]

	for i in movement:
		var newCheckNodes = []
		for checkNode in checkNodes:
			for direction in directions:
				var nextNode = _get_cell(checkNode.get_center_position() + direction)
				if nextNode:
					var gridPos = _get_grid_position(nextNode.get_center_position())
					if gridPos not in occupiedTiles and gridPos not in validTiles:
						newCheckNodes.append(nextNode)
						selectNodes.append(nextNode)
		checkNodes = newCheckNodes

	for node in selectNodes:
		var gridPos = _get_grid_position(node.get_center_position())
		validTiles.append(gridPos)
		node.select_cell()

func _get_cell(position: Vector2):
	for node in get_children():
		if node.get_global_rect().has_point(position):
			return node
