class_name Block
extends Spatial

const BLUE_MATERIAL = preload("res://Models/BlueBlock.material")
const RED_MATERIAL = preload("res://Models/RedBlock.material")
const BLACK_MATERIAL = preload("res://Models/BlackBlock.material")
const WHITE_MATERIAL = preload("res://Models/WhiteBlock.material")

onready var cube_mesh = $"cram block/Cube"

func _ready() -> void:
	pass

# Set the color of this block
func set_color(color: String) -> void:
	match color.to_lower():
		"blue":
			cube_mesh.set_surface_material(0, BLUE_MATERIAL)
		"red":
			cube_mesh.set_surface_material(0, RED_MATERIAL)
		"black":
			cube_mesh.set_surface_material(0, BLACK_MATERIAL)
		"white":
			cube_mesh.set_surface_material(0, WHITE_MATERIAL)
		_:
			print("Block color was not set correctly!")
