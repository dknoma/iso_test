class_name Player extends CharacterBody2D


const SPEED = 100.0
const JUMP_VELOCITY = -400.0

@onready var body_sprite : Sprite2D = $Body
@onready var camera : Camera2D = $Camera

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")


func _ready() -> void:
	var pointer = get_tree().get_first_node_in_group("pointer")
	pointer.tile_selected.connect(_on_tile_selected)


func _physics_process(delta: float) -> void:
	# Add the gravity.
	#if not is_on_floor():
		#velocity.y += gravity * delta
#
	## Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction:
		velocity = direction * SPEED
		#velocity.x = direction.x * SPEED
	else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity = Vector2()

	move_and_slide()


func _on_tile_selected(global_position : Vector2, tile_data : TileData, y_sort_origin : int) -> void:
	var offset_id : int = tile_data.get_custom_data(&"offset_id")
	# TODO: change offset to real values for moving sprite
	var offset : int = TilesUtil.OFFSET.get(offset_id, -16) # get offset value or default
	# offset by y_sort_origin to know how "high" tile is
	body_sprite.offset.y = -10 + offset - y_sort_origin 
	self.global_position = Vector2(global_position.x, global_position.y + y_sort_origin)
	self.z_index = 0
	camera.global_position.y = global_position.y + offset # apply offset to follow body sprite
	
