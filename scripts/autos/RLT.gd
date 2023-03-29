# (R)esource (L)ookup (T)able
extends Node


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ENV_LOOKUP : Dictionary = {
	&"default":{
		&"src":"res://objects/world_environments/default.tres",
		&"description":"Default dungeon world environment."
	},
}

const LOOKUP : Dictionary = {
	&"ground":{
		&"tileA":{
			&"src":"res://objects/cell_resources/floors/Floor_TileA.tscn",
			&"description":"Ground Tile A"
		},
		&"tileB":{
			&"src":"res://objects/cell_resources/floors/Floor_TileB.tscn",
			&"description":"Ground Tile B"
		},
		&"basic":{
			&"src":"res://objects/cell_resources/floors/Floor_Basic.tscn",
			&"description":"Basic ground floor"
		},
	},
	&"ceiling":{
		&"tileA":{
			&"src":"res://objects/cell_resources/ceilings/Ceiling_TileA.tscn",
			&"description":"Ceiling Tile A"
		},
		&"tileB":{
			&"src":"res://objects/cell_resources/ceilings/Ceiling_TileB.tscn",
			&"description":"Ceiling Tile B"
		},
		&"basic":{
			&"src":"res://objects/cell_resources/ceilings/Ceiling_Basic.tscn",
			&"description":"Basic ceiling"
		},
	},
	&"wall":{
		&"tileA":{
			&"src":"res://objects/cell_resources/walls/Wall_TileA.tscn",
			&"description":"Wall Tile A"
		},
		&"tileB":{
			&"src":"res://objects/cell_resources/walls/Wall_TileB.tscn",
			&"description":"Wall Tile B"
		},
		&"basic":{
			&"src":"res://objects/cell_resources/walls/Wall_Basic.tscn",
			&"description":"Basic wall"
		},
	},
	&"stair":{
		
	},

	
	&"entity":{
		&"Editor":{
			&"src":"res://objects/viewer/Viewer.tscn",
			&"description":"Editor entity"
		},
		&"Player":{
			&"src":"res://objects/player/Player.tscn",
			&"description":"Player start"
		},
		&"Door:Basic_Interactable":{
			&"src":"res://objects/entity_objects/door_basic_interactable/DoorBasicInteractable.tscn",
			&"description":"Basic Interactable Door"
		}
	}
}

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_section_list() -> Array:
	return LOOKUP.keys()

func has_section(section : StringName) -> bool:
	return section in LOOKUP

func has_resource(section : StringName, resource_name : StringName) -> bool:
	if not section in LOOKUP: return false
	if not resource_name in LOOKUP[section]: return false
	return true

func get_resource_list(section : StringName) -> Array:
	if not section in LOOKUP: return []
	var list : Array = []
	for key in LOOKUP[section].keys():
		var item : Dictionary = {&"name":key, &"description":key}
		if &"description" in LOOKUP[section][key]:
			item[&"description"] = LOOKUP[section][key][&"description"]
		list.append(item)
	return list

func has_environment(environment_name : StringName) -> bool:
	return environment_name in ENV_LOOKUP

func get_environment_list() -> Array:
	var list : Array = []
	for key in ENV_LOOKUP.keys():
		var item : Dictionary = {&"name":key, &"description":key}
		if &"description" in ENV_LOOKUP[key]:
			item[&"description"] = ENV_LOOKUP[key][&"description"]
		list.append(item)
	return list

func instantiate_resource(section : StringName, resource_name : StringName) -> Node3D:
	if not section in LOOKUP: return null
	if not resource_name in LOOKUP[section]: return null
	var scene : PackedScene = load(LOOKUP[section][resource_name][&"src"])
	if scene == null: return null
	return scene.instantiate()

func instantiate_environment(environment_name : StringName) -> Environment:
	if not environment_name in ENV_LOOKUP: return null
	var env = ResourceLoader.load(ENV_LOOKUP[environment_name][&"src"])
	if not is_instance_of(env, Environment): return null
	return env
