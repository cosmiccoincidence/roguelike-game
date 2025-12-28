extends EnemyBase
# Enemy1.gd

@export var grunt_sfx: AudioStream
@export var attack_sfx: AudioStream
@export var hit_sfx: AudioStream

func _ready():
	# Set base enemy level (0 = normal, +1 = slightly harder, +2 = elite, etc.)
	base_enemy_level = 0  # Normal enemy
	
	# Set BASE stats (these will be scaled by enemy_level)
	# enemy_level is now calculated as: map_level + base_enemy_level
	base_max_health = 10
	base_damage = 2
	health_per_level = 1  # +2 HP per level
	damage_per_level = 0.5  # +0.5 damage per level (rounds down)
	
	# If enemy_level was already set by map generator, scale stats now
	# Otherwise, use default enemy_level (5) from EnemyBase
	if enemy_level > 0:
		scale_stats_to_level()
	
	# Other stats (not level-dependent)
	crit_chance = 0.1
	crit_multiplier = 2.0
	
	# Behavior
	rotation_change_interval = 5.0
	rotation_speed = 40.0
	combat_rotation_speed = 140.0
	detection_range = 5.0
	aggro_range = 15.0
	attack_range = 2.0
	move_speed = 5.0
	attack_cooldown = 1.0
	
	# Sounds (optional overrides)
	vocal_sounds = {
		#"grunt": grunt_sfx
	}
	combat_sounds = {
		#"attack": attack_sfx,
		#"hit": hit_sfx
	}
	
	super._ready()
