class_name ItemStack
extends Reference


var name_with_affixes := []
var count := 1
var index_in_inventory := 1
var position_in_inventory := Vector2.ZERO
var inventory : Reference
var item_type : ItemType
var extra_properties : Dictionary


func _init(item, item_count = 1, item_extra_properties = null):
	item_type = item
	count = item_count
	extra_properties = (
		item_extra_properties
		if item_extra_properties != null && item_extra_properties.size() > 0 else
		item.default_properties.duplicate(true)
	)
	name_with_affixes = extra_properties.get("name", [null])


func get_bottom_right() -> Vector2:
	return Vector2(
		position_in_inventory.x + item_type.in_inventory_width,
		position_in_inventory.y + item_type.in_inventory_height
	)


func get_overflow_if_added(count_delta) -> int:
	return int(max(count + count_delta - item_type.max_stack_count, 0))


func get_delta_if_added(count_delta) -> int:
	return int(min(item_type.max_stack_count - count, count_delta))


func get_name() -> String:
	var trd := name_with_affixes.duplicate()
	for i in trd.size():
		if trd[i] != null:
			trd[i] = tr("item_affix_" + trd[i])

		else:
			trd[i] = tr("item_name_" + item_type.item_name)
	
	return " ".join(trd)


func _to_string():
	return (
		get_name()
		+ "\nCount: " + str(count)
		+ ", Data: \n" + str(extra_properties)
		+ "\n"
	)
