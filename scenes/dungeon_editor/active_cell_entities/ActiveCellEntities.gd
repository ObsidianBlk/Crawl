extends Control


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal entity_selection_requested()

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ITEM : PackedScene = preload("res://scenes/dungeon_editor/active_cell_entities/ace_item/ACEItem.tscn")
const SELECTION_SURFACE : Array = [
	CrawlGlobals.SURFACE.North,
	CrawlGlobals.SURFACE.East,
	CrawlGlobals.SURFACE.South,
	CrawlGlobals.SURFACE.West,
]

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var map : CrawlMap = null:							set = set_map
@export var map_position : Vector3i = Vector3i.ZERO:		set = set_map_position
@export var follow_map_focus : bool = true:					set = set_follow_map_focus

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _selected : Array = []

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _entity_list_container : VBoxContainer = %EntityListContainer
@onready var _entity_settings : Window = $EntitySettings

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_map(m : CrawlMap) -> void:
	if m != map:
		_ClearEntityList()
		if map != null:
			if map.entity_added.is_connected(_on_entity_added):
				map.entity_added.disconnect(_on_entity_added)
			if map.entity_removed.is_connected(_on_entity_removed):
				map.entity_removed.disconnect(_on_entity_removed)
			if map.focus_position_changed.is_connected(_on_map_focus_position_changed):
				map.focus_position_changed.disconnect(_on_map_focus_position_changed)
		map = m
		if map != null:
			if not map.entity_added.is_connected(_on_entity_added):
				map.entity_added.connect(_on_entity_added)
			if not map.entity_removed.is_connected(_on_entity_removed):
				map.entity_removed.connect(_on_entity_removed)
			if follow_map_focus:
				if not map.focus_position_changed.is_connected(_on_map_focus_position_changed):
					map.focus_position_changed.connect(_on_map_focus_position_changed)
				map_position = map.get_focus_position()

func set_map_position(p : Vector3i) -> void:
	if p != map_position:
		map_position = p
		_ClearEntityList()
		_AssignEntitiesAt(map_position)

func set_follow_map_focus(f : bool) -> void:
	if f != follow_map_focus:
		follow_map_focus = f
		if map == null: return
		if follow_map_focus:
			if not map.focus_position_changed.is_connected(_on_map_focus_position_changed):
				map.focus_position_changed.connect(_on_map_focus_position_changed)
		else:
			if map.focus_position_changed.is_connected(_on_map_focus_position_changed):
				map.focus_position_changed.disconnect(_on_map_focus_position_changed)

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_entity_settings.close_requested.connect(_on_entity_settings_close_requested)
	_AssignEntitiesAt(map_position)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _GetACEItem(uuid : StringName) -> Control:
	if _entity_list_container == null: return null
	for child in _entity_list_container.get_children():
		if child.uuid == uuid:
			return child
	return null

func _RemoveACEItem(uuid : StringName) -> void:
	if _entity_list_container == null: return
	var item : Control = _GetACEItem(uuid)
	if item != null:
		_RemoveSelected(item.uuid)
		_entity_list_container.remove_child(item)
		item.queue_free()

func _UpdateACEItem(entity : CrawlEntity) -> void:
	if _entity_list_container == null: return
	var item : Control = _GetACEItem(entity.uuid)
	if item == null:
		item = ITEM.instantiate()
		if item == null: return # Perhaps I should annouce a crit failure
		_entity_list_container.add_child(item)
		item.selection_changed.connect(_on_item_selection_changed)
		item.uuid = entity.uuid
		item.type = entity.type
	item.entity_name = entity.entity_name
	item.facing = entity.facing

func _AddSelected(uuid : StringName) -> void:
	var idx : int = _selected.find(uuid)
	if idx < 0:
		_selected.append(uuid)

func _RemoveSelected(uuid : StringName) -> void:
	var idx : int = _selected.find(uuid)
	if idx >= 0:
		_selected.remove_at(idx)

func _ClearEntityList() -> void:
	if map == null or _entity_list_container == null: return
	for child in _entity_list_container.get_children():
		var entity : CrawlEntity = map.get_entity(child.uuid)
		if entity == null:
			_RemoveACEItem(child.uuid) # Somehow we have a dangling item.
			continue
		_on_entity_removed(entity)

func _AssignEntitiesAt(pos : Vector3i) -> void:
	if map == null or _entity_list_container == null: return
	var elist : Array = map.get_entities({&"position":pos})
	if elist.size() <= 0: return
	
	for entity in elist:
		if entity.type == &"Editor": continue # Ignore Editor type entity
		_on_entity_added(entity)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_map_focus_position_changed(focus_position : Vector3i) -> void:
	map_position = focus_position # This should call the map_position setter

func _on_entity_added(entity : CrawlEntity) -> void:
	if entity.get_map() != map: return
	if entity.type == &"Editor": return # We ignore this entity type!
	if entity.position != map_position: return
	
	if not entity.position_changed.is_connected(_on_entity_position_changed.bind(entity)):
		entity.position_changed.connect(_on_entity_position_changed.bind(entity))
	if not entity.facing_changed.is_connected(_on_entity_facing_changed.bind(entity)):
		entity.facing_changed.connect(_on_entity_facing_changed.bind(entity))
	if not entity.name_changed.is_connected(_on_entity_name_changed.bind(entity)):
		entity.name_changed.connect(_on_entity_name_changed.bind(entity))
	
	_UpdateACEItem(entity)

func _on_entity_removed(entity : CrawlEntity) -> void:
	if entity.position_changed.is_connected(_on_entity_position_changed.bind(entity)):
		entity.position_changed.disconnect(_on_entity_position_changed.bind(entity))
	if entity.facing_changed.is_connected(_on_entity_facing_changed.bind(entity)):
		entity.facing_changed.disconnect(_on_entity_facing_changed.bind(entity))
	if entity.name_changed.is_connected(_on_entity_name_changed.bind(entity)):
		entity.name_changed.disconnect(_on_entity_name_changed.bind(entity))
	
	_RemoveACEItem(entity.uuid)

func _on_entity_position_changed(from : Vector3i, to : Vector3i, entity : CrawlEntity) -> void:
	if to == map_position: return # Logically, this should NEVER happen
	_on_entity_removed(entity)

func _on_entity_facing_changed(from : CrawlGlobals.SURFACE, to : CrawlGlobals.SURFACE, entity : CrawlEntity) -> void:
	_UpdateACEItem(entity)

func _on_entity_name_changed(new_name : String, entity : CrawlEntity) -> void:
	print("The Name was CHANGED!!")
	_UpdateACEItem(entity)

func _on_item_selection_changed(uuid : StringName, selected : bool) -> void:
	if selected:
		_AddSelected(uuid)
	else:
		_RemoveSelected(uuid)

func _on_add_entity_pressed():
	entity_selection_requested.emit()


func _on_entity_facings_item_selected(idx : int) -> void:
	if map == null: return
	if not (idx >= 0 and idx < SELECTION_SURFACE.size()): return
	for uuid in _selected:
		var entity : CrawlEntity = map.get_entity(uuid)
		if entity == null : return
		entity.facing = SELECTION_SURFACE[idx]

func _on_remove_entities_pressed() -> void:
	if map == null: return
	for uuid in _selected:
		map.remove_entity_by_uuid(uuid)

func _on_settings_pressed():
	if map == null: return
	if _entity_settings.visible == true: return
	if _selected.size() != 1:
		return # TODO: Popup a dialog stating only a single entity can be selected.
	var entity : CrawlEntity = map.get_entity(_selected[0])
	_entity_settings.entity = entity
	
	var ctrl : Control = RLT.instantiate_entity_ui(entity.type)
	if ctrl != null:
		_entity_settings.attach_control(ctrl)
	
	_entity_settings.popup_centered()

func _on_entity_settings_close_requested() -> void:
	if not _entity_settings.visible: return
	_entity_settings.visible = false
