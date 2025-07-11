# State Pattern

The State pattern is a behavioral design pattern that allows an object to alter its behavior when its internal state changes. It appears as if the object changed its class.

This pattern is used when an object's behavior depends on its state and it must change its behavior at run-time depending on that state. It can also be used when operations have large, multipart conditional statements that depend on the object's state.

## C++ Code Examples

This directory showcases various ways to implement state machines and the State pattern.

### `StateCodingExercise.cpp` (Combination Lock)

This example implements a `CombinationLock`. The lock's `status` (a string) changes based on the digits entered, moving from "LOCKED" to showing entered digits, then to "OPEN" on success or "ERROR" on failure. This is a simple stateful class.

```cpp
#include <iostream>
#include <vector>
#include <string>
using namespace std;

class CombinationLock
{
    vector<int> combination;
    int digits_entered{0};
    bool failed{false};

    void reset()
    {
      status = "LOCKED";
      digits_entered = 0;
      failed = false;
    }
public:
    string status;

    CombinationLock(const vector<int> &combination) : combination(combination) {
      reset();
    }

    void enter_digit(int digit)
    {
      if (status == "LOCKED") status = "";
      status +=  to_string(digit);
      if (combination[digits_entered] != digit)
      {
        failed = true;
      }
      digits_entered++;

      if (digits_entered == combination.size())
        status = failed ? "ERROR" : "OPEN";
    }
};

#include "gtest/gtest.h"
// ... (GTest code from file) ...

int main(int ac, char* av[])
{
  testing::InitGoogleTest(&ac, av);
  return RUN_ALL_TESTS();
}
```

### `classic.cpp` (Classic State Pattern - Light Switch)

This file demonstrates the classic Gang of Four State pattern. A `LightSwitch` object delegates its `on()` and `off()` behavior to a `State` object (either `OnState` or `OffState`). The state objects themselves handle the transitions by changing the `LightSwitch`'s current state.

```cpp
#include <iostream>
#include <string>
using namespace std;

class LightSwitch;

struct State
{
  virtual void on(LightSwitch *ls)
  {
    cout << "Light is already on\n";
  }
  virtual void off(LightSwitch *ls)
  {
    cout << "Light is already off\n";
  }
  virtual ~State() = default; // Added virtual destructor
};

struct OnState : State
{
  OnState()
  {
    cout << "Light turned on\n";
  }

  void off(LightSwitch* ls) override;
};

struct OffState : State
{
  OffState()
  {
    cout << "Light turned off\n";
  }

  void on(LightSwitch* ls) override;
};

class LightSwitch
{
  State *state;
public:
  LightSwitch()
  {
    state = new OffState();
  }
  ~LightSwitch() { delete state; } // Added destructor
  void set_state(State* state)
  {
    delete this->state; // Delete old state
    this->state = state;
  }
  void on() { state->on(this); }
  void off() { state->off(this); }
};

void OnState::off(LightSwitch* ls)
{
  cout << "Switching light off...\n";
  ls->set_state(new OffState());
  // delete this; // State objects are now managed by LightSwitch
}

void OffState::on(LightSwitch* ls)
{
  cout << "Switching light on...\n";
  ls->set_state(new OnState());
  // delete this; // State objects are now managed by LightSwitch
}

void main_3() // Example usage
{
  LightSwitch ls;
  ls.on();  // OffState handles on, transitions to OnState
  ls.off(); // OnState handles off, transitions to OffState
  ls.off(); // OffState handles off, already off
  // getchar(); // Commented for non-interactive
}
```
*Note: Small memory management improvements (destructor in `LightSwitch`, virtual destructor in `State`, and removal of `delete this` in state transitions assuming `LightSwitch` manages state lifetime) are suggested for robustness.*

### `handmade.cpp` (Handmade State Machine - Telephone)

This example implements a state machine for a telephone using enums for `State` and `Trigger`. The transition rules are stored in a `std::map`. The program loops, taking user input for triggers and updating the current state based on the rules.

```cpp
#include <iostream>
#include <string>
#include <map>
#include <vector>
using namespace std;

enum class State
{
  off_hook,
  connecting,
  connected,
  on_hold,
  on_hook
};

// ... (ostream operator for State and Trigger) ...

enum class Trigger
{
  call_dialed,
  hung_up,
  call_connected,
  placed_on_hold,
  taken_off_hold,
  left_message,
  stop_using_phone
};

int main_f(char* argv[]) // Example usage
{
  map<State, vector<pair<Trigger, State>>> rules;

  rules[State::off_hook] = { /* ... rules ... */ };
  // ... (definition of all rules) ...

  State currentState{ State::off_hook }, exitState{ State::on_hook };

  while (true)
  {
    cout << "The phone is currently " << currentState << endl;
    // ... (logic for user input and state transition) ...
    if (currentState == exitState) break;
  }
  cout << "We are done using the phone" << "\n";
  return 0;
}
```

### `msm.cpp` (Boost Meta State Machine - Telephone)

This file demonstrates a more advanced state machine for a telephone using the Boost Meta State Machine (MSM) library. It defines states as structs, events (triggers) as structs, and a transition table. Boost MSM handles the state transitions, entry/exit actions, and guards.

```cpp
#include <iostream>
#include <string>
#include <vector>
using namespace std;

#include <boost/msm/back/state_machine.hpp>
#include <boost/msm/front/state_machine_def.hpp>
#include <boost/msm/front/functor_row.hpp>

namespace msm = boost::msm;
namespace mpl = boost::mpl;
using namespace msm::front;

// ... (state_names vector, event structs like CallDialed, HungUp) ...

struct PhoneStateMachine : state_machine_def<PhoneStateMachine>
{
  bool angry{ false };

  struct OffHook : state<> {};
  struct Connecting : state<> { /* ... on_entry ... */ };
  struct Connected : state<> {};
  struct OnHold : state<> {};
  struct PhoneDestroyed : state<> {};

  struct PhoneBeingDestroyed { /* ... action ... */ };
  struct CanDestroyPhone { /* ... guard ... */ };

  struct transition_table : mpl::vector <
    Row<OffHook, CallDialed, Connecting>,
    Row<Connecting, CallConnected, Connected>,
    Row<Connected, PlacedOnHold, OnHold>,
    Row<OnHold, PhoneThrownIntoWall, PhoneDestroyed, PhoneBeingDestroyed, CanDestroyPhone>
    // ... other transitions
  > {};

  typedef OffHook initial_state;

  template <class FSM, class Event>
  void no_transition(Event const& e, FSM&, int state) { /* ... */ }
};

int main() // Example Usage
{
  msm::back::state_machine<PhoneStateMachine> phone;
  // ... (phone.process_event calls, info() calls) ...
  return 0;
}
```

## Execution Result

(Please provide instructions on how to compile and run these examples. The output will be placed here.)
---

*This file was automatically generated.*
