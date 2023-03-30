extends Window


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal entity_created(entity)

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
	for key in RLT.get_entity_groups():
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
	for entity_info in RLT.get_entity_info_in_group(key):
		var eidx : int = entity_list.item_count
		entity_list.add_item(entity_info["name"])
		entity_list.set_item_metadata(eidx, entity_info)

func _on_entity_item_selected(idx : int) -> void:
	if not (idx >= 0 and idx < entity_list.item_count): return
	var meta = entity_list.get_item_metadata(idx)
	if typeof(meta) != TYPE_DICTIONARY: return
	
	# TODO: REALLY Fix up this bullshit!
	var entity : CrawlEntity = CrawlEntity.new()
	entity.uuid = UUID.v7()
	entity.type = meta[&"type"]
	
	entity_created.emit(entity)
	
	visible = false
	entity_list.deselect_all()


