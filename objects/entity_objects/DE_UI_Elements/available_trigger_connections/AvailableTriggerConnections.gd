extends Control

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const META_KEY_CONNECTIONS : String = "connections"
const TRIGGER_TYPES : Array = [
	&"Trigger",
	&"Door",
]

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var entity : CrawlEntity = null:				set = set_entity
@export var max_connections : int = 0:					set = set_max_connections
@export var selected_color : Color = Color.CADET_BLUE:	set = set_selected_color

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _tree_sections : Dictionary = {}

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _tree : Tree = $Tree

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_entity(e : CrawlEntity) -> void:
	if e != entity:
		entity = e
		clear()
		if entity != null:
			_BuildTree()

func set_max_connections(mc : int) -> void:
	if mc < 0: return
	if mc != max_connections:
		max_connections = mc
		_UpdateSelectedItems()

func set_selected_color(c : Color) -> void:
	if c != selected_color:
		selected_color = c
		_UpdateSelectedItems()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_tree.item_selected.connect(_on_item_selected)
	_BuildTree()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _FindTreeItem(section : TreeItem, uuid : StringName) -> TreeItem:
	if section.get_child_count() <= 0: return null
	for child in section.get_children():
		if child.get_metadata(0) == uuid:
			return child
	return null

func _UpdateSectionItems(section : TreeItem) -> void:
	if entity == null: return
	var map : CrawlMap = entity.get_map()
	if map == null: return
	
	var section_type : StringName = section.get_metadata(0)
	var connections : Array = entity.get_meta_value(META_KEY_CONNECTIONS, [])
	
	var tlist : Array = map.get_entities({&"primary_type":section_type})
	for child in section.get_children():
		var uuid = child.get_metadata(0)
		if tlist.any(func(ent): ent.uuid == uuid):
			if connections.find(uuid) >= 0:
				child.set_custom_bg_color(0, selected_color)
		else:
			section.remove_child(child)
	
	for tentity in tlist:
		if tentity == entity: continue
		if _FindTreeItem(section, tentity.uuid) != null: continue
		var item : TreeItem = section.create_child()
		var iname : String = ""
		if tentity.entity_name.is_empty():
			iname = "[ %s ] (%d,%d,%d)"%[
				tentity.type,
				tentity.position.x, tentity.position.y, tentity.position.z
			]
		else:
			iname = "[ %s ] %s (%d,%d,%d)"%[
				tentity.type, tentity.entity_name,
				tentity.position.x, tentity.position.y, tentity.position.z
			]
		item.set_text(0, iname)
		item.set_metadata(0, tentity.uuid)
		item.set_selectable(0, true)
		if connections.find(tentity.uuid) >= 0:
			item.set_custom_bg_color(0, selected_color)

func _UpdateSelectedItems() -> void:
	if entity == null: return
	if _tree_sections.is_empty(): return
	
	var connections : Array = entity.get_meta_value(META_KEY_CONNECTIONS, [])
	if max_connections > 0 and connections.size() > max_connections:
		connections = connections.slice(0, max_connections)
		entity.set_meta_value(META_KEY_CONNECTIONS, connections)
	
	for section_name in _tree_sections.keys():
		var section : TreeItem = _tree_sections[section_name]
		for child in section.get_children():
			var uuid : StringName = child.get_metadata(0)
			if connections.find(uuid) >= 0:
				child.set_custom_bg_color(0, selected_color)
			else:
				child.clear_custom_bg_color(0)


func _BuildTree() -> void:
	if _tree == null: return
	var root : TreeItem = _tree.get_root()
	if root != null: return
	
	root = _tree.create_item()
	for type in TRIGGER_TYPES:
		var section : TreeItem = root.create_child()
		section.set_selectable(0, false)
		section.set_text(0, type)
		section.set_metadata(0, type)
		_tree_sections[type] = section
		_UpdateSectionItems(section)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func clear() -> void:
	_tree_sections.clear()
	_tree.clear()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_item_selected() -> void:
	if entity == null:
		_tree.deselect_all()
		return
	
	var item : TreeItem = _tree.get_selected()
	var uuid = item.get_metadata(0)
	var clist : Array = entity.get_meta_value(META_KEY_CONNECTIONS, [])
	
	var idx : int = clist.find(uuid)
	if idx >= 0:
		clist.remove_at(idx)
	elif max_connections == 0 or clist.size() < max_connections:
		clist.append(uuid)
	
	entity.set_meta_value(META_KEY_CONNECTIONS, clist)
	_UpdateSelectedItems()

