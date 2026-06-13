extends Node2D
class_name CombatManager

@onready var math_manager: MathManager = $MathManager
@onready var player: Node2D = $Player
@onready var enemy: Node2D = $Enemy
@onready var ui: Control = $CanvasLayer/BattleUI
@onready var backgrounds: Array[Sprite2D] = [$Background, $Background2, $Background3, $Background4]


var current_difficulty: MathManager.Difficulty = MathManager.Difficulty.ARMY1
var current_question: Dictionary = {}
var timer: float = 0.0
var is_active: bool = false
var is_transitioning: bool = false

var army_data: Dictionary = {}
@export var global_enemy_sfx_volume: float = 0.0 # Adjust this to change volume for ALL enemies

func _ready() -> void:
	# Initialize army data with specific SFX and volume control
	army_data = {
		MathManager.Difficulty.ARMY1: {
			"hp": 40,
			"name": "Frosty",
			"texture": preload("res://assets/generated/enemy_army_1_frame_0.png"),
			"player_dmg": 10,
			"enemy_dmg": 8,
			"sfx_attack": SoundManager.SFX_E1SLASH,
			"sfx_hit": SoundManager.SFX_E1HIT,
			"sfx_death": SoundManager.SFX_E1DEATH,
			"vol_attack": 1.0,
			"vol_hit": 2.0,
			"vol_death": -2.0
		},
		MathManager.Difficulty.ARMY2: {
			"hp": 60,
			"name": "Darky",
			"texture": preload("res://assets/generated/enemy_army_2_frame_0.png"),
			"player_dmg": 10,
			"enemy_dmg": 12,
			"sfx_attack": SoundManager.SFX_E2SLASH,
			"sfx_hit": SoundManager.SFX_E2HIT,
			"sfx_death": SoundManager.SFX_E2DEATH,
			"vol_attack": 0.0,
			"vol_hit": 0.0,
			"vol_death": 0.0
		},
		MathManager.Difficulty.ARMY3: {
			"hp": 70,
			"name": "Sickly",
			"texture": preload("res://assets/generated/enemy_boss_frame_0.png"),
			"player_dmg": 14,
			"enemy_dmg": 16,
			"sfx_attack": SoundManager.SFX_E3SLASH,
			"sfx_hit": SoundManager.SFX_E3HIT,
			"sfx_death": SoundManager.SFX_E3DEATH,
			"vol_attack": -2.0,
			"vol_hit": -4.0,
			"vol_death": 0.0
		},
		MathManager.Difficulty.BOSS: {
			"hp": 100,
			"name": "Sparky",
			"texture": preload("res://art/tile_0121.png"),
			"player_dmg": 20,
			"enemy_dmg": 24,
			"sfx_attack": SoundManager.SFX_E4SLASH,
			"sfx_hit": SoundManager.SFX_E4HIT,
			"sfx_death": SoundManager.SFX_E4DEATH,
			"vol_attack": 2.0,
			"vol_hit": 1.0,
			"vol_death": -4.0
		}
	}

	# Start background music
	SoundManager.play_bgm(SoundManager.BGM_FIGHT, -20)
	
	ui.answer_submitted.connect(_on_answer_submitted)
	ui.retry_requested.connect(reset_entire_game)
	player.health_changed.connect(ui.update_player_hp)
	enemy.health_changed.connect(_on_enemy_health_changed)
	
	update_background_visibility()
	start_battle()
	
	# Injected dynamic admin layout generation
	create_admin_panel()

func start_battle() -> void:
	is_transitioning = false 
	if ui.status_label:
		ui.status_label.hide() # Explicitly clears out "Great job!", etc., when starting the next round
	setup_enemy()
	next_question()
	is_active = true
	ui.is_battle_active = true

func setup_enemy() -> void:
	var data: Dictionary = army_data[current_difficulty]
	enemy.setup(data["hp"], data["name"], data["texture"])
	enemy.base_damage = data["enemy_dmg"]
	
	# Assign specific SFX and volume from army_data
	if "sfx_attack" in data: enemy.sfx_attack = data["sfx_attack"]
	if "sfx_hit" in data: enemy.sfx_hit = data["sfx_hit"]
	if "sfx_death" in data: enemy.sfx_death = data["sfx_death"]
	
	enemy.sfx_vol_attack = data.get("vol_attack", 0.0) + global_enemy_sfx_volume
	enemy.sfx_vol_hit = data.get("vol_hit", 0.0) + global_enemy_sfx_volume
	enemy.sfx_vol_death = data.get("vol_death", 0.0) + global_enemy_sfx_volume
	
	player.base_damage = data["player_dmg"]
	ui.update_enemy_hp(enemy.current_health, enemy.max_health, enemy.enemy_name)
	ui.update_player_hp(player.current_health, player.max_health)
	update_background_visibility()

func _process(delta: float) -> void:
	if not is_active:
		return
		
	var capped_delta = min(delta, 0.1)
	timer -= capped_delta
	ui.update_timer(timer, current_question["time"])
	
	if timer <= 0 and not is_transitioning:
		var last_second_input: String = ui.get_current_input_text()
		if last_second_input != "" and last_second_input == current_question["answer"]:
			ui.clear_input()
			handle_correct_answer()
		else:
			ui.clear_input()
			handle_wrong_answer()

func next_question() -> void:
	if is_transitioning: return 
	
	current_question = math_manager.generate_question(current_difficulty)
	timer = current_question["time"]
	ui.update_question(current_question["question"])
	ui.update_timer(timer, current_question["time"])
	
	var curse_text: String = ""
	if current_question.has("curse") and current_question["curse"] != "":
		curse_text = "CURSE RISK: " + current_question["curse"]
	ui.update_curse(curse_text)

func _on_answer_submitted(answer: String) -> void:
	if not is_active or is_transitioning or answer == "":
		return
		
	if answer == current_question["answer"]:
		handle_correct_answer()
	else:
		handle_wrong_answer()

func handle_correct_answer() -> void:
	player.play_attack()
	enemy.take_damage(player.get_damage())
	
	if enemy.current_health > 0:
		ui.show_message("Correct!")
		if not is_transitioning:
			next_question()

func handle_wrong_answer() -> void:
	var dmg: int = enemy.get_damage()
	enemy.play_attack()
	
	player.take_damage(dmg)
	ui.show_message("-" + str(dmg) + " HP")
	
	if current_question.has("curse") and current_question["curse"] != "":
		apply_curse_to_player(current_question["curse"])
	
	player.process_curse_turn()
	enemy.process_curse_turn()
	
	if player.current_health > 0:
		next_question()
	else:
		game_over()

func apply_curse_to_player(curse: String) -> void:
	match curse:
		"POISON":
			player.apply_poison()
			ui.show_message("CURSE triggered: You are Poisoned!")
		"DAMAGE REDUCTION":
			player.apply_damage_debuff()
			ui.show_message("CURSE triggered: Your Damage Reduced!")

func _on_enemy_health_changed(hp: int, max_hp: int) -> void:
	ui.update_enemy_hp(hp, max_hp, enemy.enemy_name)
	if hp <= 0 and is_active:
		handle_enemy_defeat()

func handle_enemy_defeat() -> void:
	is_active = false
	is_transitioning = true
	ui.is_battle_active = false
	
	timer = 0.0
	
	var health_pct: float = (float(player.current_health) / float(player.max_health)) * 100.0
	var round_feedback: String = ""
	
	if health_pct >= 100.0:
		round_feedback = "Flawless victory! 👌"
	elif health_pct >= 80.0:
		round_feedback = "Great job! 🔥"
	elif health_pct >= 50.0:
		round_feedback = "Stay focused! ⚔️"
	elif health_pct >= 25.0:
		round_feedback = "Careful now! ⚠️"
	else:
		round_feedback = "Hanging by a thread! 💀"
	
	if current_difficulty < MathManager.Difficulty.BOSS:
		ui.clear_transition_ui()
		ui.clear_input()
		current_difficulty = (current_difficulty + 1) as MathManager.Difficulty
		
		ui.show_intermission_congratulations(round_feedback + "\nStage Cleared!")
		await get_tree().create_timer(4.0).timeout
		
		# Play cutscene after every encounter except the final boss
		await play_cutscene()
			
		start_battle()
	else:
		# Delay the victory screen so the boss death animation can be seen
		await get_tree().create_timer(5.0).timeout
		ui.clear_transition_ui()
		ui.clear_input()
		ui.show_final_victory_screen()
		await get_tree().create_timer(3.0).timeout
		ui.show_retry_button()

func update_background_visibility() -> void:
	for i in range(backgrounds.size()):
		if backgrounds[i]:
			backgrounds[i].visible = (i == int(current_difficulty))

func play_cutscene() -> void:
	print("Starting cutscene sequence...")
	is_transitioning = true
	
	# Reference nodes from the current node (Main/CombatManager)
	var background = get_node_or_null("Background")
	var canvas_layer = get_node_or_null("CanvasLayer")
	var main_camera = get_node_or_null("Camera2D")
	
	# Hide gameplay elements
	if background: background.hide()
	if canvas_layer: canvas_layer.hide()
	if player: player.hide()
	if enemy: enemy.hide()
	
	# Instance and setup cutscene
	var cutscene_path: String = "res://scenes/cutscene.tscn"
	if not FileAccess.file_exists(cutscene_path):
		print("Error: Cutscene file not found at ", cutscene_path)
		_finish_cutscene()
		return
		
	var cutscene_scene = load(cutscene_path)
	var cutscene_instance = cutscene_scene.instantiate()
	cutscene_instance.hide() # Hide initially to prevent flashes
	add_child(cutscene_instance)
	
	var cutscene_camera: Camera2D = cutscene_instance.get_node_or_null("Camera2D")
	var anim_player: AnimationPlayer = cutscene_instance.get_node_or_null("AnimationPlayer2")
	
	if cutscene_camera:
		cutscene_camera.make_current()
	
	if anim_player:
		var anim_name: String = "encounter"
		match current_difficulty:
			MathManager.Difficulty.ARMY2:
				anim_name = "encounter"
			MathManager.Difficulty.ARMY3:
				anim_name = "encounter_2"
			MathManager.Difficulty.BOSS:
				anim_name = "encounter_3"
		
		print("Playing cutscene animation: ", anim_name)
		anim_player.play(anim_name)
		anim_player.advance(0) # Force update to first frame
		cutscene_instance.show()
		# Wait for animation to finish
		await anim_player.animation_finished
	else:
		print("Warning: No AnimationPlayer2 found in cutscene")
		await get_tree().create_timer(3.0).timeout
	
	# Cleanup
	if cutscene_instance:
		cutscene_instance.queue_free()
	
	# Restore gameplay
	if main_camera:
		main_camera.make_current()
	
	_finish_cutscene()
	print("Cutscene sequence finished.")

func _finish_cutscene() -> void:
	var background = get_node_or_null("Background")
	var canvas_layer = get_node_or_null("CanvasLayer")
	
	if background: background.show()
	if canvas_layer: canvas_layer.show()
	if player: player.show()
	if enemy: enemy.show()
	
	if ui:
		ui.restore_ui_visibility()
	
	is_transitioning = false

func game_over() -> void:
	is_active = false
	is_transitioning = true
	ui.is_battle_active = false
	timer = 0.0
	ui.clear_transition_ui()
	ui.clear_input()

	
	player.is_active = false
	player.play_death()
	
	# Delay the blackout so we see the death animation fully
	await get_tree().create_timer(4.0).timeout
	ui.show_final_defeat_screen()
	
	await get_tree().create_timer(1.0).timeout
	ui.show_retry_button()

func reset_entire_game() -> void:
	is_active = false
	is_transitioning = false
	ui.is_battle_active = false
	timer = 0.0
	
	current_difficulty = MathManager.Difficulty.ARMY1
	
	ui.clear_input()
	ui.clear_transition_ui()
	ui.restore_ui_visibility()
	
	player.reset_properties()
	enemy.reset_properties()
	
	start_battle()

# --- ADMIN MODE INLINE LOGIC ---

func create_admin_panel() -> void:
	var admin_box := VBoxContainer.new()
	admin_box.custom_minimum_size = Vector2(180, 0)
	admin_box.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	admin_box.alignment = BoxContainer.ALIGNMENT_CENTER
	admin_box.theme_type_variation = "VBoxContainer"
	$CanvasLayer.add_child(admin_box)
	
	var layout_data = [
		{"label": "Go to enemy 1", "call": func(): admin_change_stage(MathManager.Difficulty.ARMY1)},
		{"label": "Go to enemy 2", "call": func(): admin_change_stage(MathManager.Difficulty.ARMY2)},
		{"label": "Go to enemy 3", "call": func(): admin_change_stage(MathManager.Difficulty.ARMY3)},
		{"label": "Go to Boss", "call": func(): admin_change_stage(MathManager.Difficulty.BOSS)},
		{"label": "trigger poison curse", "call": func(): apply_curse_to_player("POISON")},
		{"label": "trigger damage reduction curse", "call": func(): apply_curse_to_player("DAMAGE REDUCTION")},
		{"label": "trigger flicker curse", "call": func(): ui.admin_trigger_flicker()},
		{"label": "reset curse", "call": func(): admin_reset_curses()},
		{"label": "heal", "call": func(): admin_heal_player()}
	]
	
	for structure in layout_data:
		var btn := Button.new()
		btn.text = structure["label"]
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		btn.pressed.connect(structure["call"])
		admin_box.add_child(btn)

func admin_change_stage(diff: MathManager.Difficulty) -> void:
	current_difficulty = diff
	is_active = false
	start_battle()
	ui.show_message("Warped Target Stage!")

func admin_reset_curses() -> void:
	if player:
		player.poison_ticks = 0
		player.damage_modifier = 0
	if ui:
		ui.is_glitch_curse_active = false
		ui.clear_transition_ui()
		ui.show_message("All Curses Cleared!")

func admin_heal_player() -> void:
	if player and ui:
		player.current_health = player.max_health
		player.health_changed.emit(player.current_health, player.max_health)
		ui.show_message("Health Restored!")
