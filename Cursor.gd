extends Spatial

onready var board = get_parent() as Spatial
onready var follower = $Follower
onready var follower_mesh = $Follower/CursorMesh
onready var cursor_mesh = $MeshPivot/CursorMesh
onready var mesh_pivot = $MeshPivot

export var valid_color: Color = Color(0, 1, 0, 0.3)
export var invalid_color: Color = Color(1, 1, 0, 0.3)

var rotation_idx = 1
var max_rot_idx = 2
var default_pos #= global_transform.origin

func _ready() -> void:
	default_pos = global_transform.origin
	pass

func reset_pos() -> void:
	global_transform.origin = default_pos

# Change the color to represent valid block placements
func update_color() -> void:
	if valid_block_placement():
		cursor_mesh.get_surface_material(0).albedo_color = valid_color
	else:
		cursor_mesh.get_surface_material(0).albedo_color = invalid_color

# Attempt to move cursor in given direction
func move_cursor(direction: Vector3) -> void:
	var new_cursor_pos = global_transform.origin + direction.normalized()
	var new_follower_pos = follower.global_transform.origin + direction.normalized()
	
	if board.in_board_perimeter(new_cursor_pos):
		new_cursor_pos.y = board.lowest_open_space(new_cursor_pos.x, new_cursor_pos.z)
	if valid_cursor_pos_at(new_cursor_pos) and board.in_board_perimeter(new_follower_pos):
		global_transform.origin = new_cursor_pos
	update_color()

# Check if the cursor and follower are in valid block positions
func valid_block_placement() -> bool:
	return (board.valid_block_placement(global_transform.origin) and
		board.valid_block_placement(follower.global_transform.origin))

# Check if given pos is a valid place to move the cursor
func valid_cursor_pos(x: int, y: int, z: int) -> bool:
	return board.in_board_perimeter(Vector3(x, y, z)) and board.check_block(x, y, z) == board.Block.EMPTY

func valid_cursor_pos_at(pos: Vector3) -> bool:
	return valid_cursor_pos(pos.x, pos.y, pos.z)

func rotate_cursor() -> void:
	var follower_pos = global_transform.origin
	rotation_idx += 1
	if rotation_idx > max_rot_idx:
		rotation_idx = 0
	mesh_pivot.rotation = Vector3.ZERO
	
	match rotation_idx:
		# Vertical
		0:
			follower_pos.y += 1
			mesh_pivot.rotate_x(deg2rad(90))
		# X Horizontal
		1:
			follower_pos.x += 1
			if not board.in_board_perimeter(follower_pos):
				follower_pos.x -= 2
		# Z Horizontal
		2:
			follower_pos.z += 1
			if not board.in_board_perimeter(follower_pos):
				follower_pos.z -= 2
	follower.global_transform.origin = follower_pos
	if rotation_idx != 0:
		mesh_pivot.look_at(follower_mesh.global_transform.origin, Vector3.UP)
	update_color()

func game_over() -> void:
	visible = false
