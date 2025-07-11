# Mediator Pattern

The Mediator pattern is a behavioral design pattern that lets you reduce chaotic dependencies between objects. The pattern restricts direct communications between the objects and forces them to collaborate only via a mediator object.

It promotes loose coupling by keeping objects from referring to each other explicitly, and it allows you to vary their interaction independently.

## C++ Code Examples

Below are C++ source files demonstrating different implementations of the Mediator pattern.

### `MediatorCodingExercise.cpp`

This file shows a simple mediator that handles integer value changes between `Participant` objects. The `Mediator` class notifies all participants when one of them "says" a value.

```cpp
#include <iostream>
#include <vector>
using namespace std;

struct IParticipant
{
    virtual void notify(IParticipant* sender, int value) = 0;
};

struct Mediator
{
    vector<IParticipant*> participants;
    void say(IParticipant* sender, int value)
    {
      for (auto p : participants)
        p->notify(sender, value);
    }
};

struct Participant : IParticipant
{
    int value{0};
    Mediator& mediator;

    Participant(Mediator &mediator) : mediator(mediator)
    {
      mediator.participants.push_back(this);
    }

    void notify(IParticipant *sender, int value) override {
      if (sender != this)
        this->value += value;
    }

    void say(int value)
    {
      mediator.say(this, value);
    }
};

#include "gtest/gtest.h"
#include "helpers/iohelper.h"

#include "exercise.cpp"

namespace {

    class Evaluate : public ::testing::Test {};

    TEST_F(Evaluate, LongMediationTest) {
      Mediator m;
      Participant p1{m}, p2{m};

      ASSERT_EQ(0, p1.value);
      ASSERT_EQ(0, p2.value);

      p1.say(2);

      ASSERT_EQ(0, p1.value);
      ASSERT_EQ(2, p2.value);

      p2.say(4);

      ASSERT_EQ(4, p1.value);
      ASSERT_EQ(2, p2.value);
    }

}  // namespace
```

### Chat Room Example

This example implements a chat room where the `ChatRoom` class acts as the mediator between `Person` objects. Persons join the room and can broadcast messages to everyone or send private messages to specific individuals, all facilitated by the `ChatRoom`.

**`person.h`**
```cpp
#pragma once
#include <string>
#include <iostream>
#include <vector>
using namespace std;

struct ChatRoom;

struct Person
{
  string name;
  ChatRoom* room = nullptr;

  Person(const string& name);
  void receive(const string& origin, const string& message);

  void say(const string& message) const;
  vector<string> chat_log;

  void pm(const string& who, const string& message) const;

  // IDE에서 자동으로 생성된 코드이다
  friend bool operator==(const Person& lhs, const Person& rhs)
  {
    return lhs.name == rhs.name;
  }

  friend bool operator!=(const Person& lhs, const Person& rhs)
  {
    return !(lhs == rhs);
  }
};
```

**`person.cpp`**
```cpp
#include "person.h"
#include "chatroom.h"

Person::Person(const string& name) : name(name)
{
}

void Person::receive(const string& origin, const string& message)
{
  string s{ origin + ": \"" + message + "\"" };
  cout << "[" << name << "'s chat session] " << s << "\n";
  chat_log.emplace_back(s);
}

void Person::say(const string& message) const
{
  room->broadcast(name, message);
}

void Person::pm(const string& who, const string& message) const
{
  room->message(name, who, message);
}
```

**`chatroom.h`**
```cpp
#pragma once
#include <vector>
#include <string> // Added for string usage

// Forward declaration
struct Person;

struct ChatRoom
{
  std::vector<Person*> people; // 추가만 한다고 가정한다

  void join(Person* p);
  void broadcast(const std::string& origin, const std::string& message);
  void message(const std::string& origin, const std::string& who, const std::string& message);
};
```

**`chatroom.cpp`**
```cpp
#include "person.h"
#include "chatroom.h"
#include <algorithm>
#include <string> // Added for string usage

void ChatRoom::broadcast(const string& origin, const string& message)
{
  for (auto p : people)
    if (p->name != origin)
      p->receive(origin, message);
}

void ChatRoom::join(Person* p)
{
  string join_msg = p->name + " joins the chat";
  broadcast("room", join_msg);

  p->room = this;
  people.push_back(p);
}

void ChatRoom::message(const string& origin, const string& who, const string& message)
{
  auto target = find_if(begin(people), end(people), [&](const Person* p) { return p->name == who; });
  if (target != end(people))
  {
    (*target)->receive(origin, message);
  }
}
```

**`chat.cpp` (Main/Usage)**
```cpp
#include <iostream>
#include <string>
#include <vector>
using namespace std;

#include "person.h"
#include "chatroom.h"

int main__()
{
  ChatRoom room;

  Person john{ "john" };
  Person jane{ "jane" };
  room.join(&john);
  room.join(&jane);
  john.say("hi room");
  jane.say("oh, hey john");

  Person simon("simon");
  room.join(&simon);
  simon.say("hi everyone!");

  jane.pm("simon", "glad you could join us, simon");

  getchar();
  return 0;
}
```

### `soccer.cpp` (Event Broker/Signals Mediator)

This example demonstrates a Mediator pattern using an event broker approach with `boost::signals2`. The `Game` object acts as the mediator, to which `Player` objects publish events (like scoring a goal) and `Coach` objects subscribe to react to these events.

```cpp
#include <iostream>
#include <string>
#include <vector>
struct Game;
using namespace std;

#include <boost/signals2.hpp>
using namespace boost::signals2;

struct EventData
{
  virtual ~EventData() = default;
  virtual void print() const = 0;
};

struct Player;
struct PlayerScoredData : EventData
{
  string player_name;
  int goals_scored_so_far;

  PlayerScoredData(const string& player_name, const int goals_scored_so_far)
    : player_name(player_name),
      goals_scored_so_far(goals_scored_so_far)
  {
  }

  void print() const override
  {
    cout << player_name << " has scored! (their "
      << goals_scored_so_far << " goal)" << "\n";
  }
};

struct Game
{
  signal<void(EventData*)> events; // °üÂûÀÚ
};

struct Player
{
  string name;
  int goals_scored = 0;
  Game& game;


  Player(const string& name, Game& game)
    : name(name),
      game(game)
  {
  }

  void score()
  {
    goals_scored++;
    PlayerScoredData ps{name, goals_scored};
    game.events(&ps);
  }
};

struct Coach
{
  Game& game;

  explicit Coach(Game& game)
    : game(game)
  {
    // ¼±¼ö°¡ 3Á¡ ¹Ì¸¸ÀÇ µæÁ¡À» ÇßÀ¸¸é °Ý·ÁÇØÁØ´Ù
    game.events.connect([](EventData* e)
    {
      PlayerScoredData* ps = dynamic_cast<PlayerScoredData*>(e);
      if (ps && ps->goals_scored_so_far < 3)
      {
        cout << "coach says: well done, " << ps->player_name << "\n";
      }
    });
  }
};

int main()
{
  Game game;
  Player player{ "Sam", game };
  Coach coach{ game };

  player.score();
  player.score();
  player.score(); // ignored by coach

  getchar();
  return 0;
}
```

## Execution Result

(Please provide instructions on how to compile and run these examples. The output will be placed here.)
---

*This file was automatically generated.*
