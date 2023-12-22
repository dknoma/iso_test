class_name Player extends Node2D


const SPEED = 2.0
const JUMP_VELOCITY = -400.0

@onready var body : CharacterBody2D = $Body
@onready var body_sprite : Sprite2D = $Body/Sprite
@onready var camera : Camera2D = $Body/Camera
@onready var area : Area2D = $"Body/Area2D"

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

var tilemap : TileMap
var pointer : Pointer
var body_offset : int

var base_pos := Vector2()

func _ready() -> void:
	tilemap = get_tree().get_first_node_in_group("tilemap")
	tilemap.top_level = true
	pointer = get_tree().get_first_node_in_group("pointer")
	pointer.tile_selected.connect(_on_tile_selected)
	area.body_entered.connect(_on_tile_entered)
	#body.top_level = true


func _physics_process(delta: float) -> void:
	# Add the gravity.
	#if not is_on_floor():
		#velocity.y += gravity * delta
#
	## Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
	#var current_cell = tilemap.local_to_map(Vector2(position.x, position.y - body_offset))
	#var origin_cell = tilemap.local_to_map(Vector2(position.x, position.y))
	#print_debug("%s | %s" % [current_cell, origin_cell])
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	# TODO: make diagonal movement something liek 2/1 instead of 1/1?
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var speed_mod := SPEED
	if direction:
		if direction.x != 0 and direction.y != 0:
			direction.y = direction.y / 2
			speed_mod = speed_mod * 1.25
		var data := pointer.select_tile(body.global_position, tilemap)
		var tile_data : TileData = data.get("tile", null) as TileData
		var target_pos : Vector2 = data.get("target_pos", Vector2())
		var origin_offset : float = data.get("y_sort_origin", 0)
		var layer : int = data.get("layer", 0)
		var offset := Vector2()
		var ramp := false
		if tile_data:
			var info : Dictionary = tile_data.get_custom_data("info")
			if !info.is_empty():
				# TODO: can calculate height value of ramp via x pixel pos
				if info["type"] == "ramp" and !info["properties"].is_empty():
					#print_debug(info)
					ramp = true
					var dir : Vector2 = info["properties"]["direction"]
					if direction.x > 0:
						if dir.x > 0:
							offset.y = dir.y
						elif dir.x < 0:
							offset.y = -dir.y
						else:
							offset.y = 0
					elif direction.x < 0:
						if dir.x > 0:
							offset.y = -dir.y
						elif dir.x < 0:
							offset.y = dir.y
						else:
							offset.y = 0
						#offset.y = -dir.y if dir.x > 0 else dir.y if dir.x < 0 else 0
		
		base_pos = base_pos + (direction * speed_mod)
		var next_pos := body.global_position + (Vector2(direction.x, direction.y + offset.y) * speed_mod)
		#var next_origin_pos := body.global_position + (direction * SPEED)
		var cell := tilemap.local_to_map(next_pos)
		var origin_pos = tilemap.map_to_local(cell)
		var pixel_x_pos : int = roundi(next_pos.x + (16 if (cell.y % 2) != 0 else 0)) % 32
		print("cell=%s, %s, %s, %s" % [cell, pixel_x_pos, origin_offset, offset])
		#print_debug("c=%s, %s" % [origin_pos, target_pos])
		global_position = Vector2i(base_pos.x, base_pos.y)
		#global_position = Vector2i(origin_pos.x, origin_pos.y + body_offset + 23)
		body.global_position = next_pos
		
		#body.velocity = direction * SPEED
		#velocity.x = direction.x * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)
		#body.velocity = Vector2()

	#body.move_and_slide()


func _on_tile_selected(to_position : Vector2, tile_data : TileData, y_sort_origin : int) -> void:
	var offset_id : int = tile_data.get_custom_data(&"offset_id")
	# TODO: change offset to real values for moving sprite
	body_offset = y_sort_origin
	var offset : int = TilesUtil.OFFSET.get(offset_id, -16) # get offset value or default
	# offset by y_sort_origin to know how "high" tile is
	#body_sprite.position = Vector2(to_position.x, to_position.y + offset)
	#body_sprite.offset.y = -10 + offset - body_offset 
	base_pos = Vector2(to_position.x, to_position.y + 11)
	global_position = Vector2(to_position.x, to_position.y + body_offset)
	body.global_position = Vector2(to_position.x, to_position.y + offset)
	z_index = 0
	camera.global_position = Vector2(to_position.x, to_position.y + offset) # apply offset to follow body sprite
	#lerp()


func _on_tile_entered(body : Node2D) -> void:
	if body is TileMap:
		print_debug("tile")


