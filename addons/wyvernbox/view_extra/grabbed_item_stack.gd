extends ItemStackView

export var default_inventory := NodePath("")
export var drop_at_node := NodePath("")
export var drop_parent := NodePath("")
export var drop_scene : PackedScene = load("res://addons/wyvernbox/ground/ground_item_stack_view_2d.tscn")
export var drop_max_distance := 256.0
export var unit_size := Vector2(18, 18)

var grabbed_stack : ItemStack


func _ready():
	var new_node = Control.new()
	new_node.set_anchors_preset(PRESET_WIDE)
	new_node.connect("gui_input", self, "_drop_surface_input")
	new_node.name = "DropSurface"
	yield(get_tree(), "idle_frame")
	get_parent().add_child(new_node)
	for x in get_parent().get_children():
		if x != new_node:
			x.raise()


func grab(item_stack : ItemStack):
	if item_stack.inventory != null:
		var max_count = item_stack.item_type.max_stack_count
		if item_stack.count > max_count:
			item_stack.inventory.add_items_to_stack(item_stack, -max_count)
			item_stack = ItemStack.new(
				item_stack.item_type,
				max_count,
				item_stack.extra_properties.duplicate(true)
			)
			
		else:
			item_stack.inventory.remove_stack(item_stack)

	get_tree().get_nodes_in_group("tooltip")[0].hide()
	_set_grabbed_stack(item_stack)
	_move_to_mouse()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _set_grabbed_stack(item_stack : ItemStack):
	grabbed_stack = item_stack
	set_deferred("visible", item_stack != null)
	if item_stack == null:
		return

	visible = true
	rect_size = unit_size * item_stack.item_type.get_size_in_inventory()
	texture_rect.texture = item_stack.item_type.texture
	update_stack(item_stack, unit_size, false)


func drop():
	_any_inventory_try_drop_stack(grabbed_stack)
	update_stack(grabbed_stack, unit_size, false)


func drop_one():
	if grabbed_stack.count == 1:
		_any_inventory_try_drop_stack(grabbed_stack)
		update_stack(grabbed_stack, unit_size, false)
		return
	
	var one = grabbed_stack
	var all_but_one = ItemStack.new(
		grabbed_stack.item_type,
		grabbed_stack.count - 1,
		grabbed_stack.extra_properties.duplicate(true)
	)
	grabbed_stack.count = 1
	# Drop first. This function changes grabbed_stack to whatever's returned.
	_any_inventory_try_drop_stack(grabbed_stack)

	# If nothing was there, drop the 1 and keep holding the rest.
	if grabbed_stack == null:
		_set_grabbed_stack(all_but_one)
	
	# If the dropped 1 was returned (can't place), combine the stacks._add_random_item
	elif grabbed_stack == one:
		one.count += all_but_one.count

	# If there was something in place, just drop all instead of 1.
	else:
		var grabbed = grabbed_stack
		_any_inventory_try_drop_stack(all_but_one)
		_set_grabbed_stack(grabbed)
		
	update_stack(grabbed_stack, unit_size, false)


func _move_to_mouse():
	rect_global_position = get_global_mouse_position() - rect_size * 0.5 * rect_scale


func _any_inventory_try_drop_stack(stack):
	var found_stack : ItemStack
	for x in get_tree().get_nodes_in_group("inventory_view"):
		if !x.is_visible_in_tree():
			continue
		
		found_stack =	x.try_place_stackv(
			stack, x.global_position_to_cell(get_global_mouse_position(), stack)
		)
		if found_stack != stack:
			if found_stack == null:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			
			_set_grabbed_stack(found_stack)
			return


func drop_on_ground(stack):
	var new_node = drop_scene.instance()
	new_node.set_stack(stack)
	get_node(drop_parent).add_child(new_node)
	if new_node is Node2D:
		new_node.global_position = get_node(drop_at_node).global_position
		new_node.jump_to_pos(new_node.global_position + (
			get_global_mouse_position() - new_node.global_position
		).limit_length(drop_max_distance))

	else:
		new_node.global_translation = get_node(drop_at_node).global_translation

	new_node.connect("name_clicked", get_node(drop_at_node), "_on_ItemPickup_area_entered", [new_node])
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _input(event):
	if !visible: return
	if event is InputEventMouseMotion:
		_move_to_mouse()
		
	if event is InputEventMouseButton:
		if Input.is_action_pressed("inventory_more"): return
		if event.button_index == BUTTON_LEFT && event.pressed:
			drop()

		if event.button_index == BUTTON_RIGHT && event.pressed:
			drop_one()


func _drop_surface_input(event):
	if event is InputEventMouseButton && grabbed_stack != null && !event.pressed:
		if event.button_index == BUTTON_LEFT:
			drop_on_ground(grabbed_stack)
			_set_grabbed_stack(null)
			
		if event.button_index == BUTTON_RIGHT:
			drop_on_ground(ItemStack.new(
				grabbed_stack.item_type,
				1,
				grabbed_stack.extra_properties.duplicate(true)
			))
			grabbed_stack.count -= 1
			if grabbed_stack.count == 0:
				_set_grabbed_stack(null)

			else:
				_set_grabbed_stack(grabbed_stack)
