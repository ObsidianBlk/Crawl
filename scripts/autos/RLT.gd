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

const ENTITIES_LOOKUP : Dictionary = {
	&"Unique":{
		&"Player":{&"name":&"Player Start"}
	},
	&"Door":{
		&"Basic_Interactable":{&"name":&"Basic Door"}
	},
	&"Trigger":{
		&"Light":{
			&"name":&"Triggerable Light",
			&"ui":"res://objects/entity_objects/trigger_light/DE_trigger_light_editor/DE_TriggerLightEditor.tscn"
		},
		&"Gate_AND":{
			&"name":&"AND Gate",
			&"ui":"res://objects/entity_objects/crawl_AND_gate_3d/DE_AND_gate_editor/DE_ANDGateEditor.tscn"
		},
		&"Gate_OR":{
			&"name":&"OR Gate",
			&"ui":"res://objects/entity_objects/crawl_OR_gate_3d/DE_OR_gate_editor/DE_ORGateEditor.tscn"
		},
		&"Gate_NOT":{
			&"name":&"NOT Gate",
			&"ui":"res://objects/entity_objects/crawl_NOT_gate_3d/DE_NOT_gate_editor/DE_NOTGateEditor.tscn"
		},
		&"Gate_NAND":{
			&"name":&"NAND Gate",
			&"ui":"res://objects/entity_objects/crawl_NAND_gate_3d/DE_NAND_gate_editor/DE_NANDGateEditor.tscn"
		},
		&"Gate_NOR":{
			&"name":&"NOR Gate",
			&"ui":"res://objects/entity_objects/crawl_NOR_gate_3d/DE_NOR_gate_editor/DE_NORGateEditor.tscn"
		},
		&"Gate_XOR":{
			&"name":&"XOR Gate",
			&"ui":"res://objects/entity_objects/crawl_XOR_gate_3d/DE_XOR_gate_editor/DE_XORGateEditor.tscn"
		},
		&"Logic_Memory":{
			&"name":&"Logical Memory",
			&"ui":"res://objects/entity_objects/crawl_memory_logic_3d/DE_memory_logic_editor/DE_MemoryLogicEditor.tscn"
		},
		&"Logic_Timer":{
			&"name":&"Logical Timer",
			&"ui":"res://objects/entity_objects/crawl_timer_logic_3d/DE_timer_logic_editor/DE_TimerLogicEditor.tscn"
		},
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
		},
		&"Trigger:Gate_AND":{
			&"src":"res://objects/entity_objects/crawl_AND_gate_3d/CrawlANDGate3D.tscn",
			&"description":"AND Gate"
		},
		&"Trigger:Gate_OR":{
			&"src":"res://objects/entity_objects/crawl_OR_gate_3d/CrawlORGate3D.tscn",
			&"description":"OR Gate"
		},
		&"Trigger:Gate_NOT":{
			&"src":"res://objects/entity_objects/crawl_NOT_gate_3d/CrawlNOTGate3D.tscn",
			&"description":"NOT Gate"
		},
		&"Trigger:Gate_NAND":{
			&"src":"res://objects/entity_objects/crawl_NAND_gate_3d/CrawlNANDGate3D.tscn",
			&"description":"NAND Gate"
		},
		&"Trigger:Gate_NOR":{
			&"src":"res://objects/entity_objects/crawl_NOR_gate_3d/CrawlNORGate3D.tscn",
			&"description":"NOR Gate"
		},
		&"Trigger:Gate_XOR":{
			&"src":"res://objects/entity_objects/crawl_XOR_gate_3d/CrawlXORGate3D.tscn",
			&"description":"XOR Gate"
		},
		&"Trigger:Logic_Memory":{
			&"src":"res://objects/entity_objects/crawl_memory_logic_3d/CrawlMemoryLogic3D.tscn",
			&"description":"Logical Memory"
		},
		&"Trigger:Logic_Timer":{
			&"src":"res://objects/entity_objects/crawl_timer_logic_3d/CrawlTimerLogic3D.tscn",
			&"description":"Logic Timer"
		},
		&"Trigger:Light":{
			&"src":"res://objects/entity_objects/trigger_light/TriggerLight.tscn",
			&"description":"Triggerable Light"
		},
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

func get_entity_groups() -> Array:
	return ENTITIES_LOOKUP.keys()

func get_entity_info_in_group(group : StringName) -> Array:
	if not group in ENTITIES_LOOKUP: return []
	var tlist : Array = []
	for key in ENTITIES_LOOKUP[group].keys():
		var type : StringName = &""
		type = key if group == &"Unique" else StringName("%s:%s"%[group, key])
		tlist.append({
			&"type": type,
			&"name": ENTITIES_LOOKUP[group][key]["name"],
			&"ui": &"" if not "ui" in ENTITIES_LOOKUP[group] else ENTITIES_LOOKUP[group]["ui"]
		})
	return tlist

func get_entity_ui_from_type(entity_type : StringName) -> String:
	if entity_type == &"": return &""
	var parts : PackedStringArray = entity_type.split(":")
	var psize : int = parts.size()
	if not (psize >= 1 and psize <= 2): return &""
	var base : StringName = parts[0]
	var sub : StringName = &""
	if parts.size() == 1:
		base = &"Unique"
		sub = parts[0]
	else:
		sub = parts[1]
	
	if not base in ENTITIES_LOOKUP: return &""
	if not sub in ENTITIES_LOOKUP[base]: return &""
	
	return &"" if not "ui" in ENTITIES_LOOKUP[base][sub] else ENTITIES_LOOKUP[base][sub]["ui"]


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

func instantiate_entity_ui(entity_type : StringName) -> Control:
	var ui_src : String = get_entity_ui_from_type(entity_type)
	if ui_src.is_empty(): return null
	var CTRL : PackedScene = load(ui_src)
	if CTRL == null: return null
	return CTRL.instantiate()


