#ifndef MATH_MANAGER_H
#define MATH_MANAGER_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

class MathManager : public Node {
    GDCLASS(MathManager, Node);

protected:
    static void _bind_methods();

public:
    MathManager();
    ~MathManager();

    enum Difficulty { ARMY1, ARMY2, ARMY3, BOSS };

    Dictionary generate_question(Difficulty p_difficulty);

private:
    Dictionary _generate_army1();
    Dictionary _generate_army2();
    Dictionary _generate_army3();
    Dictionary _generate_boss();
    String _get_random_curse(double p_chance);
};

} // namespace godot

VARIANT_ENUM_CAST(MathManager::Difficulty);

#endif // MATH_MANAGER_H