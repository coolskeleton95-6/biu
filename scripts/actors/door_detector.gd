extends Area2D
class_name DoorDetector

signal state_changed(is_active: bool)

var active_bodies: Array[Node2D] = []
var is_active: bool = false

func _ready() -> void:
	# Enable monitoring
	monitoring = true
	monitorable = false
	
	# Connect collision signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Visual feedback (Start inactive)
	modulate = Color(0.5, 1.5, 0.5)

func _on_body_entered(body: Node2D) -> void:
	# Checks for anything in the "box" group (Box.gd and Bomb.gd both have this)
	print_debug(body.name)
	if body.is_in_group("box"):
		active_bodies.append(body)
		_update_state()

func _on_body_exited(body: Node2D) -> void:
	if body in active_bodies:
		active_bodies.erase(body)
		_update_state()

func _update_state() -> void:
	var new_state = active_bodies.size() > 0
	
	if is_active != new_state:
		is_active = new_state
		state_changed.emit(is_active)
		
		# Visual Feedback
		if is_active:
			modulate = Color(0.5, 1.5, 0.5) # Glow Green
		else:
			modulate = Color(0.5, 1.5, 0.5)
