extends Window


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal entity_created(entity)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ENTITIES : Dictionary = {
	&"Unique":{
		&"Player Start":{&"entity_type":&"Player"}
	},
	&"Door":{
		&"Basic":{&"entity_type":&"Basic_Interactable"}
	},
	&"Trigger":{
		&"AND Gate":{&"entity_type":&"Gate_AND"}
	},
}

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var entity_type_options : OptionButton = %EntityTypeOptions
@onready var entity_list : ItemList = %EntityList

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	close_requested.connect(_on_close_requested)
	entity_type_options.clear()
	for key in ENTITIES.keys():
		var idx : int = entity_type_options.item_count
		entity_type_options.add_item(key)
		entity_type_options.set_item_metadata(idx, StringName(key))
	if entity_type_options.selected >= 0:
		_on_entity_type_selected(entity_type_options.selected)
	entity_type_options.item_selected.connect(_on_entity_type_selected)
	entity_list.item_selected.connect(_on_entity_item_selected)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_close_requested() -> void:
	visible = false

func _on_entity_type_selected(idx : int) -> void:
	if not (idx >= 0 and idx < entity_type_options.item_count): return
	var key = entity_type_options.get_item_metadata(idx)
	if typeof(key) != TYPE_STRING_NAME: return
	
	entity_list.clear()
	for entity_name in ENTITIES[key].keys():
		var eidx : int = entity_list.item_count
		entity_list.add_item(entity_name)
		entity_list.set_item_metadata(eidx, {&"type":key, &"entity_name":StringName(entity_name)})

func _on_entity_item_selected(idx : int) -> void:
	if not (idx >= 0 and idx < entity_list.item_count): return
	var meta = entity_list.get_item_metadata(idx)
	if typeof(meta) != TYPE_DICTIONARY: return
	
	print("Selected ", meta[&"entity_name"], " (", meta[&"type"], ")")
	if not meta[&"type"] in ENTITIES: return
	if not meta[&"entity_name"] in ENTITIES[meta[&"type"]]: return
	
	# TODO: REALLY Fix up this bullshit!
	var entity : CrawlEntity = CrawlEntity.new()
	entity.uuid = UUID.v7()
	if meta[&"type"] == &"Unique":
		entity.type = ENTITIES[meta[&"type"]][meta[&"entity_name"]][&"entity_type"]
	else:
		entity.type = StringName("%s:%s"%[meta[&"type"], ENTITIES[meta[&"type"]][meta[&"entity_name"]][&"entity_type"]]) 

	entity_created.emit(entity)
	
	visible = false
	entity_list.deselect_all()


