class_name Pointer extends Node2D

@onready var point_cast : RayCast2D = $point_cast
@onready var top_pointer : Area2D = $tile_top_pointer
@onready var top_collider : CollisionShape2D = $tile_top_pointer/Collider
@onready var base_pointer : Area2D = $tile_base_pointer
@onready var base_collider : CollisionShape2D = $tile_base_pointer/Collider
@onready var highlighter : Sprite2D = $tile_base_pointer/Highlighter
#@onready var point : StaticBody2D = $Collider/point
#@onready var point_collider : CollisionShape2D = $Collider/point/Collider


var tilemap : TileMap
var mouse_pos : Vector2
#var selected_cell : Vector2

#var collecting_point := false

#var layer_collisions_cache := {}

#var layer_collisions_cache : Array[int] = []

func _ready() -> void:
	highlighter.hide()
	tilemap = get_tree().get_first_node_in_group("tilemap")
	top_pointer.body_entered.connect(_on_touch_tile_top)
	base_pointer.body_entered.connect(_on_touch_tile_base)
	top_collider.disabled = true
	base_collider.disabled = true
	#point_cast.enabled = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		get_tree().paused = true
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		get_tree().paused = false

#
#func _physics_process(delta: float) -> void:
	#if !collecting_point: return
#
	#var coll = point_cast.get_collider()
	#if !coll:
		##for c in layer_collisions_cache:
			##tilemap.set_layer_enabled(c, true)
		##collecting_point = false
		##layer_collisions_cache.clear()
		#return
	#var layer_id = coll.get_layer_for_body_rid(point_cast.get_collider_rid())
	#var coords = coll.get_coords_for_body_rid (point_cast.get_collider_rid())
	#if layer_id < 0: return
	#print("coords=", coords)
	#if !layer_collisions_cache.has(layer_id):
		#print("add[%s]" % [layer_id])
		#layer_collisions_cache[layer_id] = true
		#coll.set_layer_enabled(layer_id, false)
	#else:
		##collisions[layer_id] = true
		#print("has[%s]" % [layer_id])
	#var coll = point_cast.get_collider()
		## If floor raycast is touching tilemap, get the tile that player is current above
	#if coll is TileMap:
		#var tileset : TileSet = coll.get_tileset()
		#var tile_pos = (coll as TileMap).local_to_map(point_cast.get_collision_point()) # tile cell position
		#var layer_id = coll.get_layer_for_body_rid(point_cast.get_collider_rid()) # RID of tilemap layer
		#print("layer=", layer_id)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if Input.is_action_just_pressed(&"pointer_select"):
			#point_cast.enabled = false
			#layer_collisions_cache.clear()
			highlighter.hide()
			mouse_pos = get_global_mouse_position()
			global_position = mouse_pos
			#collecting_point = true
			#point_cast.enabled = true
			if !point_cast.get_collider():
				print("no collider")
				if selected_tile:
					selected_tile.modulate = Color.WHITE
					selected_tile = null
				top_pointer.position = Vector2()
				base_pointer.position = top_pointer.position
				return
			#selected_cell = tilemap.local_to_map(mouse_pos)
			#var cell_pos := tilemap.map_to_local(selected_cell)
			#global_position = Vector2(cell_pos.x, cell_pos.y)
			top_collider.disabled = true
			top_collider.disabled = false
			base_collider.disabled = true
			base_collider.disabled = false
			#point_collider.disabled = true
			#point_collider.disabled = false
			pass
			#tilemap.get_layer_name()
		elif Input.is_action_just_pressed(&"pointer_unselect"):
			highlighter.hide()
			#var mouse_pos := get_global_mouse_position()
			#var cell_pos := tilemap.map_to_local(tilemap.local_to_map(mouse_pos))
			#global_position = Vector2(cell_pos.x, cell_pos.y - 16)
			#print_debug("mouse point = %s->%s->%s" % [mouse_pos, tilemap.local_to_map(mouse_pos), tilemap.map_to_local(tilemap.local_to_map(mouse_pos))])

var selected_tile : TileData

func _on_touch_tile_top(body : Node2D):
	if body is TileMap:
		#print_debug("top - %s, %s" % [body, top_pointer.get_overlapping_bodies()])
		#selected_cell = body.local_to_map(Vector2(mouse_pos.x, mouse_pos.y + 16))
		var point_pos := body.get_local_mouse_position()
		var top_pos : Vector2i = body.local_to_map(point_pos)
		var base_pos : Vector2i = body.local_to_map(Vector2(point_pos.x, point_pos.y + 16))
		top_pointer.global_position = mouse_pos

		print("%s, %s, %s" % [point_pos, top_pos, base_pos])

		var tile_data : TileData = null
		var selected_pos : Vector2
		var top_cell_pos : Vector2 = body.map_to_local(top_pos)
		var base_cell_pos : Vector2 = body.map_to_local(base_pos)
		var layer := -1

		var top_data = TileData
		var top_neighbor = TileData
		var bot_data = TileData

		var neighbor : Vector2i
		var neighbor_cell_pos : Vector2
		for l in range(body.get_layers_count() - 1, -1, -1):
			# get neighbor cell closest to pointer
			neighbor = body.get_neighbor_cell(top_pos, TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE if  point_pos.x - top_cell_pos.x < 0 else TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE)
			neighbor_cell_pos =  body.map_to_local(neighbor)
			print("[%s]side neighbor(%s) side check=%s-=-%s  / %s" % [l, "left" if  point_pos.x - top_cell_pos.x < 0 else "right", top_pos, neighbor, neighbor_cell_pos])

			# check all 3 possible overlapping tiles: top cell, closest neighbor, below cell
			top_data = try_get_tile(l, point_pos, top_pos, top_cell_pos, body, 0, 0)
			top_neighbor = try_get_tile(l, point_pos, neighbor, neighbor_cell_pos, body)
			bot_data = try_get_tile(l, point_pos, base_pos, base_cell_pos, body)

			print("OMG=%s, %s, %s" % [top_data, top_neighbor, bot_data])

			if bot_data:
				tile_data = bot_data
				selected_pos = base_cell_pos
				layer = l
				break
			elif top_neighbor:
				tile_data = top_neighbor
				selected_pos = neighbor_cell_pos
				layer = l
				break
			elif top_data:
				tile_data = top_data
				selected_pos = top_cell_pos
				layer = l
				break

		if tile_data:
			if selected_tile: selected_tile.modulate = Color.WHITE
			selected_tile = tile_data
			selected_tile.modulate = Color.REBECCA_PURPLE
			#tilemap.local_to_map()
			var global_pos := body.to_global(selected_pos)
			highlighter.global_position = Vector2(global_pos.x, global_pos.y - 24)
			highlighter.show()
			highlighter.z_index = layer + 1

		#var tmp : Vector2 = body.to_global(body.map_to_local(top_pos))
		#$tile_base_pointer/test.global_position = Vector2(tmp.x, tmp.y - 8)
#
		#print_debug("mouse point = %s->%s->%s; %s" % [mouse_pos, body.local_to_map(mouse_pos), body.map_to_local(body.local_to_map(mouse_pos)), body.get_layers_count()])


func try_get_tile(layer : int, point_pos : Vector2, cell_coords : Vector2i, cell_pos : Vector2, tilemap : TileMap, x_offset := 0, y_offset := 0) -> TileData:
	var tile : TileData

	tile = tilemap.get_cell_tile_data(layer, cell_coords)
	print("<%s>%s, %s" % [layer, cell_coords, tile])
	var z_index = tilemap.get_layer_z_index(layer)
	if tile:
		var polygon = tile.get_collision_polygon_points(2, 0)
		print(polygon)
		var i := 0
		for point in polygon:
			polygon.set(i, Vector2i(point.x + cell_pos.x, point.y + cell_pos.y))
			i += 1
		print(polygon)
		var offset := Vector2(point_pos.x + x_offset, point_pos.y + y_offset)
		var inside := Geometry2D.is_point_in_polygon(offset, polygon)
		print("==%s, %s==%s , %s" % [point_pos, offset, cell_coords, cell_pos])
		if inside:
			print("clicked %s inside layer[%s]" % [point_pos, layer])
			return tile
	return null


func _on_touch_tile_base(body : Node2D):
	#print_debug("base - %s" % [body])

	if body is TileMap:
		var local := body.get_local_mouse_position()
		#var cell_pos : Vector2 = body.local_to_map(Vector2(local.x, local.y + 16))
		##var cell_base_pos := Vector2(cell_pos.x, cell_pos.y + 16)
		##selected_cell = body.local_to_map(Vector2(mouse_pos.x, mouse_pos.y + 16))
		#var pos : Vector2 = body.map_to_local(cell_pos)
		#base_pointer.global_position = Vector2(pos.x, pos.y - 16)

		#var layer = body.get_layer_for_body_rid(get_rid())
		#var layer = body.get_coords_for_body_rid(get_rid())
		#var tile : TileData
		#var layer := -1
		#for l in range(body.get_layers_count() - 1, -1, -1):
			#tile = body.get_cell_tile_data(l, cell_pos)
			#var z_index = body.get_layer_z_index(l)
			#if tile:
				#layer = l
				#break
		##print_debug("bot[%s]=%s" % [layer, body.get_layer_z_index(layer)])
		#if layer >= 0:
			#highlighter.show()

		#print_debug("mouse point = %s->%s->%s; %s" % [mouse_pos, body.local_to_map(mouse_pos), body.map_to_local(body.local_to_map(mouse_pos)), body.get_layers_count()])
