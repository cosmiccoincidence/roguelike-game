# player_state_machine.gd
# Manages player movement states and transitions
extends Node

# ===== MOVEMENT STATES =====
enum State {
	IDLE,
	WALKING,
	SPRINTING,
	DASHING,
	DODGE_ROLLING,
	# Future states can be added here:
	# CROUCHING,
	# SLIDING,
	# CLIMBING,
	# SWIMMING,
	# etc.
}

# ===== STATE VARIABLES =====
var current_state: State = State.IDLE
var previous_state: State = State.IDLE

# ===== REFERENCES =====
var player: CharacterBody3D
var movement_component: Node

# ===== SIGNALS =====
signal state_changed(old_state: State, new_state: State)

# ===== INITIALIZATION =====

func initialize(player_node: CharacterBody3D, movement_node: Node):
	"""Called by player to set references"""
	player = player_node
	movement_component = movement_node

# ===== STATE MANAGEMENT =====

func change_state(new_state: State) -> bool:
	"""
	Attempt to change to a new state.
	Returns true if successful, false if transition is invalid.
	"""
	# Check if transition is valid
	if not _can_transition_to(new_state):
		return false
	
	# Exit current state
	_exit_state(current_state)
	
	# Update states
	previous_state = current_state
	current_state = new_state
	
	# Enter new state
	_enter_state(current_state)
	
	# Emit signal
	state_changed.emit(previous_state, current_state)
	
	return true

func get_state() -> State:
	"""Get current movement state"""
	return current_state

func get_state_name() -> String:
	"""Get current state as string (for debugging)"""
	return State.keys()[current_state]

func is_in_state(state: State) -> bool:
	"""Check if currently in a specific state"""
	return current_state == state

func is_in_any_state(states: Array[State]) -> bool:
	"""Check if currently in any of the provided states"""
	return current_state in states

# ===== STATE TRANSITIONS =====

func _can_transition_to(new_state: State) -> bool:
	"""Check if we can transition from current state to new state"""
	
	# Can always transition to same state (no-op)
	if new_state == current_state:
		return true
	
	match current_state:
		State.IDLE:
			# Can go anywhere from idle
			return true
		
		State.WALKING:
			# Can go anywhere from walking
			return true
		
		State.SPRINTING:
			# Can go anywhere from sprinting
			return true
		
		State.DASHING:
			# Can only go to idle/walking/sprinting after dash ends
			# Cannot start dodge roll during dash
			return new_state in [State.IDLE, State.WALKING, State.SPRINTING]
		
		State.DODGE_ROLLING:
			# Can only go to idle/walking/sprinting after dodge roll ends
			# Cannot start dash during dodge roll
			return new_state in [State.IDLE, State.WALKING, State.SPRINTING]
	
	# Default: allow transition
	return true

# ===== STATE ENTER/EXIT =====

func _enter_state(state: State):
	"""Called when entering a new state"""
	match state:
		State.IDLE:
			pass  # Nothing special for idle
		
		State.WALKING:
			pass  # Nothing special for walking
		
		State.SPRINTING:
			pass  # Sprint stamina handled in movement component
		
		State.DASHING:
			if movement_component:
				movement_component.is_dashing = true
		
		State.DODGE_ROLLING:
			if movement_component:
				movement_component.is_dodge_rolling = true
	
	# Debug print
	print("State: %s → %s" % [State.keys()[previous_state], State.keys()[state]])

func _exit_state(state: State):
	"""Called when exiting a state"""
	match state:
		State.IDLE:
			pass
		
		State.WALKING:
			pass
		
		State.SPRINTING:
			pass
		
		State.DASHING:
			if movement_component:
				movement_component.is_dashing = false
		
		State.DODGE_ROLLING:
			if movement_component:
				movement_component.is_dodge_rolling = false

# ===== STATE LOGIC =====

func update_state(delta: float, input_dir: Vector2, is_moving: bool, wants_sprint: bool):
	"""
	Update state based on input and conditions.
	Called every physics frame.
	"""
	match current_state:
		State.IDLE:
			if is_moving:
				if wants_sprint:
					change_state(State.SPRINTING)
				else:
					change_state(State.WALKING)
		
		State.WALKING:
			if not is_moving:
				change_state(State.IDLE)
			elif wants_sprint:
				change_state(State.SPRINTING)
		
		State.SPRINTING:
			if not is_moving:
				change_state(State.IDLE)
			elif not wants_sprint:
				change_state(State.WALKING)
		
		State.DASHING:
			# Dash automatically ends when timer expires (handled in movement component)
			if movement_component and not movement_component.is_dashing:
				if is_moving:
					if wants_sprint:
						change_state(State.SPRINTING)
					else:
						change_state(State.WALKING)
				else:
					change_state(State.IDLE)
		
		State.DODGE_ROLLING:
			# Dodge roll automatically ends when timer expires (handled in movement component)
			if movement_component and not movement_component.is_dodge_rolling:
				if is_moving:
					if wants_sprint:
						change_state(State.SPRINTING)
					else:
						change_state(State.WALKING)
				else:
					change_state(State.IDLE)

# ===== HELPER FUNCTIONS =====

func can_dash() -> bool:
	"""Check if player can dash in current state"""
	return current_state in [State.IDLE, State.WALKING, State.SPRINTING]

func can_dodge_roll() -> bool:
	"""Check if player can dodge roll in current state"""
	return current_state in [State.IDLE, State.WALKING, State.SPRINTING]

func can_sprint() -> bool:
	"""Check if player can sprint in current state"""
	return current_state in [State.IDLE, State.WALKING]

func is_action_locked() -> bool:
	"""Check if player is in a state that locks actions (dash, dodge roll, etc.)"""
	return current_state in [State.DASHING, State.DODGE_ROLLING]
