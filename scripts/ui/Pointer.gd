class_name Pointer extends Node2D


enum AoEType {
	CIRCLE,
	SQUARE
}


signal tile_selected(position : Vector2, tile_data : TileData, y_sort_origin : int)


@onready var point_cast : RayCast2D = $point_cast
@onready var top_pointer : Area2D = $tile_top_pointer
@onready var top_collider : CollisionShape2D = $tile_top_pointer/Collider
@onready var polygon : Polygon2D = $Polygon


var tilemap : TileMap

var pressed := false

var selected_tile : TileData
var selected_pos : Vector2
var selected_layer : int


var debug_edit : SpinBox


func _ready() -> void:
	polygon.hide()
	tilemap = get_tree().get_first_node_in_group("tilemap")
	top_pointer.body_entered.connect(_on_touch_tile_top)
	top_collider.disabled = true
	var canvas := CanvasLayer.new()
	add_child(canvas)
	debug_edit = SpinBox.new()
	canvas.add_child(debug_edit)
	debug_edit.value = 3
	debug_edit.focus_mode = Control.FOCUS_NONE


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		get_tree().paused = true
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if Input.is_action_just_released(&"pointer_select"):
			for c in get_tree().get_nodes_in_group("marker"):
				c.free()
			top_pointer.global_position = get_global_mouse_position()
			if !point_cast.get_collider():
				print_debug("no collider")
				#if selected_tile:
					#selected_tile = null
				polygon.hide()
				#return
			top_collider.disabled = true
			top_collider.disabled = false
		elif Input.is_action_just_pressed(&"pointer_unselect"):
			#selected_tile = null
			polygon.hide()
			polygon.position = Vector2()
			for c in get_tree().get_nodes_in_group("marker"):
				c.free()
	elif event is InputEventKey:
		print_debug("event=%s, %s, %s ,%s" % [event, pressed, event.is_pressed(), Input.is_physical_key_pressed(KEY_Q)])
		if event.is_pressed() and !pressed:
			pressed = true
			if event.keycode == KEY_Q:
				tiles_along_path()
			elif event.keycode == KEY_Z:
				tile_aoe(AoEType.CIRCLE, debug_edit.value)
		elif !event.is_pressed() and pressed:
			pressed = false
		#if Input.is_action_just_pressed("ui_text_completion_replace"):


func tile_aoe(type : AoEType, radius : int):
	for c in get_tree().get_nodes_in_group("marker"):
		c.free()

	# TODO: placeholder origin pos
	var dict := select_tile(tilemap.get_local_mouse_position(), tilemap)
	if !dict: return
	var target_pos : Vector2 = dict["target_pos"]
	var target_cell : Vector2i = dict["target_cell"]
	var target_layer : int = dict["layer"]
	var target_y_sort_origin : int = dict["y_sort_origin"]
	var target_origin_pos = Vector2(target_pos.x, target_pos.y + target_y_sort_origin)
	var target_origin_cell : Vector2i = tilemap.local_to_map(target_origin_pos)
	var selected_cell : Vector2i = tilemap.local_to_map(selected_pos)
	
	# TODO: placeholders
	var tile : TileData
	var stacked_cell : Vector2i
	var y_sort_origin := 0
	var stacked_layer := 0
	
	var cell_set := get_area(target_origin_cell, radius)
	print_debug("set=%s" % [cell_set])
	
	for cell in cell_set:
		var p : PackedVector2Array = []
		var next_data := get_stacked_tile(cell, 0, 0)
		if next_data:
			tile = next_data["next_tile"]
			stacked_cell = next_data["next_cell"]
			#next_pos = tilemap.map_to_local(stacked_cell)
			stacked_layer = next_data["layer"]
			y_sort_origin = next_data["y_sort_origin"]
			p = next_data["polygon"]
			
		if !tile:
			print_rich("Tile%s on layer[%s] not found" % [stacked_cell, stacked_layer])
			#push_error("Tile on layer[%s] @ origin%s is null somehow..." % [stacked_layer, stacked_cell])
			continue # just ignore cells that don't have valid tiles
		
		# container is used to determine the y sort origin of the polygons; otherwise wont sort correctly
		var container := Node2D.new()
		container.add_to_group("marker")
		container.z_index = 0
		tilemap.add_child(container)
		var new_polygon = Polygon2D.new()
		container.add_child(new_polygon)
		new_polygon.y_sort_enabled = true
		new_polygon.polygon = p
		new_polygon.z_index = 0
		container.global_position = tilemap.map_to_local(cell)
		new_polygon.position = Vector2(0, -y_sort_origin)
		
	for poly in get_tree().get_nodes_in_group("marker"):
		if poly.is_queued_for_deletion(): continue
		poly.get_child(0).self_modulate = Color(0.686275, 0.933333, 0.933333, 0.5)


func get_area(origin : Vector2i, radius : int) -> Dictionary:
	var cell_set := {}
	print_debug("Radius=%s, %s" % [radius, origin])
	cell_set[origin] = true
	for r in radius + 1:
		if (r % 2) == 0:
			print("even=", r)
			for col in range(origin.x - (r / 2), origin.x + (r / 2) + 1):
				for row in range(origin.y - r, origin.y + r + 1, 2):
					if Vector2i(col, row) == origin: continue
					print("cr[%s, %s]" % [col, row])
					cell_set[Vector2i(col, row)] = true
		else:
			print("odd=%s, %s" % [r, origin.x - r])
			var even := (origin.y % 2) == 0
			for col in range(origin.x - (r / 2) - 1 if even else origin.x - (r / 2), 1 + (origin.x + (r / 2) if even else origin.x + (r / 2) + 1)):
				for row in range(origin.y - r, origin.y + r + 1, 2):
					print("odd cr[%s, %s]" % [col, row])
					cell_set[Vector2i(col, row)] = true
	return cell_set


func add_to_queue(origin : Vector2i, tilemap : TileMap, diagonal : bool) -> Array:
	var queue := []
	var neighbor := TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE if diagonal else TileSet.CELL_NEIGHBOR_RIGHT_CORNER
	for i in 4:
		var n := tilemap.get_neighbor_cell(origin, neighbor)
		queue.push_back(n)
		neighbor += 4 # get next corner to add
	return queue


func tiles_along_path() -> void:
	for c in get_tree().get_nodes_in_group("marker"):
		c.free()
		
	# TODO: placeholder origin pos
	var dict := select_tile(tilemap.get_local_mouse_position(), tilemap)
	
	if !dict.has("tile"): return
	var target_pos : Vector2 = dict["target_pos"]
	var target_cell : Vector2i = dict["target_cell"]
	var target_layer : int = dict["layer"]
	var target_y_sort_origin : int = dict["y_sort_origin"]
	var target_origin_pos = Vector2(target_pos.x, target_pos.y + target_y_sort_origin)
	var target_origin_cell : Vector2i = tilemap.local_to_map(target_origin_pos)
	var selected_cell : Vector2i = tilemap.local_to_map(selected_pos)
	#print_debug("target=%s, selected=%s | %s" % [target_cell, selected_cell, dict])
	
	# TODO: placeholders
	var range := 4
	var jump := 4
	
	var neighbor_direction := -1
	var current_layer := selected_layer # original layer that current cell is on
	var current_y_sort_origin := tilemap.get_layer_y_sort_origin(selected_layer)
	var current_origin_pos : Vector2 = Vector2(selected_pos.x, selected_pos.y + current_y_sort_origin)
	var current_origin_cell := tilemap.local_to_map(current_origin_pos)
	
	var next_cell := current_origin_cell
	var next_origin_cell := current_origin_cell
	var next_pos := current_origin_pos
	var next_y_sort_origin := current_y_sort_origin
	
	var current_tile : TileData = tilemap.get_cell_tile_data(current_layer, current_origin_cell)
	var i := 0
	while next_cell != target_cell:
		#print_rich("[rainbow]GGGG[/rainbow] [%s] target[%s, %s] next=[%s, %s] | %s" % [i, target_cell, target_origin_cell, next_cell, current_origin_cell, [next_y_sort_origin]])
		
		neighbor_direction = get_neighbor_direction(target_origin_cell, current_origin_cell)
		next_origin_cell = tilemap.get_neighbor_cell(current_origin_cell, neighbor_direction)
		current_origin_cell = next_origin_cell
		next_pos = tilemap.map_to_local(next_origin_cell)
		
		var p : PackedVector2Array = []
		var next_data := get_stacked_tile(next_origin_cell, 0, jump)
		if next_data:
			current_tile = next_data["next_tile"]
			next_cell = next_data["next_cell"]
			next_pos = tilemap.map_to_local(next_cell)
			current_layer = next_data["layer"]
			next_y_sort_origin = next_data["y_sort_origin"]
			p = next_data["polygon"]
		#print_debug("d=%s" % [next_data])
		
		if next_cell != target_cell:
			#print_debug("777 - %s-%s, %s" % [next_cell, current_origin_cell, target_origin_cell])
			# next cell is different from target cell, but have same origin: on same column in world
			if current_origin_cell == target_origin_cell:
				#print_debug("different cells, but same origin: on same column in world")
				next_cell = target_cell
				next_pos = target_pos
				current_tile = tilemap.get_cell_tile_data(target_layer, target_cell)
				next_y_sort_origin = target_y_sort_origin
				# adjust polygon point positions to account for layer y_sort_origin
				p = current_tile.get_collision_polygon_points(3, 0)
				var j = 0
				for point in p:
					p.set(j, Vector2(point.x, point.y))
					j += 1
				
		#print_debug("y_sort_check=%s | %s, [%s, %s] %s" % [[next_cell, current_origin_cell], [target_y_sort_origin, next_y_sort_origin], target_layer, current_layer, cell_neighbor_name(neighbor_direction)])
		
		# Tile is missing somehow on current path...
		# TODO: add some handling to move around void areas
		if !current_tile:
			print_rich("[color=#FF0000]Tile on layer[%s] @ origin%s is null somehow...[/color]" % [current_layer, next_cell])
			push_error("Tile on layer[%s] @ origin%s is null somehow..." % [current_layer, next_cell])
			return
		
		# container is used to determine the y sort origin of the polygons; otherwise wont sort correctly
		var container := Node2D.new()
		container.add_to_group("marker")
		container.z_index = 0
		tilemap.add_child(container)
		var new_polygon = Polygon2D.new()
		container.add_child(new_polygon)
		new_polygon.y_sort_enabled = true
		new_polygon.polygon = p
		new_polygon.z_index = 0
		container.global_position = tilemap.map_to_local(next_origin_cell)
		new_polygon.position = Vector2(0, -next_y_sort_origin)
		
		i += 1
	var markers := get_tree().get_nodes_in_group("marker")
	print_debug("distance=%s, range=%s, %s" % [i, range, markers.size()])
	if i > range:
		for poly in markers:
			if poly.is_queued_for_deletion(): continue
			poly.get_child(0).self_modulate = Color(1, 0, 0, 0.5)
		print_debug("out of range %s != %s" % [next_cell, target_cell])
	else:
		for poly in markers:
			if poly.is_queued_for_deletion(): continue
			poly.get_child(0).self_modulate = Color(0.686275, 0.933333, 0.933333, 0.5)


func get_stacked_tile(origin_cell : Vector2i, current_layer : int, height_limit : int) -> Dictionary:
	var out := {}
	var start_layer := 0
	var next_cell : Vector2i = origin_cell
	var next_tile : TileData
	
	var y_sort_origin := 0
	var nothing_under := false
	var i = 0 # the amount of 16px offset for the next layers
	for l in range(0, tilemap.get_layers_count()):
		next_cell = Vector2i(origin_cell.x, origin_cell.y - i)
		var tmp = tilemap.get_cell_tile_data(l, next_cell)
		#print_debug("i=%s, %s, %s, %s" % [i, l, tmp, next_cell])
		#print_debug("check above tiles: %s - %s = %s" % [point_pos, next_pos, tmp])
		i += 2
		if !tmp:
			if l == 0 and !nothing_under: nothing_under = true
			if nothing_under: continue
			#if (current_layer + height_limit) - l >= 0: continue # continue if still within heigh limits
			break # break if run out of tiles directly connected above; should not select tiles that are above but not connected
		nothing_under = false
		next_tile = tmp
		out["next_tile"] = next_tile
		out["next_cell"] = next_cell
		out["layer"] = l
		out["y_sort_origin"] = tilemap.get_layer_y_sort_origin(l) # get y_sort of the next tile above
	#print_debug("after TMP - %s, %s | %s" % [current_layer, next_cell, y_sort_origin])
	
	if !next_tile:
		return out # no valid tile found
	# get surface polygon shape from collision layer 3
	var p := next_tile.get_collision_polygon_points(3, 0)
	# adjust polygon point positions to account for layer y_sort_origin
	i = 0
	for point in p:
		p.set(i, Vector2(point.x, point.y - y_sort_origin))
		i += 1
	out["polygon"] = p
	return out


# Compare cell origins to see which direction should move in
func get_neighbor_direction(target_cell : Vector2i, selected_cell : Vector2i) -> int:
	var neighbor_direction = -1

	if target_cell.x != selected_cell.x and target_cell.y != selected_cell.y:
		neighbor_direction = TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE if target_cell.x > selected_cell.x and target_cell.y < selected_cell.y else TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE if target_cell.x > selected_cell.x and target_cell.y > selected_cell.y else TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE if target_cell.x < selected_cell.x and target_cell.y > selected_cell.y else TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE if target_cell.x < selected_cell.x and target_cell.y < selected_cell.y else -1
	
	elif target_cell.x != selected_cell.x and target_cell.y == selected_cell.y:
		#print_debug("horizontal")
		neighbor_direction = TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE if target_cell.x > selected_cell.x else TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE
	elif target_cell.x == selected_cell.x and target_cell.y != selected_cell.y:
		#print_debug("vertical")
		if target_cell.y < selected_cell.y:
			neighbor_direction = TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE if (selected_cell.y % 2) == 0 else TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE # go right if y value is even, left if odd
		else:
			neighbor_direction = TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE if (selected_cell.y % 2) == 0 else TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE # go right if y value is even, left if odd
		
	#print_debug("neighbor=%s" % [cell_neighbor_name(neighbor_direction)])
	
	return neighbor_direction


func cell_neighbor_name(neighbor : int) -> String:
	return "CELL_NEIGHBOR_TOP_RIGHT_SIDE" if neighbor == TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE else "CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE" if neighbor == TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE else "CELL_NEIGHBOR_BOTTOM_LEFT_SIDE" if neighbor == TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE else "CELL_NEIGHBOR_TOP_LEFT_SIDE" if neighbor == TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE else "<none>"


func select_tile(origin_pos : Vector2, tilemap : TileMap) -> Dictionary:
	print_debug("L - %s" % [[tilemap.get_cell_tile_data(0, Vector2()), tilemap.get_cell_tile_data(1, Vector2()), tilemap.get_cell_tile_data(2, Vector2()), tilemap.get_cell_tile_data(3, Vector2()), tilemap.get_cell_tile_data(4, Vector2())]])

	var tile_data : TileData
	var top_data : TileData
	var top_neighbor : TileData
	var bot_data : TileData
	# get positions of possible overlapping tiles
	var top_pos : Vector2i = tilemap.local_to_map(origin_pos)
	var top_cell_pos : Vector2 = tilemap.map_to_local(top_pos)
	var neighbor : Vector2i = tilemap.get_neighbor_cell(top_pos, TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE if  origin_pos.x - top_cell_pos.x < 0 else TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE) # get closest overlapping neighbor cell
	var neighbor_cell_pos : Vector2 = tilemap.map_to_local(neighbor)
	var base_pos : Vector2i = tilemap.local_to_map(Vector2(origin_pos.x, origin_pos.y + 16))
	var base_cell_pos : Vector2 = tilemap.map_to_local(base_pos)
	
	# go from highest layer to lowest as highest are "closest" from the player's perspective
	var y_sort_origin := 0
	var target_pos : Vector2
	var target_layer := 0
	for l in range(tilemap.get_layers_count() - 1, -1, -1):
		# check all 3 possible overlapping tiles: top cell, closest neighbor, below cell
		y_sort_origin = tilemap.get_layer_y_sort_origin(l)
		top_data = try_get_tile(l, origin_pos, top_pos, top_cell_pos, tilemap) 
		top_neighbor = try_get_tile(l, origin_pos, neighbor, neighbor_cell_pos, tilemap)
		bot_data = try_get_tile(l, origin_pos, base_pos, base_cell_pos, tilemap)
		
		# check tiles pointer is inside; set selected to 'closest' one (bot > neighbor > top)
		if bot_data:
			tile_data = bot_data
			target_pos = base_cell_pos
			target_layer = l
			print_debug("bot-%s,%s,%s" % [tile_data, target_pos, target_layer])
			break
		elif top_neighbor:
			tile_data = top_neighbor
			target_pos = neighbor_cell_pos
			target_layer = l
			print_debug("neighbor-%s,%s,%s" % [tile_data, target_pos, target_layer])
			break
		elif top_data:
			tile_data = top_data
			target_pos = top_cell_pos
			target_layer = l
			print_debug("top-%s,%s,%s" % [tile_data, target_pos, target_layer])
			break

	if tile_data:
		var target_tile = tile_data
		var base_cell = tilemap.local_to_map(target_pos) # cell of clicked on tile; don't change
		var next_pos := Vector2(target_pos.x, target_pos.y - 16)
		#print_debug("selected %s, %s | %s" % [base_cell, next_pos, tilemap.get_layers_count()])
		var tmp : TileData
		var i = 1 # the amount of 16px offset for the next layers
		for l in range(target_layer + 1, tilemap.get_layers_count()):
			next_pos = Vector2(target_pos.x, target_pos.y - (i * 16))
			# use next_pos since 'inside(...)' should always be true for tiles above the selected one
			tmp = try_get_tile(l, next_pos, Vector2i(base_cell.x, base_cell.y - (i * 2)), next_pos, tilemap)
			#print_debug("check above tiles: %s - %s = %s" % [point_pos, next_pos, tmp])
			if !tmp: break # break if run out of tiles directly connected above; should not select tiles that are above but not connected
			target_tile = tmp
			target_pos = next_pos
			target_layer = l
			y_sort_origin = tilemap.get_layer_y_sort_origin(l) # get y_sort of the next tile above
			i += 1

		# get surface polygon shape from collision layer 3
		var p := target_tile.get_collision_polygon_points(3, 0)
		# adjust polygon point positions to account for layer y_sort_origin
		i = 0
		for point in p:
			p.set(i, Vector2(point.x, point.y - y_sort_origin))
			i += 1
		
		return {
			"tile": target_tile,
			"target_pos": target_pos,
			"target_cell": tilemap.local_to_map(target_pos),
			"layer": target_layer,
			"y_sort_origin": y_sort_origin,
			"polygon": p
		}
	else:
		return {}


func try_get_stacked_tile(tile_data : TileData, target_pos : Vector2, target_layer : int, y_sort_origin : int) -> Dictionary:
	#if !tile_data: return {}
	var base_cell = tilemap.local_to_map(target_pos)
	var target_tile = tile_data
	var target_cell = tilemap.local_to_map(target_pos)
	var next_pos := Vector2(target_pos.x, target_pos.y)
	#var next_pos := Vector2(target_pos.x, target_pos.y - 16)
	#target_pos = Vector2(target_pos.x, target_pos.y + (target_layer * 16))
	#print_debug("stack - selected %s, %s | L[%s], %s" % [base_cell, next_pos, target_layer, y_sort_origin])
	var tmp : TileData
	var tmp_cell : Vector2i
	var i = -target_layer # the amount of 16px offset for the next layers
	#for l in range(target_layer, tilemap.get_layers_count()):
		#next_pos = Vector2(target_pos.x, target_pos.y - (i * 16))
		
	for l in range(0, tilemap.get_layers_count()):
		#print_debug("i=%s, %s" % [i, i * 16])
		tmp_cell = Vector2i(base_cell.x, base_cell.y - (i * 2))
		next_pos = tilemap.map_to_local(tmp_cell)
		#next_pos = Vector2(target_pos.x, target_pos.y - (i * 16))
		# use next_pos since 'inside(...)' should always be true for tiles above the selected one
		# FIXME: this is returning null somehow when trying to search during q highlight
		#print_debug("GET TMP - %s, %s, [%s, %s], %s, map_to_loc=%s" % [l, next_pos, base_cell, tmp_cell, next_pos, tilemap.map_to_local(tmp_cell)])
		tmp = try_get_tile(l, next_pos, tmp_cell, next_pos, tilemap)
		#print_debug("check above tiles: %s - %s = %s" % [point_pos, next_pos, tmp])
		if !tmp: break # break if run out of tiles directly connected above; should not select tiles that are above but not connected
		target_tile = tmp
		target_pos = next_pos
		target_cell = tmp_cell
		target_layer = l
		y_sort_origin = tilemap.get_layer_y_sort_origin(l) # get y_sort of the next tile above
		i += 1
	#print_debug("after TMP - %s, [%s, %s], %s" % [target_layer, target_cell, target_pos, y_sort_origin])
	# get surface polygon shape from collision layer 3
	var p := target_tile.get_collision_polygon_points(3, 0)
	# adjust polygon point positions to account for layer y_sort_origin
	i = 0
	for point in p:
		p.set(i, Vector2(point.x, point.y - y_sort_origin))
		i += 1
	
	return {
		"tile": target_tile,
		"target_pos": target_pos,
		"target_cell": target_cell,
		"layer": target_layer,
		"y_sort_origin": y_sort_origin,
		"polygon": p
	}


func try_get_tile(layer : int, point_pos : Vector2, cell_coords : Vector2i, cell_pos : Vector2, tilemap : TileMap) -> TileData:
	var tile : TileData = tilemap.get_cell_tile_data(layer, cell_coords)
	#print_debug("<%s>%s, %s" % [layer, cell_coords, tile])
	if tile:
		var polygon = tile.get_collision_polygon_points(2, 0)
		var i := 0
		# offset polygon points to use cell's local position
		for point in polygon:
			polygon.set(i, Vector2i(point.x + cell_pos.x, point.y + cell_pos.y))
			i += 1
		var inside := Geometry2D.is_point_in_polygon(point_pos, polygon) # check if point is in polygon
		#print_debug("==%s, %s==%s , %s" % [point_pos, offset, cell_coords, cell_pos])
		if inside:
			return tile
	return null


func _on_touch_tile_top(body : Node2D):
	if body is TileMap:
		var dict = select_tile(body.get_local_mouse_position(), body)
		if !dict: return
		selected_tile = dict["tile"]
		selected_pos = dict["target_pos"]
		selected_layer = dict["layer"]
		var y_sort_origin = dict["y_sort_origin"]
		var global_pos := tilemap.to_global(selected_pos)
		# prevent collider from triggering whenever pointer moves position
		polygon.hide()
		polygon.polygon = dict["polygon"]
		top_collider.set_deferred("disabled", true)
		global_position =  Vector2(global_pos.x, global_pos.y)
		polygon.global_position = Vector2(global_pos.x, global_pos.y + y_sort_origin)
		polygon.z_index = 0 # default z_index
		polygon.show()
		
		tile_selected.emit(global_pos, selected_tile, y_sort_origin)
