extends Control


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var entity : CrawlEntity = null:				set = set_entity



# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _lineedit_name : LineEdit = %LineEdit_Name
@onready var _lineedit_type : LineEdit = %LineEdit_Type


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_entity(e : CrawlEntity) -> void:
	if e != entity:
		entity = e
		_UpdateFieldValues()


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_UpdateFieldValues()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateFieldValues() -> void:
	if _lineedit_name == null or _lineedit_type == null: return
	if entity == null:
		_lineedit_name.text = ""
		_lineedit_type.editable = true
		_lineedit_type.text = ""
		_lineedit_type.editable = false
	else:
		_lineedit_name.text = entity.entity_name
		_lineedit_type.editable = true
		_lineedit_type.text = entity.type
		_lineedit_type.editable = false

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_line_edit_name_text_submitted(new_text : String) -> void:
	if entity == null: return
	entity.entity_name = new_text
