extends Spatial

const CRAM_BLOCK = preload("res://CramBlock.tscn")

const CAMERA_SPEED = 1
const CAMERA_OFFSET = 2
const CAMERA_MIN_ROTATION = -89
const CAMERA_MAX_ROTATION = 5
const CHECKBOARD_THICKNESS = 0.2

onready var blocks = $Blocks
onready var board_bounds = $BoardBounds
onready var cursor = $Cursor
onready var camera = $CameraPivot/Camera
onready var camera_pivot = $CameraPivot
onready var main_menu = get_parent().get_node("MainMenu")
onready var gui = get_parent().get_node("GUI")

export var width = 5 # X / col1
export var length = 5 # Z / col2
export var height = 5 # Y / row
var board_array = []
var empty_spaces = width * length * height
var game_over = true
var nimber_calculated = false
var nimber_label_updated = false
var ai_play = false
var ai_turn = false

var known_boards = {}

enum Block {
	EMPTY,
	BLUE,
	RED
}
var player_color = Block.BLUE

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if not game_over:
		if not ai_play:
			human_play()
		else:
			ai_play()
	else:
		if Input.is_action_just_pressed("ui_cancel"):
			return_to_main_menu()

func ai_play() -> void:
	# AI's turn
	if ai_turn:
		var move = find_best_move(get_impartial_board((board_array)))
		var pos1 = Vector3(move[0][1], move[0][0], move[0][2])
		var pos2 = Vector3(move[1][1], move[1][0], move[1][2])
		place_blocks_at(pos1, pos2, player_color)
		toggle_player_ai()
	# Player's turn
	else:
		# Return to main menu
		if Input.is_action_just_pressed("ui_cancel"):
			return_to_main_menu()
		
		# Cursor movement
		var forward = Vector3.ZERO
		var cam_forward = -camera_pivot.transform.basis.z.normalized()
		cam_forward.y = 0
		var cam_axis = cam_forward.abs().max_axis()
		forward[cam_axis] = sign(cam_forward[cam_axis])
		
		if Input.is_action_just_pressed("move_up"):
			move_cursor(forward)
		elif Input.is_action_just_pressed("move_down"):
			move_cursor(-forward)
		elif Input.is_action_just_pressed("move_left"):
			move_cursor(-forward.cross(Vector3.UP))
		elif Input.is_action_just_pressed("move_right"):
			move_cursor(forward.cross(Vector3.UP))
		
		# Cursor rotation
		if Input.is_action_just_pressed("rotate"):
			cursor.rotate_cursor()
		
		# Block placement
		if Input.is_action_just_pressed("place_block"):
			if cursor.valid_block_placement():
				place_blocks_at(cursor.global_transform.origin, cursor.follower.global_transform.origin, player_color)
				
				# Move the cursor up above the new block (1 extra if placing vertically)
				cursor.global_transform.origin.y += 1
				if cursor.rotation_idx == 0:
					cursor.global_transform.origin.y += 1
				# Reduce empty spaces remaining by number of blocks placed
				toggle_player_ai()

# Returns the coordinates of where to place blocks for optimal move
func find_best_move(board_state: Array) -> Array:
	var successors = generate_successors(board_state)
	
	var best_successor = successors[0]
	for successor in successors:
		var successor_nimber
		# If we've already calculated this board's nimber, fetch it from the dict
		if successor in known_boards:
			successor_nimber = known_boards[successor]
		# Else, calculate the nimber and add it to the dict
		else:
			successor_nimber = get_nimber(successor)
			known_boards[successor] = successor_nimber
		# When a move to 0 is found, break and take that move
		if successor_nimber == 0:
			best_successor = successor
			break
	
	# Find the coordinates of the move made in that successor
	var best_move = []
	for row in range(height):
		for col1 in range(width):
			for col2 in range(length):
				# If a space is not empty in the successor and is empty in the main board, it's part of the move
				if best_successor[row][col1][col2] != 0 and board_array[row][col1][col2] == Block.EMPTY:
					best_move.append([row, col1, col2])
	return best_move

func toggle_player_ai() -> void:
	var label_string = ""
	if player_color == Block.BLUE:
		player_color = Block.RED
		label_string += "Red's turn"
	else:
		player_color = Block.BLUE
		label_string += "Blue's turn"
	ai_turn = not ai_turn
	cursor.visible = not ai_turn
	if ai_turn:
		label_string += " (AI)"
	else:
		label_string += " (Human)"
	gui.update_turn_label(label_string)
	
	cursor.update_color()
	
	# If there's not enough empty space to place more, the game is over
	if not is_moves_remaining():
		end_game()

func human_play() -> void:
	# Return to main menu
	if Input.is_action_just_pressed("ui_cancel"):
		return_to_main_menu()
	
	if not game_over:
		
		# Nimber calculation
		if gui.nimber_label.text == "Value: Calculating...":
			gui.update_nimber_label(get_nimber(get_impartial_board(board_array)))
			nimber_calculated = true
		if not nimber_calculated and Input.is_action_just_pressed("nimber"):
			gui.update_nimber_label(-2)
		
		# Cursor movement
		var forward = Vector3.ZERO
		var cam_forward = -camera_pivot.transform.basis.z.normalized()
		cam_forward.y = 0
		var cam_axis = cam_forward.abs().max_axis()
		forward[cam_axis] = sign(cam_forward[cam_axis])
		
		if Input.is_action_just_pressed("move_up"):
			move_cursor(forward)
		elif Input.is_action_just_pressed("move_down"):
			move_cursor(-forward)
		elif Input.is_action_just_pressed("move_left"):
			move_cursor(-forward.cross(Vector3.UP))
		elif Input.is_action_just_pressed("move_right"):
			move_cursor(forward.cross(Vector3.UP))
		
		# Cursor rotation
		if Input.is_action_just_pressed("rotate"):
			cursor.rotate_cursor()
		
		# Block placement
		if Input.is_action_just_pressed("place_block"):
			if cursor.valid_block_placement():
				place_blocks_at(cursor.global_transform.origin, cursor.follower.global_transform.origin, player_color)
				
				# Move the cursor up above the new block (1 extra if placing vertically)
				cursor.global_transform.origin.y += 1
				if cursor.rotation_idx == 0:
					cursor.global_transform.origin.y += 1
				
				# Set nimber calculation variables
				nimber_calculated = false
				nimber_label_updated = false
				gui.update_nimber_label(-1)
				
				toggle_player()

func _physics_process(delta: float) -> void:
	# Camera movement
	if Input.is_action_pressed("camera_up"):
		camera_pivot.rotation.x -= CAMERA_SPEED * delta
	if Input.is_action_pressed("camera_down"):
		camera_pivot.rotation.x += CAMERA_SPEED * delta
	if Input.is_action_pressed("camera_left"):
		camera_pivot.rotation.y -= CAMERA_SPEED * delta
	if Input.is_action_pressed("camera_right"):
		camera_pivot.rotation.y += CAMERA_SPEED * delta
	
	camera_pivot.rotation_degrees.x = clamp(camera_pivot.rotation_degrees.x, CAMERA_MIN_ROTATION, CAMERA_MAX_ROTATION)

# Return the nimber value of the given board state
func get_nimber(board_state: Array) -> int:
	var successors = generate_successors(board_state)
	
	# If there are no options from this state, it is in 0
	if len(successors) == 0:
		return 0
	
	var successor_nimbers = []
	for successor in successors:
		var successor_nimber = -1
		# If we've already calculated this board's nimber, fetch it from the dict
		if successor in known_boards:
			successor_nimber = known_boards[successor]
		# Else, calculate the nimber and add it to the dict
		else:
			successor_nimber = get_nimber(successor)
			known_boards[successor] = successor_nimber
		# Add it to the array if it's not already there
		if not successor_nimber in successor_nimbers:
			successor_nimbers.append(successor_nimber)
	
	return mex(successor_nimbers)

# Return all the possible board states that can result from the given board state
func generate_successors(board: Array) -> Array:
	var successors = []
	
	# Loop over board
	for row in range(len(board)):
		for col1 in range(len(board[row])):
			for col2 in range(len(board[row][col1])):
				# If a space is empty, check its neighbors
				if board[row][col1][col2] == 0:
					for neighbor in get_neighbors(row, col1, col2):
						# If a neighbor is also empty, check if its valid to place a block there
						if board[neighbor[0]][neighbor[1]][neighbor[2]] == 0:
							var main_supported = is_block_supported(board, row, col1, col2)
							var neighbor_supported = is_block_supported(board, neighbor[0], neighbor[1], neighbor[2])
							# If both blocks are supported, it's a valid move
							# If main block is supported and neighbor is above it, it's a valid move
							# If neighbor is supported and main block is above it, also a valid move
							if ((main_supported and neighbor_supported) or
							(main_supported and neighbor == [row + 1, col1, col2]) or
							(neighbor_supported and neighbor == [row - 1, col1, col2])):
								var successor = board.duplicate(true)
								successor[row][col1][col2] = 1
								successor[neighbor[0]][neighbor[1]][neighbor[2]] = 1
								# Only add this successor if it's not already there
								if not successor in successors:
									successors.append(successor)
	
	return successors

# Return an array of all boards that are equivalent to the given board
func get_equivalent_boards(board: Array) -> Array:
	var equivalent_boards = []
	equivalent_boards.append(board.duplicate(true))
	# Get mirrored boards
	var x_mirror = get_mirrored_board(board, "x")
	var z_mirror = get_mirrored_board(board, "z")
	equivalent_boards.append(x_mirror)
	equivalent_boards.append(z_mirror)
	
	# All 90 degree rotations
	for i in range(3):
		# Main board
		rotate_3d_array(board)
		equivalent_boards.append(board.duplicate(true))
		
		# X mirrored
		rotate_3d_array(x_mirror)
		equivalent_boards.append(x_mirror.duplicate(true))
		
		# Z mirrored
		rotate_3d_array(z_mirror)
		equivalent_boards.append(z_mirror.duplicate(true))
	
	return equivalent_boards

# In-place rotation of 3D array by 90 degrees
func rotate_3d_array(array: Array) -> void:
	for sub_array in array:
		rotate_2d_array(sub_array)

# In-place rotation of 2D array by 90 degrees
func rotate_2d_array(array: Array) -> void:
	transpose_2d_array(array)
	array.invert()

# In-place transposition of 2D array
func transpose_2d_array(array: Array) -> void:
	for i in range(len(array)):
		for j in range(i, len(array[i])):
			var t = array[i][j]
			array[i][j] = array[j][i]
			array[j][i] = t

# Get board mirrored over given axis
func get_mirrored_board(board: Array, axis: String) -> Array:
	var mirrored_board = board.duplicate(true)
	axis = axis.to_lower()
	if axis == "x":
		for row in range(height):
			for col1 in range(width):
				mirrored_board[row][col1] = mirrored_board[row][col1].invert()
	elif axis == "z":
		for row in range(height):
			mirrored_board[row] = mirrored_board[row].invert()
	else:
		print("Invalid axis, board was not mirrored")
	
	return mirrored_board

func is_block_supported(board: Array, row: int, col1: int, col2: int) -> bool:
	return row - 1 < 0 or board[row - 1][col1][col2] != 0

# Return the minimum excluded value in an array of integers
func mex(integers: Array) -> int:
	integers.sort()
	var num = 0
	for integer in integers:
		if integer < num:
			pass
		elif integer == num:
			num += 1
		else:
			return num
	return num

# Return an impartial version of the board (all values are 1 or 0, instead of Red, Blue, or Empty)
func get_impartial_board(board: Array) -> Array:
	var impartial_board = board.duplicate(true)
	
	for row in range(len(board)):
		for col1 in range(len(board[row])):
			for col2 in range(len(board[row][col1])):
				if board[row][col1][col2] == Block.EMPTY:
					impartial_board[row][col1][col2] = 0
				else:
					impartial_board[row][col1][col2] = 1
	
	return impartial_board

func return_to_main_menu() -> void:
	# Save known boards to file
	#print(len(known_boards))
	#var boards_file = File.new()
	#boards_file.open(BOARDS_FILE_PATH, File.WRITE)
	#boards_file.store_var(known_boards)
	#boards_file.close()
	
	gui.hide()
	main_menu.show()

func toggle_player() -> void:
	if player_color == Block.BLUE:
		player_color = Block.RED
		gui.update_turn_label("Red's turn")
	else:
		player_color = Block.BLUE
		gui.update_turn_label("Blue's turn")
	
	cursor.update_color()
	
	# If there's not enough empty space to place more, the game is over
	if not is_moves_remaining():
		end_game()

func is_moves_remaining() -> bool:
	if len(board_array) == 0 or len(board_array[0]) == 0 or len(board_array[0][0]) == 0:
		return false
	
	# If there are lots of empty spaces left, there must be moves
	if empty_spaces > len(board_array) * len(board_array[0]):
		return true
	
	# Check entire board for possible moves
	for row in range(height):
		for col1 in range(width):
			for col2 in range(length):
				# If the space is empty, check its neighbors
				if board_array[row][col1][col2] == Block.EMPTY:
					for neighbor in get_neighbors(row, col1, col2):
						if board_array[neighbor[0]][neighbor[1]][neighbor[2]] == Block.EMPTY:
							return true
	return false

func get_neighbors(row, col1, col2) -> Array:
	var neighbors = [
		[row + 1, col1, col2],
		[row - 1, col1, col2],
		[row, col1 + 1, col2],
		[row, col1 - 1, col2],
		[row, col1, col2 + 1],
		[row, col1, col2 - 1],
	]
	#board_array[y][x][z]
	#y: height, x: width, z: length
	var return_neighbors = []
	for neighbor in neighbors:
		if (neighbor[0] >= 0 and neighbor[0] < height
		and neighbor[1] >= 0 and neighbor[1] < width
		and neighbor[2] >= 0 and neighbor[2] < length):
			return_neighbors.append(neighbor)
	return return_neighbors

func end_game() -> void:
	var winner = "Blue"
	var loser = "Red"
	if player_color == Block.BLUE:
		var temp = winner
		winner = loser
		loser = temp
	
	if ai_play:
		if ai_turn:
			loser += " (AI)"
			winner += " (Human)"
		else:
			loser += " (Human)"
			winner += " (AI)"
	
	var end_text = "%s has no moves.\n%s wins!"
	gui.update_turn_label(end_text % [loser, winner])
	gui.hide_nimber_label()
	#gui.update_nimber_label(0)
	game_over = true
	cursor.game_over()

# Attempt to move cursor in given direction
func move_cursor(direction: Vector3) -> void:
	cursor.move_cursor(direction)

# Check if given position is a valid spot to place a block
func valid_block_placement(pos: Vector3) -> bool:
	return (in_board_bounds(pos) and check_block_at(pos) == Block.EMPTY and
		(pos.y - 1 < 0 or check_block_at(Vector3(pos.x, pos.y - 1, pos.z)) != Block.EMPTY
		or pos.y - 1 == cursor.global_transform.origin.y))
	
	# Position must be in board bounds
	if not in_board_bounds(pos):
		return false
	# Position must be empty
	if check_block_at(pos) != Block.EMPTY:
		return false
	# Position must either be on the bottom of the board or have a block beneath it
	if not (pos.y - 1 < 0 or check_block_at(Vector3(pos.x, pos.y - 1, pos.z)) != Block.EMPTY):
		return false
	
	return true

# Check if given position is within the horizontal bounds of the board
func in_board_perimeter(pos: Vector3) -> bool:
	return pos.x >= 0 and pos.x < width and pos.z >= 0 and pos.z < length

# Check if given position is within the board bounds
func in_board_bounds(pos: Vector3) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height and pos.z >= 0 and pos.z < length

func initialize_board(board_width: int, board_length: int, board_height: int) -> void:
	# If save file exists, read it
	#var boards_file = File.new()
	#if boards_file.file_exists(BOARDS_FILE_PATH):
		#boards_file.open(BOARDS_FILE_PATH, File.READ)
		#known_boards = boards_file.get_var()
		#boards_file.close()
	
	game_over = false
	nimber_calculated = false
	nimber_label_updated = false
	cursor.visible = true
	cursor.reset_pos()
	gui.update_nimber_label(-1)
	
	# Clear any existing blocks
	for child in blocks.get_children():
		child.queue_free()
	for child in board_bounds.get_children():
		child.queue_free()
	
	board_array = []
	width = board_width
	length = board_length
	height = board_height
	empty_spaces = width * length * height
	
	var x_offset = 0
	if width % 2 == 0:
		x_offset = 0.5
	
	var z_offset = 0
	if length % 2 == 0:
		z_offset = 0.5
		
	#board_bounds.global_transform.origin = Vector3(width / 2 - x_offset, 0, length / 2 - z_offset)
	#board_bounds.scale = Vector3(width + BOUNDS_OFFSET, height + BOUNDS_OFFSET, length + BOUNDS_OFFSET)
	
	# Place bottom layer board grid
	for i in range(width):
		for j in range(length):
			var board_block = CRAM_BLOCK.instance()
			board_bounds.add_child(board_block)
			board_block.global_transform.origin = Vector3(i, 0, j)
			board_block.rotate_x(deg2rad(180))
			board_block.cube_mesh.rotate_x(deg2rad(90))
			board_block.scale.y = CHECKBOARD_THICKNESS
			# Alternate colors for checkerboard pattern
			if (i % 2 == 0) != (j % 2 == 0):
				board_block.set_color("black")
			else:
				board_block.set_color("white")
	
	# Board cage pillars
	for i in range(height):
		# Each corner
		var corner_pillars = []
		for j in range(4):
			var board_block = CRAM_BLOCK.instance()
			board_bounds.add_child(board_block)
			#board_block.global_transform.origin = Vector3(1.1 * x,i, 1.1 * z)
			board_block.cube_mesh.rotate_x(deg2rad(-90))
			board_block.scale.x = 0.1
			board_block.scale.z = 0.1
			# Alternate colors going up
			if i % 2 == 0:
				board_block.set_color("black")
			else:
				board_block.set_color("white")
			corner_pillars.append(board_block)
		# Set positions for each corner
		corner_pillars[0].global_transform.origin = Vector3(0, i, 0)
		corner_pillars[1].global_transform.origin = Vector3(0, i, 0.1 + length)
		corner_pillars[2].global_transform.origin = Vector3(0.1 + width, i, 0)
		corner_pillars[3].global_transform.origin = Vector3(0.1 + width, i, 0.1 + length)
		var offset = 0.55
		for pillar in corner_pillars:
			pillar.global_transform.origin.x -= offset
			pillar.global_transform.origin.z -= offset
	
	# Board cage rim
	
	camera_pivot.rotation_degrees = Vector3(0, 0, 0)
	# Place camera pivot in center of board
	camera_pivot.global_transform.origin = Vector3(width / 2, height / 2, length / 2)
	#camera_pivot.global_transform.origin.y = height / 2
	
	# Offset camera
	camera.global_transform.origin = camera_pivot.global_transform.origin
	camera.global_transform.origin.z += max(max(width, length), height) + CAMERA_OFFSET
	
	for row in range(height):
		board_array.append([])
		for col1 in range(width):
			board_array[row].append([])
			for col2 in range(length):
				board_array[row][col1].append(Block.EMPTY)
	
	cursor.global_transform.origin = Vector3(0, 0, 0)
	cursor.rotate_cursor()
	while cursor.rotation_idx != 1:
		cursor.rotate_cursor()
	var valid_check = 3
	while (not cursor.valid_block_placement()) and valid_check > 0:
		cursor.rotate_cursor()
		valid_check -= 1
	
	if ai_play:
		toggle_player_ai()
		toggle_player_ai()
	else:
		toggle_player()
		toggle_player()
	
	# If there's not enough empty space to place more, the game is over
	if not is_moves_remaining():
		end_game()
	

func set_cursor_pos(x: int, y: int, z: int) -> void:
	cursor.global_transform.origin = Vector3(x, y, z)

# Return the lowest open space at given column
func lowest_open_space(x: int, z: int) -> int:
	for i in range(height):
		if board_array[i][x][z] == Block.EMPTY:
			return i
	return height

# Return the type of block at given space on the board
func check_block(x: int, y: int, z: int) -> int:
	if in_board_bounds(Vector3(x, y, z)):
		return board_array[y][x][z]
	return Block.EMPTY

func check_block_at(pos: Vector3) -> int:
	return check_block(pos.x, pos.y, pos.z)

func place_block(x: int, y: int, z: int, color: int) -> Block:
	empty_spaces -= 1
	board_array[y][x][z] = color
	return update_board_space([y, x, z], color)

func place_block_at(pos: Vector3, color: int) -> Block:
	return place_block(pos.x, pos.y, pos.z, color)

func place_blocks_at(pos1: Vector3, pos2: Vector3, color: int) -> void:
	var block1: MeshInstance = place_block_at(pos1, color).cube_mesh
	var block2: MeshInstance = place_block_at(pos2, color).cube_mesh
	block1.rotation = Vector3.ZERO
	block2.rotation = Vector3.ZERO
	block2.scale *= -1
	if pos1.y != pos2.y:
		block1.rotate_x(deg2rad(90))
		block2.rotate_x(deg2rad(90))
	else:
		block1.look_at(block2.global_transform.origin, Vector3.UP)
		block2.look_at(block1.global_transform.origin, Vector3.UP)
		block2.rotate_y(deg2rad(180))

func clear_board_view() -> void:
	for child in blocks.get_children():
		child.queue_free()

func update_board_space(space: Array, color: int) -> Block:
	var block_instance: Block = CRAM_BLOCK.instance()
	blocks.add_child(block_instance)
	if color == Block.BLUE:
		block_instance.set_color("blue")
		#block_instance = BLUE_BLOCK.instance()
	elif color == Block.RED:
		block_instance.set_color("red")
		#block_instance = RED_BLOCK.instance()
	block_instance.global_transform.origin = Vector3(space[1], space[0], space[2])
	return block_instance

func update_board_view() -> void:
	clear_board_view()
	for row in range(height):
		for col1 in range(width):
			for col2 in range(length):
				# If the space on the board is not empty, place a block instance
				var block_instance: Block = CRAM_BLOCK.instance()
				blocks.add_child(block_instance)
				if board_array[row][col1][col2] == Block.BLUE:
					block_instance.set_color("blue")
					#block_instance = BLUE_BLOCK.instance()
				elif board_array[row][col1][col2] == Block.RED:
					block_instance.set_color("red")
					#block_instance = RED_BLOCK.instance()
				block_instance.global_transform.origin = Vector3(col1, row, col2)
