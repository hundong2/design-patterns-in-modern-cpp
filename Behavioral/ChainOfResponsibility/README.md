# Chain of Responsibility Pattern

The Chain of Responsibility pattern is a behavioral design pattern that lets you pass requests along a chain of handlers. Upon receiving a request, each handler decides either to process the request or to pass it to the next handler in the chain.

This allows for loose coupling between the sender of a request and its receivers. Multiple handlers can be given a chance to process a request.

## C++ Code Examples

Below are the C++ source files demonstrating different aspects or implementations of the Chain of Responsibility pattern.

### `CoRCodingExercise.cpp`

This file seems to implement a game scenario where creature statistics (like attack and defense) are modified by a chain of effects or other creatures in the game.

```cpp
#include <iostream>
#include <vector>
using namespace std;

struct Creature;
struct Game
{
  vector<Creature*> creatures;
};

struct StatQuery
{
  enum Statistic { attack, defense } statistic;
  int result;
};

struct Creature
{
protected:
  Game& game;
  int base_attack, base_defense;

public:
  Creature(Game &game, int base_attack, int base_defense) : game(game), base_attack(base_attack),
                                                            base_defense(base_defense) {}

  virtual int get_attack() = 0;
  virtual int get_defense() = 0;
  virtual void query(void* source, StatQuery& sq) = 0;
};

class Goblin : public Creature
{
  int get_statistic(StatQuery::Statistic stat)
  {
    StatQuery q{stat,0};
    for (auto c : game.creatures)
      c->query(this, q);
    return q.result;
  }
public:
  Goblin(Game &game, int base_attack, int base_defense) : Creature(game, base_attack, base_defense) {}

  Goblin(Game &game) : Creature(game, 1, 1) {}

  int get_attack() override {
    return get_statistic(StatQuery::attack);
  }

  int get_defense() override {
    return get_statistic(StatQuery::defense);
  }

  void query(void *source, StatQuery &sq) override {
    if (source == this)
    {
      switch (sq.statistic)
      {
        case StatQuery::attack:
          sq.result += base_attack;
          break;
        case StatQuery::defense:
          sq.result += base_defense;
          break;
      }
    } else
    {
      if (sq.statistic == StatQuery::defense)
      {
        sq.result++;
      }
    }
  }
};

class GoblinKing : public Goblin
{
public:
  GoblinKing(Game &game) : Goblin(game, 3, 3) {}

  void query(void *source, StatQuery &sq) override {
    if (source != this && sq.statistic == StatQuery::attack)
    {
      sq.result++;
    }
    else Goblin::query(source, sq);
  }
};

#include "gtest/gtest.h"

//#include "helpers/iohelper.h"

//#include "exercise.cpp"

namespace
{
  class Evaluate : public testing::Test
  {
  public:
  };

  TEST_F(Evaluate, ManyGoblinsTest)
  {
    Game game;
    Goblin goblin{game};
    game.creatures.push_back(&goblin);

    cout << "Checking that a baseline goblin is a 1/1...\n";

    ASSERT_EQ(1, goblin.get_attack());
    ASSERT_EQ(1, goblin.get_defense());

    cout << "Adding a second goblin, now they should be 1/2...\n";
    Goblin goblin2{game};
    game.creatures.push_back(&goblin2);

    ASSERT_EQ(1, goblin.get_attack());
    ASSERT_EQ(2, goblin.get_defense());

    cout << "Adding a goblin king, now a goblin should be 2/3...\n";
    GoblinKing goblin3{game};
    game.creatures.push_back(&goblin3);

    ASSERT_EQ(2, goblin.get_attack());
    ASSERT_EQ(3, goblin.get_defense());
  }

} // namespace

int main(int ac, char* av[])
{
  testing::InitGoogleTest(&ac, av);
  return RUN_ALL_TESTS();
}
```

### `cor_broker.cpp`

This file demonstrates the Chain of Responsibility pattern using a "broker" or "mediator" (Game object with signals) to dispatch queries to modifiers. Modifiers subscribe to events and change query results.

```cpp
#include <iostream>
#include <string>
using namespace std;
#include <boost/signals2.hpp>
using namespace boost::signals2;


struct Query
{
  string creature_name;
  enum Argument { attack, defense } argument;
  int result;


  Query(const string& creature_name, const Argument argument, const int result)
    : creature_name(creature_name),
      argument(argument),
      result(result)
  {
  }
};

struct Game // 매게자
{
  signal<void(Query&)> queries;
};

class Creature
{
  Game& game;
  int attack, defense;
public:
  string name;
  Creature(Game& game, const string& name, const int attack, const int defense)
    : game(game),
      attack(attack),
      defense(defense),
      name(name)
  {
  }

  // 버추얼 메소드일 필요는 없다
  int GetAttack() const
  {
    Query q{ name, Query::Argument::attack, attack };
    game.queries(q);
    return q.result;
  }

  friend ostream& operator<<(ostream& os, const Creature& obj)
  {
    return os
      << "name: " << obj.name
      << " attack: " << obj.GetAttack() // note here
      << " defense: " << obj.defense;
  }
};

class CreatureModifier
{
  Game& game;
  Creature& creature;
public:
  virtual ~CreatureModifier() = default;

  // handle() 함수는 없다.

  CreatureModifier(Game& game, Creature& creature)
    : game(game),
      creature(creature)
  {
  }
};

class DoubleAttackModifier : public CreatureModifier
{
  connection conn;
public:
  DoubleAttackModifier(Game& game, Creature& creature)
    : CreatureModifier(game, creature)
  {
    // 이 크리쳐의 공격력 값을 참조하려 하면
    // 원래 값의 두 배를 리턴한다.
    conn = game.queries.connect([&](Query& q)
    {
      if (q.creature_name == creature.name &&
        q.argument == Query::Argument::attack)
        q.result *= 2;
    });
  }

  ~DoubleAttackModifier()
  {
    conn.disconnect();
  }
};

// 비슷한 아이디어이다. Query 대신 Command를 쓴다는 것만 다르다.
int main(int ac, char* av)
{
  Game game;
  Creature goblin{ game, "Strong Goblin", 2, 2 };

  cout << goblin << endl;

  {
    DoubleAttackModifier dam{ game, goblin };

    cout << goblin << endl;
  }

  cout << goblin << endl;

  getchar();
  return 0;
}
```

### `cor_pointer.cpp`

This file illustrates a more direct linked-list style chain of modifiers. Each modifier holds a pointer to the next, and `handle()` calls propagate through the chain.

```cpp
#include <iostream>
#include <string>
using namespace std;

struct Creature
{
  string name;
  int attack, defense;

  Creature(const string& name, const int attack, const int defense)
    : name(name),
      attack(attack),
      defense(defense)
  {
  }


  friend ostream& operator<<(ostream& os, const Creature& obj)
  {
    return os
      << "name: " << obj.name
      << " attack: " << obj.attack
      << " defense: " << obj.defense;
  }
};

class CreatureModifier
{
  CreatureModifier* next{ nullptr }; // unique_ptr
protected:
  Creature& creature; // 포인터 또는 shared_ptr
public:
  explicit CreatureModifier(Creature& creature)
    : creature(creature)
  {
  }
  virtual ~CreatureModifier() = default;

  void add(CreatureModifier* cm)
  {
    if (next) next->add(cm);
    else next = cm;
  }

  // 두 가지 접근방법:

  // 1. 항상 베이스의 handle()을 호출한다. 추가적인 로직을 수행할 수도 있다.
  // 2. 직접 처리할 수 없을때만 베이스의 handle()을 호출한다.

  virtual void handle()
  {
    if (next) next->handle();
  }
};

// 1. 크리처의 공격력을 두 배 늘린다.
// 2. 힘이 2보다 크지 않으면 방어력을 1 늘린다.
// 3. 이 크리처에는 보너스가 적용되지 않는다.

class NoBonusesModifier : public CreatureModifier
{
public:
  explicit NoBonusesModifier(Creature& creature)
    : CreatureModifier(creature)
  {
  }

  void handle() override
  {
    // 아무것도 안함.
  }
};

class DoubleAttackModifier : public CreatureModifier
{
public:
  explicit DoubleAttackModifier(Creature& creature)
    : CreatureModifier(creature)
  {
  }

  void handle() override
  {
    creature.attack *= 2;
    CreatureModifier::handle();
  }
};

class IncreaseDefenseModifier : public CreatureModifier
{
public:
  explicit IncreaseDefenseModifier(Creature& creature)
    : CreatureModifier(creature)
  {
  }


  void handle() override
  {
    if (creature.attack <= 2)
      creature.defense += 1;
    CreatureModifier::handle();
  }
};

int main_()
{
  Creature goblin{ "Goblin", 1, 1 };
  CreatureModifier root{ goblin };
  DoubleAttackModifier r1{ goblin };
  DoubleAttackModifier r1_2{ goblin };
  IncreaseDefenseModifier r2{ goblin };
  //NoBonusesModifier nb{ goblin }; //유효한 Command 객체

  //root.add(&nb);
  root.add(&r1);
  root.add(&r1_2);
  root.add(&r2);

  root.handle(); // 다소 번거롭다

  cout << goblin << endl;

  //getchar();
  return 0;
}
```

## Execution Result

(Please provide instructions on how to compile and run these examples. The output will be placed here.)
---

*This file was automatically generated.*
