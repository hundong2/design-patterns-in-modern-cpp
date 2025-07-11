# Observer Pattern

The Observer pattern is a behavioral design pattern that lets you define a subscription mechanism to notify multiple objects about any events that happen to the object they’re observing.

When an object (the "subject" or "observable") changes state, all its dependent objects (the "observers") are notified and updated automatically.

## C++ Code Examples

This directory contains several examples of the Observer pattern, from basic implementations to more advanced ones using libraries and addressing thread safety.

### `ObserverCodingExercise.cpp` (Rat Game)

A simple game scenario where `Rat` objects observe each other. When a rat enters or dies, other rats are notified and update their attack power. `Game` acts as a central point for dispatching these notifications.

```cpp
#include <iostream>
#include <vector>
using namespace std;

struct IRat
{
    virtual void rat_enters(IRat* sender) = 0;
    virtual void rat_dies(IRat* sender) = 0;
    virtual void notify(IRat* target) = 0;
};

struct Game
{
    vector<IRat*> rats;
    virtual void fire_rat_enters(IRat* sender)
    {
      for (auto rat : rats) rat->rat_enters(sender);
    }
    virtual void fire_rat_dies(IRat* sender)
    {
      for (auto rat : rats) rat->rat_dies(sender);
    }
    virtual void fire_notify(IRat* target)
    {
      for (auto rat : rats) rat->notify(target);
    }
};

struct Rat : IRat
{
    Game& game;
    int attack{1};

    Rat(Game &game) : game(game)
    {
      game.rats.push_back(this);
      game.fire_rat_enters(this);
    }

    ~Rat() { game.fire_rat_dies(this); }

    void rat_enters(IRat *sender) override {
      if (sender != this)
      {
        ++attack;
        game.fire_notify(sender);
      }
    }

    void rat_dies(IRat *sender) override {
      --attack;
    }

    void notify(IRat *target) override {
      if (target == this) ++attack;
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

### `observer1.cpp` & `observer2.cpp` (Person Listeners)

These files demonstrate a `Person` object whose properties (like `age` and `can_vote`) are observed by `PersonListener` implementations (e.g., `ConsoleListener`).
- **`observer1.cpp`**: Basic implementation.
- **`observer2.cpp`**: Adds thread safety using a `std::mutex` for subscribe, unsubscribe, and notify operations. It also handles the case of unsubscribing listeners during notification by marking them as `nullptr` and then cleaning up.

**`observer1.cpp` (Conceptual Snippet)**
```cpp
// ... (struct PersonListener, Person, ConsoleListener definitions) ...
// Person p{ 14 };
// ConsoleListener cl;
// p.subscribe(&cl);
// p.set_age(15); // Notifies cl
// p.set_age(16); // Notifies cl (age and can_vote change)
// ...
```

**`observer2.cpp` (Conceptual Snippet - with thread safety)**
```cpp
// ... (struct PersonListener, Person with mutex, ConsoleListener definitions) ...
// Person p{ 14 };
// ConsoleListener cl;
// p.subscribe(&cl);
// p.set_age(17);
// p.ubsubscribe(&cl); // (original typo was ubsubscribe)
// p.set_age(18); // cl is no longer notified
// ...
```

### `observer3.cpp` (Boost.Signals2 Observer)

This example shows a `Person` object that inherits from a templated `Observable` struct which uses `boost::signals2::signal` for managing property change notifications. This leverages a library for a more robust event-handling mechanism.

```cpp
#include <iostream>
#include <string>
using namespace std;
#include <boost/signals2.hpp>
using namespace boost;
using namespace signals2;

namespace {

template <typename T>
struct Observable
{
  virtual ~Observable() = default;
  signal<void(T&, const string&)> property_changed;
};

struct Person : Observable<Person>
{
  explicit Person(int age)
    : age(age)
  {
  }

  int get_age() const
  {
    return age;
  }

  void set_age(const int age)
  {
    if (this->age == age) return;

    this->age = age;
    property_changed(*this, "age");
  }

private:
  int age;
};
// ... (main_test5 usage) ...
}
```

### `observer_book.cpp` (Observable/Observer Classes)

This file implements generic `Observable<T>` and `Observer<T>` template classes. A `Person` class inherits `Observable<Person>`, and `ConsolePersonObserver` and `TrafficAdministration` inherit `Observer<Person>`. `TrafficAdministration` demonstrates an observer that unsubscribes itself when a condition is met (person is old enough to drive). It also touches upon thread safety with `std::mutex`.

```cpp
// ... (Observable<T>, Observer<T> templates) ...
// struct Person : Observable<Person> { ... }
// struct ConsolePersonObserver : Observer<Person> { ... }
// struct TrafficAdministration : Observer<Person> { ... }

// Person p{ 10 };
// TrafficAdministration o;
// p.subscribe(&o);
// p.set_age(16); // o is notified
// p.set_age(17); // o is notified and then unsubscribes itself
// p.set_age(21); // o is no longer notified
// ...
```

### `observer_notes.cpp` (Discussion and Reentrancy Issues)

This file contains more of a discussion and code snippets (`Foo`, `Listener`, `ScopeListener`) related to the complexities of the Observer pattern, particularly:
- Listener management (adding, removing).
- Thread safety with `std::recursive_mutex`.
- The problem of modifying the observer list (e.g., a listener removing itself or another listener) during a notification cycle, which can lead to crashes or undefined behavior if not handled carefully (reentrancy).

```cpp
// ... (Foo, Listener, ScopeListener showing reentrancy problem) ...
// Foo foo;
// ScopeListener sl(foo); // Subscribes in constructor
// foo.SetS("abc"); // fooChanged in sl is called, which calls stopListening (removes itself)
                  // This can crash if notifyListeners isn't careful.
// Destructor of sl also calls stopListening
```

### `new/` Directory (Refined Observable/Observer Implementation)

The `new/` directory contains a more structured and refined implementation of the observer pattern, including:

- **`Observer.hpp`**: Defines the `Observer<T>` template interface.
  ```cpp
  template <typename T> struct Observer
  {
    virtual void field_changed(
      T& source, const std::string& field_name) = 0;
  };
  ```
- **`Observable.hpp`**: Defines a basic `Observable<T>` template class for managing and notifying observers.
  ```cpp
  template <typename T> struct Observable {
    std::vector<Observer<T>*> observers;
  public:
    void notify(T& source, const std::string& field_name);
    void subscribe(Observer<T>& observer);
    void unsubscribe(Observer<T>& observer);
  };
  ```
- **`SaferObservable.hpp`**: An improved version of `Observable` that uses `std::recursive_mutex` (though `std::mutex` is generally preferred if reentrancy can be avoided by design) for thread-safe subscribe/unsubscribe/notify operations. It also attempts to handle observer self-unsubscription during notification by setting the observer pointer to `nullptr` in the list (though this has limitations, e.g., with `std::set`).
  ```cpp
  template <typename T> struct SaferObservable {
    std::vector<Observer<T>*> observers;
    typedef std::recursive_mutex mutex_t;
    mutex_t mtx;
  public:
    void notify(T& source, const std::string& field_name);
    void subscribe(Observer<T>& observer);
    void unsubscribe(Observer<T>& observer); // Special handling for reentrancy
  };
  ```
- **`main.cpp`**: Demonstrates usage of `SaferObservable` with `Person`, `ConsolePersonObserver`, and `TrafficAdministration` (similar to `observer_book.cpp`). It also includes an example of using `boost::signals2` for comparison.

**`new/main.cpp` (Conceptual Snippet)**
```cpp
// class Person : public SaferObservable<Person> { ... }
// struct ConsolePersonObserver : public Observer<Person> { ... }
// struct TrafficAdministration : Observer<Person> { ... }

// Person person{10};
// ConsolePersonObserver cpo;
// person.subscribe(cpo);
// TrafficAdministration ta;
// person.subscribe(ta);
// person.set_age(16);
// person.set_age(17); // ta unsubscribes itself here safely
// ...
```

## Execution Result

(Please provide instructions on how to compile and run these examples. The output will be placed here.)
---

*This file was automatically generated.*
