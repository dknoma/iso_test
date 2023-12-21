extends Node

var tilemap : TileMap

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tilemap = get_tree().get_first_node_in_group("tilemap") as TileMap
	
	for layer in tilemap.get_layers_count():
		var cells := tilemap.get_used_cells(layer)
		for cell in cells:
			var label = Label.new()
			add_child(label)
			var pos = tilemap.map_to_local(cell)
			label.global_position = Vector2(pos.x, pos.y - (2 * layer))
			label.text = "(%s, %s)" % [cell.x, cell.y]
			#label.size = Vector2(0.25, 0.25)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
