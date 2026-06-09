extends Control

signal answer_submitted(answer: String)
signal retry_requested()

@onready var main_vbox: VBoxContainer = $CenterContainer/VBox
@onready var question_label: Label = $CenterContainer/VBox/QuestionLabel
@onready var timer_label: Label = $CenterContainer/VBox/TimerLabel
@onready var input_edit: LineEdit = $CenterContainer/VBox/AnswerInput
@onready var timer_bar: ProgressBar = $CenterContainer/VBox/TimerBar
@onready var player_hp_bar: ProgressBar = $PlayerHP
@onready var enemy_hp_bar: ProgressBar = $EnemyHP
@onready var status_label: Label = $StatusLabel
@onready var curse_label: Label = $CenterContainer/VBox/CurseLabel
@onready var retry_button: Button = $CenterContainer/VBox/RetryButton
@onready var blackout_overlay: ColorRect = $BlackoutOverlay

var typing_timer: float = 0.0
var typing_delay: float = 0.75 
var is_battle_active: bool = false

var is_glitch_curse_active: bool = false
var glitch_timer: float = 0.0
var glitch_visible: bool = true

var msg_tween: Tween

func _ready() -> void:
	input_edit.placeholder_text = "TYPE YOUR ANSWER..."
	input_edit.clear_button_enabled = false
	input_edit.text_changed.connect(_on_text_changed)
	
	if blackout_overlay:
		blackout_overlay.hide()
		blackout_overlay.modulate.a = 0.0
	
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)
		retry_button.hide()
	
	for child in get_all_children(self):
		if child is Control and child != input_edit and child != retry_button:
			child.focus_mode = Control.FOCUS_NONE
			child.mouse_filter = Control.MOUSE_FILTER_PASS
	
	input_edit.focus_mode = Control.FOCUS_ALL
	_create_hp_label(player_hp_bar)
	_create_hp_label(enemy_hp_bar)
	call_deferred("grab_input_focus")

# Intercepts and destroys any Enter key presses so they don't impact focus or gameplay
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			get_viewport().set_input_as_handled() # Absorb the input completely

func _create_hp_label(bar: ProgressBar) -> void:
	var label: Label = Label.new()
	label.name = "HPText"
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	bar.add_child(label)

func get_all_children(node: Node) -> Array:
	var nodes: Array = []
	for child in node.get_children():
		nodes.append(child)
		if child.get_child_count() > 0:
			nodes.append_array(get_all_children(child))
	return nodes

func grab_input_focus() -> void:
	if retry_button and retry_button.visible:
		return
	if is_battle_active and is_visible_in_tree() and is_inside_tree():
		input_edit.editable = true
		input_edit.grab_focus()
		input_edit.caret_column = input_edit.text.length()

func update_question(text: String) -> void:
	main_vbox.show()
	
	status_label.remove_theme_color_override("font_color")
	status_label.remove_theme_font_size_override("font_size")
	status_label.set_anchors_preset(Control.PRESET_CENTER)
	
	question_label.text = text
	input_edit.clear()
	typing_timer = 0.0
	
	is_glitch_curse_active = randf() < 0.05
	glitch_timer = 0.0
	glitch_visible = true
	question_label.show()
	question_label.modulate.a = 1.0
	call_deferred("grab_input_focus")

func _on_text_changed(_new_text: String) -> void:
	typing_timer = 0.0

func _process(delta: float) -> void:
	if not is_battle_active:
		input_edit.editable = false
		return
	
	if is_visible_in_tree() and is_inside_tree():
		if retry_button and retry_button.visible:
			input_edit.editable = false
			return
			
		if get_viewport().gui_get_focus_owner() != input_edit:
			input_edit.grab_focus()
		
		if is_glitch_curse_active:
			glitch_timer += delta
			if glitch_timer >= 1.0:
				glitch_timer = 0.0
				glitch_visible = not glitch_visible
				question_label.modulate.a = 1.0 if glitch_visible else 0.0
		
		var clean_text = input_edit.text.strip_edges()
		if clean_text.length() > 0:
			typing_timer += delta
			if typing_timer >= typing_delay:
				_submit_answer()
		else:
			typing_timer = 0.0

func _submit_answer() -> void:
	var answer: String = input_edit.text.strip_edges()
	if answer != "":
		answer_submitted.emit(answer)
		input_edit.clear()
		typing_timer = 0.0
		call_deferred("grab_input_focus")

func get_current_input_text() -> String:
	return input_edit.text.strip_edges()

func clear_input() -> void:
	input_edit.text = ""
	input_edit.clear()
	typing_timer = 0.0

func clear_transition_ui() -> void:
	question_label.text = ""
	question_label.modulate.a = 1.0
	curse_label.text = ""
	timer_label.text = "0.0"
	timer_bar.value = 0
	is_glitch_curse_active = false

func update_timer(current: float, total: float) -> void:
	var display_time: float = max(0.0, current)
	timer_label.text = "%0.1f" % display_time
	timer_bar.max_value = total
	timer_bar.value = display_time

func update_curse(text: String) -> void:
	var display_text: String = text
	
	if is_glitch_curse_active:
		if display_text != "":
			display_text += " | Flicker Curse!😂"
		else:
			display_text = "Flicker Curse!😂"

	if curse_label:
		curse_label.text = display_text
		if display_text != "":
			curse_label.modulate = Color.WHITE
		else:
			curse_label.modulate = Color.WHITE

func update_player_hp(current: int, max_val: int) -> void:
	player_hp_bar.max_value = max_val
	player_hp_bar.value = current
	player_hp_bar.show_percentage = false
	if player_hp_bar.has_node("HPText"):
		player_hp_bar.get_node("HPText").text = str(current) + " / " + str(max_val)

func update_enemy_hp(current: int, max_val: int, _name_str: String) -> void:
	enemy_hp_bar.max_value = max_val
	enemy_hp_bar.value = current
	enemy_hp_bar.show_percentage = false
	if enemy_hp_bar.has_node("HPText"):
		enemy_hp_bar.get_node("HPText").text = str(current) + " / " + str(max_val)

func show_message(text: String) -> void:
	if msg_tween and msg_tween.is_valid():
		msg_tween.kill()
		
	status_label.text = text
	status_label.add_theme_font_size_override("font_size", 28)
	
	if "Correct" in text:
		status_label.add_theme_color_override("font_color", Color.GREEN)
	elif "Wrong" in text or "Timed out" in text:
		status_label.add_theme_color_override("font_color", Color.RED)
	else:
		status_label.add_theme_color_override("font_color", Color.WHITE)
		
	status_label.set_anchors_preset(Control.PRESET_CENTER)
	status_label.modulate.a = 1.0 
	status_label.show() 
	
	msg_tween = create_tween()
	msg_tween.tween_property(status_label, "modulate:a", 0.0, 1.2).set_delay(1.0)
	msg_tween.tween_callback(status_label.hide)

func show_intermission_congratulations(feedback_text: String) -> void:
	if msg_tween and msg_tween.is_valid():
		msg_tween.kill()
	
	main_vbox.hide()
	
	status_label.text = feedback_text
	status_label.add_theme_color_override("font_color", Color.GREEN)
	status_label.add_theme_font_size_override("font_size", 36)
	status_label.set_anchors_preset(Control.PRESET_CENTER)
	status_label.modulate.a = 1.0
	status_label.show()

func show_final_victory_screen() -> void:
	if msg_tween and msg_tween.is_valid():
		msg_tween.kill()
		
	main_vbox.hide()
	blackout_overlay.show()
	
	var fade_tween = create_tween()
	fade_tween.tween_property(blackout_overlay, "modulate:a", 1.0, 0.8)
	
	status_label.text = "Victory!"
	status_label.add_theme_color_override("font_color", Color.WHITE)
	status_label.add_theme_font_size_override("font_size", 48)
	status_label.set_anchors_preset(Control.PRESET_CENTER)
	status_label.modulate.a = 1.0
	status_label.show()

func show_final_defeat_screen() -> void:
	if msg_tween and msg_tween.is_valid():
		msg_tween.kill()
		
	main_vbox.hide()
	blackout_overlay.show()
	
	var fade_tween = create_tween()
	fade_tween.tween_property(blackout_overlay, "modulate:a", 1.0, 0.8)
	
	status_label.text = "Defeat..."
	status_label.add_theme_color_override("font_color", Color.RED)
	status_label.add_theme_font_size_override("font_size", 48)
	status_label.set_anchors_preset(Control.PRESET_CENTER)
	status_label.modulate.a = 1.0
	status_label.show()

func show_retry_button() -> void:
	if retry_button:
		main_vbox.show()
		question_label.hide()
		timer_label.hide()
		timer_bar.hide()
		curse_label.hide()
		input_edit.hide()
		
		retry_button.show()
		retry_button.focus_mode = Control.FOCUS_ALL
		retry_button.grab_focus()

func restore_ui_visibility() -> void:
	main_vbox.show()
	question_label.show()
	question_label.modulate.a = 1.0
	timer_label.show()
	timer_bar.show()
	curse_label.show()
	input_edit.show()
	status_label.hide()
	if blackout_overlay:
		blackout_overlay.hide()
		blackout_overlay.modulate.a = 0.0

func _on_retry_pressed() -> void:
	clear_input()
	retry_button.hide()
	restore_ui_visibility()
	retry_requested.emit()
	SoundManager.play_bgm(SoundManager.BGM_VILLAGE,-10,0.5)
