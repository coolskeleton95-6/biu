extends Node

# Configuration
@export var max_history: int = 50

# Dependencies (Found automatically or assigned)
var player: Node2D
var bomb_placer: Node2D

# State
var state_history: Array[Dictionary] = []

func _ready() -> void:
	# Assume the parent is the Player
	player = get_parent()
	
	# Find BombPlacer sibling
	if player.has_node("BombPlacer"):
		bomb_placer = player.get_node("BombPlacer")
	else:
		push_warning("HistoryManager: BombPlacer not found on Player.")

func record_snapshot() -> void:
	if not player: return

	var snapshot = {
		"player_pos": player.position,
		"boxes": [],
		"bombs": []
	}
	
	# 1. Snapshot Persistent Boxes
	# We iterate the "box" group, but skip bombs (which are also in group "box")
	var boxes = get_tree().get_nodes_in_group("box")
	for box in boxes:
		# Check if this node is managed by bomb_placer (is a bomb)
		if bomb_placer and box in bomb_placer.active_bombs:
			continue
			
		if box.has_method("get_snapshot"):
			snapshot.boxes.append(box.get_snapshot())
			
	# 2. Snapshot Transient Bombs
	if bomb_placer:
		for bomb in bomb_placer.active_bombs:
			if is_instance_valid(bomb) and bomb.has_method("get_snapshot"):
				snapshot.bombs.append(bomb.get_snapshot())
			
	state_history.append(snapshot)
	if state_history.size() > max_history:
		state_history.pop_front()

func undo_last_action() -> void:
	# Prevent undo if player is currently moving (to avoid tween conflicts)
	if player.get("is_moving") or state_history.is_empty():
		return
		
	var snapshot = state_history.pop_back()
	restore_state(snapshot)

func restore_state(snapshot: Dictionary) -> void:
	# 1. Restore Player
	player.position = snapshot.player_pos
	
	# 2. Restore Boxes
	# Because boxes persist, we rely on the node reference.
	for box_data in snapshot.boxes:
		var box = box_data.node
		if is_instance_valid(box) and box.has_method("restore_snapshot"):
			box.restore_snapshot(box_data)
			# Kill any active tweens on the box to stop movement immediately
			var t = box.create_tween()
			t.kill()
			
	# 3. Restore Bombs
	if bomb_placer:
		_restore_bombs(snapshot.bombs)

func _restore_bombs(bombs_data: Array) -> void:
	# A. Cleanup current active bombs
	var current_bombs = bomb_placer.active_bombs.duplicate()
	bomb_placer.active_bombs.clear()
	
	for bomb in current_bombs:
		if is_instance_valid(bomb):
			bomb.queue_free()
			
	# B. Respawn bombs from history
	for bomb_data in bombs_data:
		# Spawn a fresh bomb at the saved position
		var new_bomb = bomb_placer.spawn_bomb_at(bomb_data.pos)
		
		# Restore its internal state (Floating, Water info, etc)
		if new_bomb.has_method("restore_snapshot"):
			new_bomb.restore_snapshot(bomb_data)
