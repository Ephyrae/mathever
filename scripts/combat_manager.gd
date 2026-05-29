extends Node2D
class_name CombatManager

@onready var math_manager: MathManager = $MathManager
@onready var player: Player = $Player
@onready var enemy: Enemy = $Enemy
@onready var ui: Control = $CanvasLayer/BattleUI

var current_difficulty: MathManager.Difficulty = MathManager.Difficulty.ARMY1
var current_question: Dictionary = {}
var timer: float = 0.0
var is_active: bool = false
var is_transitioning: bool = false

var army_data: Dictionary = {
	MathManager.Difficulty.ARMY1: {
		"hp": 40,
		"name": "Army 1",
		"texture": preload("res://assets/generated/enemy_army_1_frame_0.png"),
		"player_dmg": 10,
		"enemy_dmg": 8
	},
	MathManager.Difficulty.ARMY2: {
		"hp": 60,
		"name": "Army 2",
		"texture": preload("res://assets/generated/enemy_army_2_frame_0.png"),
		"player_dmg": 10,
		"enemy_dmg": 12
	},
	MathManager.Difficulty.ARMY3: {
		"hp": 70,
		"name": "Army 3",
		"texture": preload("res://assets/generated/enemy_boss_frame_0.png"),
		"player_dmg": 14,
		"enemy_dmg": 16
	},
	MathManager.Difficulty.BOSS: {
		"hp": 100,
		"name": "The Boss",
		"texture": preload("res://art/tile_0121.png"),
		"player_dmg": 20,
		"enemy_dmg": 24
	}
}

func _ready() -> void:
	ui.answer_submitted.connect(_on_answer_submitted)
	ui.retry_requested.connect(reset_entire_game)
	player.health_changed.connect(ui.update_player_hp)
	enemy.health_changed.connect(_on_enemy_health_changed)
	
	start_battle()

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
	player.base_damage = data["player_dmg"]
	ui.update_enemy_hp(enemy.current_health, enemy.max_health, enemy.enemy_name)
	ui.update_player_hp(player.current_health, player.max_health)

func _process(delta: float) -> void:
	if not is_active or is_transitioning:
		return
		
	var capped_delta = min(delta, 0.1)
	timer -= capped_delta
	ui.update_timer(timer, current_question["time"])
	
	if timer <= 0:
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
	player.take_damage(dmg)
	ui.show_message("Wrong or Timed out! -" + str(dmg) + " HP")
	
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
	ui.clear_transition_ui()
	ui.clear_input()
	
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
		current_difficulty = (current_difficulty + 1) as MathManager.Difficulty
		
		ui.show_intermission_congratulations(round_feedback + "\nStage Cleared!")
		await get_tree().create_timer(3.0).timeout
		
		start_battle()
	else:
		ui.show_final_victory_screen()
		await get_tree().create_timer(3.0).timeout
		ui.show_retry_button()

func game_over() -> void:
	is_active = false
	is_transitioning = true
	ui.is_battle_active = false
	timer = 0.0
	ui.clear_transition_ui()
	ui.clear_input()
	
	ui.show_final_defeat_screen()
	await get_tree().create_timer(1.5).timeout
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
