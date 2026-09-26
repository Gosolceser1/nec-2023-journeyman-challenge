extends SceneTree

func _init() -> void:
	print("Validating main.tscn loading and table viewer...")
	var scene = load("res://Main.tscn")
	if scene == null:
		push_error("Failed to load main.tscn")
		quit(1)
		return
	var main_node = scene.instantiate()
	if main_node == null:
		push_error("Failed to instantiate main.tscn")
		quit(1)
		return
	print("main.tscn instantiated successfully!")
	quit(0)
