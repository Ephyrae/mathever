#include "math_manager.h"
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/expression.hpp>
#include <godot_cpp/variant/array.hpp>

using namespace godot;

void MathManager::_bind_methods() {
    BIND_ENUM_CONSTANT(ARMY1);
    BIND_ENUM_CONSTANT(ARMY2);
    BIND_ENUM_CONSTANT(ARMY3);
    BIND_ENUM_CONSTANT(BOSS);

    ClassDB::bind_method(D_METHOD("generate_question", "difficulty"), &MathManager::generate_question);
}

MathManager::MathManager() {}
MathManager::~MathManager() {}

Dictionary MathManager::generate_question(Difficulty p_difficulty) {
    switch (p_difficulty) {
        case ARMY1: return _generate_army1();
        case ARMY2: return _generate_army2();
        case ARMY3: return _generate_army3();
        case BOSS:  return _generate_boss();
    }
    return Dictionary();
}

Dictionary MathManager::_generate_army1() {
    Array ops;
    ops.append("+"); ops.append("-"); ops.append("*"); ops.append("/");
    String op = ops[UtilityFunctions::randi() % ops.size()];

    int a = 0, b = 0, answer = 0;
    String question = "";

    if (op == "+") {
        a = UtilityFunctions::randi_range(1, 20);
        b = UtilityFunctions::randi_range(1, 20);
        question = String::num_int64(a) + " + " + String::num_int64(b);
        answer = a + b;
    } else if (op == "-") {
        a = UtilityFunctions::randi_range(1, 20);
        b = UtilityFunctions::randi_range(1, a);
        question = String::num_int64(a) + " - " + String::num_int64(b);
        answer = a - b;
    } else if (op == "*") {
        a = UtilityFunctions::randi_range(1, 9);
        b = UtilityFunctions::randi_range(1, 9);
        question = String::num_int64(a) + " * " + String::num_int64(b);
        answer = a * b;
    } else if (op == "/") {
        b = UtilityFunctions::randi_range(1, 9);
        answer = UtilityFunctions::randi_range(1, 9);
        a = b * answer;
        question = String::num_int64(a) + " / " + String::num_int64(b);
    }

    Dictionary res;
    res["question"] = question;
    res["answer"] = String::num_int64(answer);
    res["time"] = 5.0;
    res["curse"] = _get_random_curse(0.10);
    return res;
}

Dictionary MathManager::_generate_army2() {
    int a = UtilityFunctions::randi_range(1, 9);
    int b = UtilityFunctions::randi_range(1, 9);
    int c = UtilityFunctions::randi_range(1, 9);

    Array ops; ops.append("+"); ops.append("-"); ops.append("*");
    String op1 = ops[UtilityFunctions::randi() % ops.size()];
    String op2 = ops[UtilityFunctions::randi() % ops.size()];

    String expression_str = String::num_int64(a) + " " + op1 + " " + String::num_int64(b) + " " + op2 + " " + String::num_int64(c);

    Ref<Expression> expr;
    expr.instantiate();
    Error err = expr->parse(expression_str);

    if (err != OK) return _generate_army2();

    Variant result = expr->execute();
    int int_result = result;

    if (int_result < 0) return _generate_army2();

    Dictionary res;
    res["question"] = expression_str;
    res["answer"] = String::num_int64(int_result);
    res["time"] = 10.0;
    res["curse"] = _get_random_curse(0.10);
    return res;
}

Dictionary MathManager::_generate_army3() {
    int type = UtilityFunctions::randi() % 3;
    String question = "";
    int answer = 0;

    if (type == 0) {
        int x = UtilityFunctions::randi_range(1, 9);
        int a = UtilityFunctions::randi_range(2, 9);
        int b = UtilityFunctions::randi_range(1, 15);
        int c = (a * x) + b;
        question = String::num_int64(a) + "x + " + String::num_int64(b) + " = " + String::num_int64(c) + ", x = ?";
        answer = x;
    } else if (type == 1) {
        int x = UtilityFunctions::randi_range(2, 9);
        int a = UtilityFunctions::randi_range(2, 9);
        int b = UtilityFunctions::randi_range(1, 15);
        int c = (a * x) - b;
        if (c < 0) return _generate_army3();
        question = String::num_int64(a) + "x - " + String::num_int64(b) + " = " + String::num_int64(c) + ", x = ?" ;
        answer = x;
    } else if (type == 2) {
        int x = UtilityFunctions::randi_range(1, 6);
        int a = UtilityFunctions::randi_range(2, 8);
        int b = UtilityFunctions::randi_range(5, 25);
        question = "x = " + String::num_int64(x) + ", " + String::num_int64(a) + "x + " + String::num_int64(b) + " = ?";
        answer = (a * x) + b;
    }

    Dictionary res;
    res["question"] = question;
    res["answer"] = String::num_int64(answer);
    res["time"] = 15.0;
    res["curse"] = _get_random_curse(0.10);
    return res;
}

Dictionary MathManager::_generate_boss() {
    int type = UtilityFunctions::randi() % 2;
    String question = "";
    int answer = 0;

    if (type == 0) {
        int x = UtilityFunctions::randi_range(1, 5);
        int y = UtilityFunctions::randi_range(1, 5);
        int a = UtilityFunctions::randi_range(2, 6);
        int b = UtilityFunctions::randi_range(2, 6);
        int c = UtilityFunctions::randi_range(1, 10);

        answer = (a * x) + (b * y) - c;
        if (answer < 0) return _generate_boss();

        question = "x=" + String::num_int64(x) + ", y=" + String::num_int64(y) + ". " + String::num_int64(a) + "x + " + String::num_int64(b) + "y - " + String::num_int64(c) + " = ?";
    } else if (type == 1) {
        int x = UtilityFunctions::randi_range(1, 6);
        int a = UtilityFunctions::randi_range(2, 5);
        int b = UtilityFunctions::randi_range(1, 5);
        int c = UtilityFunctions::randi_range(1, 10);

        int d = a * (x + b) - c;
        if (d < 0) return _generate_boss();

        question = String::num_int64(a) + "(x + " + String::num_int64(b) + ") - " + String::num_int64(c) + " = " + String::num_int64(d) + ", x = ?";
        answer = x;
    }

    Dictionary res;
    res["question"] = question;
    res["answer"] = String::num_int64(answer);
    res["time"] = 20.0;
    res["curse"] = _get_random_curse(0.15);
    return res;
}

String MathManager::_get_random_curse(double p_chance) {
    if (UtilityFunctions::randf() > p_chance) {
        return "";
    }
    Array curses;
    curses.append("POISON");
    curses.append("DAMAGE REDUCTION");
    return curses[UtilityFunctions::randi() % curses.size()];
}