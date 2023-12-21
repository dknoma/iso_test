class_name Pointer extends Node2D


signal tile_selected(position : Vector2, tile_data : TileData, y_sort_origin : int)


@onready var point_cast : RayCast2D = $point_cast
@onready var top_pointer : Area2D = $tile_top_pointer
@onready var top_collider : CollisionShape2D = $tile_top_pointer/Collider
@onready var polygon : Polygon2D = $Polygon

var tilemap : TileMap
var markers : Node

var selected_tile : TileData
var selected_pos : Vector2
var selected_layer : int
#var selected_y_sort : int

func _ready() -> void:
	polygon.hide()
	tilemap = get_tree().get_first_node_in_group("tilemap")
	markers = get_tree().get_first_node_in_group("markers")
	top_pointer.body_entered.connect(_on_touch_tile_top)
	top_collider.disabled = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		get_tree().paused = true
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		get_tree().paused = false

var pressed := false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if Input.is_action_just_released(&"pointer_select"):
			#mouse_pos = get_global_mouse_position()
			top_pointer.global_position = get_global_mouse_position()
			if !point_cast.get_collider():
				print("no collider")
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
			var markers : Node = get_tree().get_first_node_in_group("markers")
			for c in markers.get_children():
				c.queue_free()
	elif event is InputEventKey:
		print("event=%s, %s, %s ,%s" % [event, pressed, event.is_pressed(), Input.is_physical_key_pressed(KEY_Q)])
		if event.keycode == KEY_Q and event.is_pressed() and !pressed:
			pressed = true
			
			for c in markers.get_children():
				c.queue_free()
				
			var dict := select_tile(tilemap)
			
			#var mouse_pos = get_global_mouse_position()
			#var target_cell = tilemap.local_to_map(Vector2(mouse_pos.x, mouse_pos.y + 16))
			#var target_cell = tilemap.local_to_map(Vector2(target_pos.x, target_pos.y + 16))
			
			#print("next=%s, %s" % [next_cell, cell_neighbor_name(neighbor_direction)])
			#neighbor_direction = get_neighbor_direction(target_pos, next)
			#var cell_cache : Array[Vector2i] = [selected_cell]
			#if neighbor_direction == -1: return
			if !dict.has("tile"): return
			var target_pos = dict["target_pos"]
			var target_cell = dict["target_cell"]
			var target_layer = dict["layer"]
			var target_y_sort_origin = dict["y_sort_origin"]
			var target_origin_pos = Vector2(target_pos.x, target_pos.y + target_y_sort_origin)
			var target_origin_cell = tilemap.local_to_map(target_origin_pos)
			var selected_cell = tilemap.local_to_map(selected_pos)
			print("target=%s, selected=%s | %s" % [target_cell, selected_cell, dict])
			
			var range := 4
			var neighbor_direction := -1
			var current_cell : Vector2i = selected_cell
			var current_pos : Vector2 = selected_pos
			var i := 0
			var current_layer = selected_layer # original layer that current cell is on
			var y_sort_origin := tilemap.get_layer_y_sort_origin(selected_layer)
			var current_origin_pos : Vector2 = Vector2(current_pos.x, current_pos.y + y_sort_origin)
			var current_origin_cell = tilemap.local_to_map(current_origin_pos)
			
			var current_tile : TileData = tilemap.get_cell_tile_data(current_layer, current_cell)
			while current_origin_pos != target_origin_pos:
			#while current_cell != target_cell:
				print_rich("[rainbow]GGGG[/rainbow] [%s] target=%s next=%s | %s" % [i, target_cell, current_cell, [target_origin_cell, current_origin_cell]])
				neighbor_direction = get_neighbor_direction(target_pos, current_pos)
				current_cell = tilemap.get_neighbor_cell(current_cell, neighbor_direction)
				#current_pos = tilemap.map_to_local(next_cell)
				current_pos = tilemap.map_to_local(current_cell)
				current_origin_pos = Vector2(current_pos.x, current_pos.y + y_sort_origin)
				print("y_sort_check=%s | %s, [%s, %s] %s" % [[target_origin_pos, current_origin_pos], (target_y_sort_origin - y_sort_origin), target_layer, current_layer, current_cell])
				
				#if current_origin_pos == target_origin_pos and current_cell != target_cell:
					#print("same origin")
					#current_cell = Vector2i(current_cell.x, current_cell.y - ((target_layer - current_layer) * 2))
					#current_pos = Vector2(current_pos.x, current_pos.y - target_y_sort_origin)
					#current_layer = target_layer
					#y_sort_origin = target_y_sort_origin
					
				# TODO: if curr.x == target.x, but curr.y != target,y, then must be on a different layer but same position
				# TODO: need to adjust layer here so that can account for neighbor tiles on a different layer
				#current_tile = tilemap.get_cell_tile_data(current_layer if current_cell != target_cell else target_layer, current_cell)
				current_tile = tilemap.get_cell_tile_data(current_layer, current_cell)
				print("tt %s[%s] %s, %s" % [current_tile, current_layer, current_cell, cell_neighbor_name(neighbor_direction)])
				
				# try update values to stacked tile
				
				# if next == target dont try to get stacked
				var p : PackedVector2Array
				if current_origin_pos != target_origin_pos:
					var next_data := try_get_stacked_tile(current_tile, current_pos, current_layer, y_sort_origin)
					#var next_dict := try_get_stacked_tile(tile, current_pos, layer, y_sort_origin)
					if next_data:
						current_tile = next_data["tile"]
						current_cell = next_data["target_cell"]
						current_pos = next_data["target_pos"]
						current_layer = next_data["layer"]
						y_sort_origin = next_data["y_sort_origin"]
						p = next_data["polygon"]
						print("aa", next_data)
				#var tmp : TileData
				#var top_offset = 1 # offset of the tile in the above layer
				#for l in range(layer + 1, tilemap.get_layers_count()):
					#next_pos = Vector2(next_pos.x, next_pos.y - (top_offset * 16))
					## use next_pos since 'inside(...)' should always be true for tiles above the selected one
					#tmp = try_get_tile(l, next_pos, Vector2i(next_cell.x, next_cell.y - (top_offset * 2)), next_pos, tilemap)
					#print_debug("check above tiles: %s = %s" % [next_pos, tmp])
					#if !tmp: break # break if run out of tiles directly connected above; should not select tiles that are above but not connected
					#tile = tmp
					##selected_pos = next_pos
					#layer = l
					#y_sort_origin = tilemap.get_layer_y_sort_origin(l) # get y_sort of the next tile above
					#top_offset += 1
				#if next_dict.has("polygon"):
					#p = next_dict["polygon"]
				else:
					
					if current_origin_pos == target_origin_pos and current_cell != target_cell:
						print("same origin")
						current_cell = Vector2i(current_cell.x, current_cell.y - ((target_layer - current_layer) * 2))
						current_pos = Vector2(current_pos.x, current_pos.y - (target_y_sort_origin - y_sort_origin))
						current_layer = target_layer
						y_sort_origin = target_y_sort_origin
						current_tile = tilemap.get_cell_tile_data(current_layer, current_cell)
						
					p = current_tile.get_collision_polygon_points(3, 0)
					# adjust polygon point positions to account for layer y_sort_origin
					var j = 0
					for point in p:
						p.set(j, Vector2(point.x, point.y - y_sort_origin))
						j += 1
					
				
				var new_polygon = Polygon2D.new()
				markers.add_child(new_polygon)
				new_polygon.y_sort_enabled = true
				new_polygon.polygon = p
				new_polygon.z_index = 0
				new_polygon.global_position = Vector2(current_pos.x, current_pos.y + y_sort_origin)
				
				print("i=%s, %s" % [i, current_cell])
				i += 1
				#if current_cell == target_cell: 
					#print("found")
					#break
			#print("ugh=%s, %s" % [target_cell, next_cell])
			#for cell in cell_cache:
				#tile = tilemap.get_cell_tile_data(selected_layer, cell)
				#var pos = tilemap.map_to_local(cell)
				
				
				#var tmp : TileData
				#var top_offset = 1 # offset of the tile in the above layer
				#for l in range(selected_layer + 1, tilemap.get_layers_count()):
					#next_pos = Vector2(next_pos.x, next_pos.y - (top_offset * 16))
					## use next_pos since 'inside(...)' should always be true for tiles above the selected one
					#tmp = try_get_tile(l, next_pos, Vector2i(cell.x, cell.y - (top_offset * 2)), next_pos, tilemap)
					#print_debug("check above tiles: %s = %s" % [next_pos, tmp])
					#if !tmp: break # break if run out of tiles directly connected above; should not select tiles that are above but not connected
					#tile = tmp
					##selected_pos = next_pos
					##selected_layer = l
					#y_sort_origin = tilemap.get_layer_y_sort_origin(l) # get y_sort of the next tile above
					#top_offset += 1
				
				#var p := tile.get_collision_polygon_points(3, 0)
				## adjust polygon point positions to account for layer y_sort_origin
				#var j = 0
				#for point in p:
					#p.set(j, Vector2(point.x, point.y - y_sort_origin))
					#j += 1
				#var new_polygon = Polygon2D.new()
				#markers.add_child(new_polygon)
				#new_polygon.y_sort_enabled = true
				#new_polygon.set_polygon(p)
				#new_polygon.z_index = 0
				#new_polygon.global_position = Vector2(pos.x, pos.y + y_sort_origin)
						#polygon.hide()
						#polygon.polygon = p
						#polygon.global_position = Vector2(pos.x, pos.y + y_sort_origin)
						#polygon.z_index = 0 # default z_index
						#polygon.show()
			if i > range:
				for poly in markers.get_children():
					poly.self_modulate = Color(1, 0, 0, 0.5)
				print("out of range %s != %s" % [current_cell, target_cell])
			else:
				for poly in markers.get_children():
					poly.self_modulate = Color(0.686275, 0.933333, 0.933333, 0.5)
				
		elif event.keycode == KEY_Q and !event.is_pressed() and pressed:
			pressed = false
		#if Input.is_action_just_pressed("ui_text_completion_replace"):
		

# TODO: check if neighbor has tiles above, try to prioritize not going on top of those tiles (BL instead of TL if TL has tile above, etc)
func get_neighbor_direction(target_pos : Vector2, selected_pos : Vector2) -> int:
	var neighbor_direction = -1
	
	print("t=%s, s=%s" % [target_pos, selected_pos])
	
	if target_pos.x != selected_pos.x and target_pos.y != selected_pos.y:
		neighbor_direction = TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE if target_pos.x > selected_pos.x and target_pos.y < selected_pos.y else TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE if target_pos.x > selected_pos.x and target_pos.y > selected_pos.y else TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE if target_pos.x < selected_pos.x and target_pos.y > selected_pos.y else TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE if target_pos.x < selected_pos.x and target_pos.y < selected_pos.y else -1
	
	elif target_pos.x != selected_pos.x and target_pos.y == selected_pos.y:
		print("horizontal")
		neighbor_direction = TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE if target_pos.x > selected_pos.x else TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE
	elif target_pos.x == selected_pos.x and target_pos.y != selected_pos.y:
		print("vertical")
		neighbor_direction = TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE if target_pos.y < selected_pos.y else TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE
		
	print_debug("neighbor=%s" % [cell_neighbor_name(neighbor_direction)])
	
	return neighbor_direction


func cell_neighbor_name(neighbor : int) -> String:
	return "CELL_NEIGHBOR_TOP_RIGHT_SIDE" if neighbor == TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE else "CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE" if neighbor == TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE else "CELL_NEIGHBOR_BOTTOM_LEFT_SIDE" if neighbor == TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE else "CELL_NEIGHBOR_TOP_LEFT_SIDE" if neighbor == TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE else "<none>"


func select_tile(tilemap : TileMap) -> Dictionary:
	print("L - %s" % [[tilemap.get_cell_tile_data(0, Vector2()), tilemap.get_cell_tile_data(1, Vector2()), tilemap.get_cell_tile_data(2, Vector2()), tilemap.get_cell_tile_data(3, Vector2()), tilemap.get_cell_tile_data(4, Vector2())]])
	var point_pos := tilemap.get_local_mouse_position()

	#var layer := -1
	var tile_data : TileData
	var top_data : TileData
	var top_neighbor : TileData
	var bot_data : TileData
	# get positions of possible overlapping tiles
	var top_pos : Vector2i = tilemap.local_to_map(point_pos)
	var top_cell_pos : Vector2 = tilemap.map_to_local(top_pos)
	var neighbor : Vector2i = tilemap.get_neighbor_cell(top_pos, TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE if  point_pos.x - top_cell_pos.x < 0 else TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE) # get closest overlapping neighbor cell
	var neighbor_cell_pos : Vector2 = tilemap.map_to_local(neighbor)
	var base_pos : Vector2i = tilemap.local_to_map(Vector2(point_pos.x, point_pos.y + 16))
	var base_cell_pos : Vector2 = tilemap.map_to_local(base_pos)
	
	# go from highest layer to lowest as highest are "closest" from the player's perspective
	var y_sort_origin := 0
	var target_pos : Vector2
	var target_layer := 0
	for l in range(tilemap.get_layers_count() - 1, -1, -1):
		# check all 3 possible overlapping tiles: top cell, closest neighbor, below cell
		y_sort_origin = tilemap.get_layer_y_sort_origin(l)
		top_data = try_get_tile(l, point_pos, top_pos, top_cell_pos, tilemap) 
		top_neighbor = try_get_tile(l, point_pos, neighbor, neighbor_cell_pos, tilemap)
		bot_data = try_get_tile(l, point_pos, base_pos, base_cell_pos, tilemap)
		
		# check tiles pointer is inside; set selected to 'closest' one (bot > neighbor > top)
		if bot_data:
			tile_data = bot_data
			target_pos = base_cell_pos
			target_layer = l
			print("bot-%s,%s,%s" % [tile_data, target_pos, target_layer])
			break
		elif top_neighbor:
			tile_data = top_neighbor
			target_pos = neighbor_cell_pos
			target_layer = l
			print("neighbor-%s,%s,%s" % [tile_data, target_pos, target_layer])
			break
		elif top_data:
			tile_data = top_data
			target_pos = top_cell_pos
			target_layer = l
			print("top-%s,%s,%s" % [tile_data, target_pos, target_layer])
			break

	if tile_data:
		var target_tile = tile_data
		var base_cell = tilemap.local_to_map(target_pos) # cell of clicked on tile; don't change
		var next_pos := Vector2(target_pos.x, target_pos.y - 16)
		print_debug("selected %s, %s | %s" % [base_cell, next_pos, tilemap.get_layers_count()])
		var tmp : TileData
		var i = 1 # the amount of 16px offset for the next layers
		for l in range(target_layer + 1, tilemap.get_layers_count()):
			next_pos = Vector2(target_pos.x, target_pos.y - (i * 16))
			# use next_pos since 'inside(...)' should always be true for tiles above the selected one
			tmp = try_get_tile(l, next_pos, Vector2i(base_cell.x, base_cell.y - (i * 2)), next_pos, tilemap)
			print_debug("check above tiles: %s - %s = %s" % [point_pos, next_pos, tmp])
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
		return {
			#"tile": null,
			#"target_pos": Vector2(),
			#"target_cell": Vector2(),
			#"layer": 0,
			#"y_sort_origin": 0,
			#"polygon": [],
		}


func try_get_stacked_tile(tile_data : TileData, target_pos : Vector2, target_layer : int, y_sort_origin : int) -> Dictionary:
	#if !tile_data: return {}
	var base_cell = tilemap.local_to_map(target_pos)
	var target_tile = tile_data
	var target_cell = tilemap.local_to_map(target_pos)
	var next_pos := Vector2(target_pos.x, target_pos.y)
	#var next_pos := Vector2(target_pos.x, target_pos.y - 16)
	#target_pos = Vector2(target_pos.x, target_pos.y + (target_layer * 16))
	print_debug("stack - selected %s, %s | L[%s], %s" % [base_cell, next_pos, target_layer, y_sort_origin])
	var tmp : TileData
	var tmp_cell : Vector2i
	var i = -target_layer # the amount of 16px offset for the next layers
	#for l in range(target_layer, tilemap.get_layers_count()):
		#next_pos = Vector2(target_pos.x, target_pos.y - (i * 16))
		
	for l in range(0, tilemap.get_layers_count()):
		print("i=%s, %s" % [i, i * 16])
		tmp_cell = Vector2i(base_cell.x, base_cell.y - (i * 2))
		next_pos = tilemap.map_to_local(tmp_cell)
		#next_pos = Vector2(target_pos.x, target_pos.y - (i * 16))
		# use next_pos since 'inside(...)' should always be true for tiles above the selected one
		# FIXME: this is returning null somehow when trying to search during q highlight
		print("GET TMP - %s, %s, [%s, %s], %s, map_to_loc=%s" % [l, next_pos, base_cell, tmp_cell, next_pos, tilemap.map_to_local(tmp_cell)])
		tmp = try_get_tile(l, next_pos, tmp_cell, next_pos, tilemap)
		#print_debug("check above tiles: %s - %s = %s" % [point_pos, next_pos, tmp])
		if !tmp: break # break if run out of tiles directly connected above; should not select tiles that are above but not connected
		target_tile = tmp
		target_pos = next_pos
		target_cell = tmp_cell
		target_layer = l
		y_sort_origin = tilemap.get_layer_y_sort_origin(l) # get y_sort of the next tile above
		i += 1
	print("after TMP - %s, [%s, %s], %s" % [target_layer, target_cell, target_pos, y_sort_origin])
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
	print("<%s>%s, %s" % [layer, cell_coords, tile])
	if tile:
		var polygon = tile.get_collision_polygon_points(2, 0)
		var i := 0
		# offset polygon points to use cell's local position
		for point in polygon:
			polygon.set(i, Vector2i(point.x + cell_pos.x, point.y + cell_pos.y))
			i += 1
		var inside := Geometry2D.is_point_in_polygon(point_pos, polygon) # check if point is in polygon
		#print("==%s, %s==%s , %s" % [point_pos, offset, cell_coords, cell_pos])
		if inside:
			return tile
	return null


func _on_touch_tile_top(body : Node2D):
	if body is TileMap:
		var dict = select_tile(body)
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
