# (R)esource (L)ookup (T)able
extends Node


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const LOOKUP : Dictionary = {
	&"ground":{
		&"tileA":"res://objects/cell_resources/floors/Floor_TileA.tscn",
		&"tileB":"res://objects/cell_resources/floors/Floor_TileB.tscn",
	},
	&"ceiling":{
		&"tileA":"res://objects/cell_resources/ceilings/Ceiling_TileA.tscn",
		&"tileB":"res://objects/cell_resources/ceilings/Ceiling_TileB.tscn",
	},
	&"wall":{
		&"tileA":"res://objects/cell_resources/walls/Wall_TileA.tscn",
		&"tileB":"res://objects/cell_resources/walls/Wall_TileB.tscn"
	}
}

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_section_list() -> Array:
	return LOOKUP.keys()

func has_section(section : StringName) -> bool:
	return section in LOOKUP

func get_resource_list(section : StringName) -> Array:
	if not section in LOOKUP: return []
	return LOOKUP[section].keys()

func instantiate_resource(section : StringName, resource_name : StringName) -> Node3D:
	if not section in LOOKUP: return null
	if not resource_name in LOOKUP[section]: return null
	var scene : PackedScene = load(LOOKUP[section][resource_name])
	if scene == null: return null
	return scene.instantiate()

# --- DEPRECATED
func has_resource(resource : StringName) -> bool:
	return resource in LOOKUP

func load(resource : StringName) -> Material:
	if resource in LOOKUP:
		return ResourceLoader.load(LOOKUP[resource])
	return null

