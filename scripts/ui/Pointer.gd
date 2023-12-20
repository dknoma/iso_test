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
				if selected_tile:
					selected_tile = null
				polygon.hide()
				#return
			top_collider.disabled = true
			top_collider.disabled = false
		elif Input.is_action_just_pressed(&"pointer_unselect"):
			selected_tile = null
			polygon.hide()
			polygon.position = Vector2()
			var markers : Node = get_tree().get_first_node_in_group("markers")
			for c in markers.get_children():
				c.queue_free()
	elif event is InputEventKey:
		print("event=%s, %s, %s ,%s" % [event, pressed, event.is_pressed(), Input.is_physical_key_pressed(KEY_Q)])
		if event.keycode == KEY_Q and event.is_pressed() and !pressed:
			pressed = true
			
			var mouse_pos = get_global_mouse_position()
			var target_cell = tilemap.local_to_map(Vector2(mouse_pos.x, mouse_pos.y + 16))
			var target_pos = tilemap.map_to_local(target_cell)
			var selected_cell = tilemap.local_to_map(selected_pos)
			print("target=%s, selected=%s" % [target_cell, selected_cell])
			
			#if neighbor_direction == -1: return
			var tile : TileData
			var range := 4
			var neighbor_direction := -1
			var next_cell : Vector2i = selected_cell
			var next_pos : Vector2 = selected_pos
			#print("next=%s, %s" % [next_cell, cell_neighbor_name(neighbor_direction)])
			#neighbor_direction = get_neighbor_direction(target_pos, next)
			var cell_cache : Array[Vector2i] = [selected_cell]
			var i := 0
			var y_sort_origin := tilemap.get_layer_y_sort_origin(selected_layer)
			for c in markers.get_children():
				c.queue_free()
			while next_cell != target_cell:
				neighbor_direction = get_neighbor_direction(target_pos, next_pos)
				next_cell = tilemap.get_neighbor_cell(next_cell, neighbor_direction)
				next_pos = tilemap.map_to_local(next_cell)
				cell_cache.append(next_cell)
				print("i=%s, %s" % [i, next_cell])
				i += 1
				if next_cell == target_cell: 
					print("found")
					#break
			#print("ugh=%s, %s" % [target_cell, next_cell])
			for cell in cell_cache:
				tile = tilemap.get_cell_tile_data(selected_layer, cell)
				var pos = tilemap.map_to_local(cell)
				
				
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
				
				var p := tile.get_collision_polygon_points(3, 0)
				# adjust polygon point positions to account for layer y_sort_origin
				var j = 0
				for point in p:
					p.set(j, Vector2(point.x, point.y - y_sort_origin))
					j += 1
				var new_polygon = Polygon2D.new()
				markers.add_child(new_polygon)
				new_polygon.y_sort_enabled = true
				new_polygon.set_polygon(p)
				new_polygon.z_index = 0
				new_polygon.global_position = Vector2(pos.x, pos.y + y_sort_origin)
						#polygon.hide()
						#polygon.polygon = p
						#polygon.global_position = Vector2(pos.x, pos.y + y_sort_origin)
						#polygon.z_index = 0 # default z_index
						#polygon.show()
			if i > range:
				for poly in markers.get_children():
					poly.self_modulate = Color(1, 0, 0, 0.5)
				print("out of range %s != %s" % [next_cell, target_cell])
			else:
				for poly in markers.get_children():
					poly.self_modulate = Color(0.686275, 0.933333, 0.933333, 0.5)
				
		elif event.keycode == KEY_Q and !event.is_pressed() and pressed:
			pressed = false
		#if Input.is_action_just_pressed("ui_text_completion_replace"):
		

func get_neighbor_direction(target_pos : Vector2, selected_pos : Vector2) -> int:
	var neighbor_direction = -1
	
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


func _on_touch_tile_top(body : Node2D):
	if body is TileMap:
		var point_pos := body.get_local_mouse_position()

		#var layer := -1
		var tile_data : TileData
		var top_data : TileData
		var top_neighbor : TileData
		var bot_data : TileData
		# get positions of possible overlapping tiles
		var top_pos : Vector2i = body.local_to_map(point_pos)
		var top_cell_pos : Vector2 = body.map_to_local(top_pos)
		var neighbor : Vector2i = body.get_neighbor_cell(top_pos, TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE if  point_pos.x - top_cell_pos.x < 0 else TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE) # get closest overlapping neighbor cell
		var neighbor_cell_pos : Vector2 = body.map_to_local(neighbor)
		var base_pos : Vector2i = body.local_to_map(Vector2(point_pos.x, point_pos.y + 16))
		var base_cell_pos : Vector2 = body.map_to_local(base_pos)
		
		# go from highest layer to lowest as highest are "closest" from the player's perspective
		var y_sort_origin := 0
		for l in range(body.get_layers_count() - 1, -1, -1):
			# check all 3 possible overlapping tiles: top cell, closest neighbor, below cell
			y_sort_origin = body.get_layer_y_sort_origin(l)
			top_data = try_get_tile(l, point_pos, top_pos, top_cell_pos, body)
			top_neighbor = try_get_tile(l, point_pos, neighbor, neighbor_cell_pos, body)
			bot_data = try_get_tile(l, point_pos, base_pos, base_cell_pos, body)
			
			# check tiles pointer is inside; set selected to 'closest' one (bot > neighbor > top)
			if bot_data:
				tile_data = bot_data
				selected_pos = base_cell_pos
				selected_layer = l
				print("bot-%s,%s,%s" % [tile_data, selected_pos, selected_layer])
				break
			elif top_neighbor:
				tile_data = top_neighbor
				selected_pos = neighbor_cell_pos
				selected_layer = l
				print("neighbor-%s,%s,%s" % [tile_data, selected_pos, selected_layer])
				break
			elif top_data:
				tile_data = top_data
				selected_pos = top_cell_pos
				selected_layer = l
				print("top-%s,%s,%s" % [tile_data, selected_pos, selected_layer])
				break

		if tile_data:
			selected_tile = tile_data
			var next_cell = body.local_to_map(selected_pos)
			var next_pos := Vector2(selected_pos.x, selected_pos.y - 16)
			print_debug("selected %s, %s | %s" % [next_cell, next_pos, body.get_layers_count()])
			var tmp : TileData
			var i = 1 # the amount of 16px offset for the next layers
			for l in range(selected_layer + 1, body.get_layers_count()):
				next_pos = Vector2(selected_pos.x, selected_pos.y - (i * 16))
				# use next_pos since 'inside(...)' should always be true for tiles above the selected one
				tmp = try_get_tile(l, next_pos, Vector2i(next_cell.x, next_cell.y - (i * 2)), next_pos, body)
				print_debug("check above tiles: %s - %s = %s" % [point_pos, next_pos, tmp])
				if !tmp: break # break if run out of tiles directly connected above; should not select tiles that are above but not connected
				selected_tile = tmp
				selected_pos = next_pos
				selected_layer = l
				i += 1
				y_sort_origin = body.get_layer_y_sort_origin(l) # get y_sort of the next tile above
			var global_pos := body.to_global(selected_pos)
			# get surface polygon shape from collision layer 3
			var p := selected_tile.get_collision_polygon_points(3, 0)
			# adjust polygon point positions to account for layer y_sort_origin
			i = 0
			for point in p:
				p.set(i, Vector2(point.x, point.y - y_sort_origin))
				i += 1
			polygon.hide()
			polygon.polygon = p
			# prevent collider from triggering whenever pointer moves position
			top_collider.set_deferred("disabled", true)
			global_position =  Vector2(global_pos.x, global_pos.y)
			polygon.global_position = Vector2(global_pos.x, global_pos.y + y_sort_origin)
			polygon.z_index = 0 # default z_index
			polygon.show()
			tile_selected.emit(global_pos, selected_tile, y_sort_origin)
		else:
			selected_tile = null


func try_get_tile(layer : int, point_pos : Vector2, cell_coords : Vector2i, cell_pos : Vector2, tilemap : TileMap) -> TileData:
	var tile : TileData = tilemap.get_cell_tile_data(layer, cell_coords)
	#print("<%s>%s, %s" % [layer, cell_coords, tile])
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
