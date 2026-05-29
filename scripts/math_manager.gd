extends Node
class_name MathManager

enum Difficulty { ARMY1, ARMY2, ARMY3, BOSS }

func generate_question(difficulty: Difficulty) -> Dictionary:
	match difficulty:
		Difficulty.ARMY1:
			return _generate_army1(difficulty)
		Difficulty.ARMY2:
			return _generate_army2(difficulty)
		Difficulty.ARMY3:
			return _generate_army3(difficulty)
		Difficulty.BOSS:
			return _generate_boss(difficulty)
	return {}

func _generate_army1(_diff: Difficulty) -> Dictionary:
	var ops: Array = ["+", "-", "*", "/"]
	var op: String = ops[randi() % ops.size()]
	var a: int
	var b: int
	var question: String
	var answer: int

	match op:
		"+":
			a = randi_range(1, 20)
			b = randi_range(1, 20)
			question = str(a) + " + " + str(b)
			answer = a + b
		"-":
			a = randi_range(1, 20)
			b = randi_range(1, a)
			question = str(a) + " - " + str(b)
			answer = a - b
		"*":
			a = randi_range(1, 9)
			b = randi_range(1, 9)
			question = str(a) + " * " + str(b)
			answer = a * b
		"/":
			b = randi_range(1, 9)
			answer = randi_range(1, 9)
			a = b * answer
			question = str(a) + " / " + str(b)
	
	return {"question": question, "answer": str(answer), "time": 5.0, "curse": _get_random_curse(0.10)}

func _generate_army2(_diff: Difficulty) -> Dictionary:
	var a: int = randi_range(1, 9)
	var b: int = randi_range(1, 9)
	var c: int = randi_range(1, 9)
	
	var ops: Array = ["+", "-", "*"]
	var op1: String = ops[randi() % ops.size()]
	var op2: String = ops[randi() % ops.size()]
	
	var expression: String = str(a) + " " + op1 + " " + str(b) + " " + op2 + " " + str(c)
	var expression_obj: Expression = Expression.new()
	var error: Error = expression_obj.parse(expression)
	
	if error != OK:
		return _generate_army2(_diff)
	
	var result: Variant = expression_obj.execute()
	if typeof(result) != TYPE_INT and typeof(result) != TYPE_FLOAT:
		return _generate_army2(_diff)
	
	if int(result) < 0:
		return _generate_army2(_diff)
		
	return {"question": expression, "answer": str(int(result)), "time": 10.0, "curse": _get_random_curse(0.10)}

func _generate_army3(_diff: Difficulty) -> Dictionary:
	var type: int = randi() % 3
	var question: String = ""
	var answer: int = 0
	
	match type:
		0:
			var x: int = randi_range(1, 9)
			var a: int = randi_range(2, 9)
			var b: int = randi_range(1, 15)
			var c: int = (a * x) + b
			question = str(a) + "x + " + str(b) + " = " + str(c) + ", x = ?"
			answer = x
		1:
			var x: int = randi_range(2, 9)
			var a: int = randi_range(2, 9)
			var b: int = randi_range(1, 15)
			var c: int = (a * x) - b
			if c < 0: 
				return _generate_army3(_diff)
			question = str(a) + "x - " + str(b) + " = " + str(c) + ", x = ?"
			answer = x
		2:
			var x: int = randi_range(1, 6)
			var a: int = randi_range(2, 8)
			var b: int = randi_range(5, 25)
			question = "x = " + str(x) + ", " + str(a) + "x + " + str(b) + " = ?"
			answer = (a * x) + b

	return {"question": question, "answer": str(answer), "time": 15.0, "curse": _get_random_curse(0.10)}

func _generate_boss(_diff: Difficulty) -> Dictionary:
	var type: int = randi() % 2
	var question: String = ""
	var answer: int = 0
	
	match type:
		0:
			var x: int = randi_range(1, 5)
			var y: int = randi_range(1, 5)
			var a: int = randi_range(2, 6)
			var b: int = randi_range(2, 6)
			var c: int = randi_range(1, 10)
			
			answer = (a * x) + (b * y) - c
			if answer < 0:
				return _generate_boss(_diff)
				
			question = "x=" + str(x) + ", y=" + str(y) + ". " + str(a) + "x + " + str(b) + "y - " + str(c) + " = ?"
		1:
			var x: int = randi_range(1, 6)
			var a: int = randi_range(2, 5)
			var b: int = randi_range(1, 5)
			var c: int = randi_range(1, 10)
			
			var d: int = a * (x + b) - c
			if d < 0:
				return _generate_boss(_diff)
				
			question = str(a) + "(x + " + str(b) + ") - " + str(c) + " = " + str(d) + ", x = ?"
			answer = x

	return {"question": question, "answer": str(answer), "time": 20.0, "curse": _get_random_curse(0.15)}

func _get_random_curse(chance: float) -> String:
	if randf() > chance:
		return ""
	var curses: Array = ["POISON", "DAMAGE REDUCTION"]
	return curses[randi() % curses.size()]
