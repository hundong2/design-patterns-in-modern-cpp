# Creational Design Patterns

This directory contains examples of various Creational Design Patterns in C++. Creational patterns provide object creation mechanisms that increase flexibility and reuse of existing code. Also included are examples related to SOLID principles, which are often foundational to good object-oriented design, including creational strategies.

## Factory Method Pattern

The Factory Method pattern defines an interface for creating an object, but lets subclasses alter the type of objects that will be created.

### `FactoryMethod.cpp` & `Factory.cpp` (Point Creation)

These files demonstrate creating `Point` objects that can be initialized from Cartesian or Polar coordinates. The constructor is made private, and static factory methods (`NewCartesian`, `NewPolar`) are provided.

**`FactoryMethod.cpp` (Illustrative)**
```cpp
#define _USE_MATH_DEFINES
#include <cmath>
#include <iostream>

// enum class PointType { cartesian, polar }; // Not strictly needed with factory methods

class Point
{
  Point(const float x, const float y) : x{x}, y{y} {}
public:
  float x, y;

  friend std::ostream& operator<<(std::ostream& os, const Point& obj) {
    return os << "x: " << obj.x << " y: " << obj.y;
  }

  static Point NewCartesian(float x, float y) {
    return{ x,y };
  }
  static Point NewPolar(float r, float theta) {
    return{ r*cos(theta), r*sin(theta) };
  }
};

// int main_z() {
//   auto p = Point::NewPolar(5, M_PI_4);
//   std::cout << p << std::endl;
//   return 0;
// }
```
*(`Factory.cpp` is similar but uses a separate `PointFactory` class, which is a variation of the Factory pattern, sometimes just called a Factory or Simple Factory).*

### `InnerFactory.cpp` (Point Creation with Inner Factory)

This shows the factory methods encapsulated within an inner `PointFactory` class inside `Point`.

```cpp
#include <cmath>

class Point
{
  Point(float x, float y) : x(x), y(y) {}

  class PointFactory // Inner class
  {
    PointFactory() {} // Private constructor for PointFactory
  public:
    static Point NewCartesian(float x, float y) {
      return { x,y };
    }
    static Point NewPolar(float r, float theta) {
      return{ r*cos(theta), r*sin(theta) };
    }
  };
public:
  float x, y;
  static PointFactory Factory; // Static instance of the inner factory
};

// Point::PointFactory Point::Factory; // Definition of static member if needed outside C++17 inline
// int main_2() {
//   auto pp = Point::Factory.NewCartesian(2, 3);
//   return 0;
// }
```

### `FactoryCodingExercise.cpp` (Person Factory Exercise)

A coding exercise to implement a `PersonFactory` that creates `Person` objects with incrementally assigned IDs.

```cpp
#include <vector>
#include <string>
// #include <gtest/gtest.h> // For brevity, gtest parts omitted here
using namespace std;

namespace FactoryExercise {
struct Person
{
  int id;
  string name;
};

class PersonFactory
{
  int id{ 0 };
public:
  Person create_person(const string& name)
  {
    return { id++, name };
  }
};
// ... GTest code ...
}
```

## Abstract Factory Pattern

The Abstract Factory pattern provides an interface for creating families of related or dependent objects without specifying their concrete classes.

### `AbstractFactory.cpp`, `HotDrink.h`, `HotDrinkFactory.h`, `CoffeeFactory.h`, `TeaFactory.h`, `DrinkFactory.h`

These files demonstrate an Abstract Factory for creating hot drinks.
- **`HotDrink.h`**: Defines the `HotDrink` interface and concrete products `Tea` and `Coffee`.
- **`HotDrinkFactory.h`**: Defines the `HotDrinkFactory` interface (the Abstract Factory).
- **`CoffeeFactory.h`**, **`TeaFactory.h`**: Concrete factories implementing `HotDrinkFactory`.
- **`DrinkFactory.h`**: A higher-level factory that uses the concrete factories to produce drinks. It can be seen as a client of the Abstract Factory setup or a more complex factory itself. `DrinkWithVolumeFactory` is another variation.
- **`AbstractFactory.cpp`**: Shows usage.

**`HotDrink.h` (Product Interface and Concrete Products)**
```cpp
#pragma once
#include <memory>
#include <iostream> // For cout
#include <string>
// ... (using namespace std;) ...

struct HotDrink {
  virtual ~HotDrink() = default;
  virtual void prepare(int volume) = 0;
};

struct Tea : HotDrink {
  void prepare(int volume) override {
    std::cout << "Take tea bag, boil water, pour " << volume << "ml, add some lemon" << std::endl;
  }
};

struct Coffee : HotDrink {
  void prepare(int volume) override {
    std::cout << "Grind some beans, boil water, pour " << volume << "ml, add cream, enjoy!" << std::endl;
  }
};
```

**`HotDrinkFactory.h` (Abstract Factory Interface)**
```cpp
#pragma once
#include "HotDrink.h" // Includes <memory>
// ... (using namespace std;) ...

struct HotDrinkFactory {
  virtual std::unique_ptr<HotDrink> make() const = 0;
  virtual ~HotDrinkFactory() = default; // Good practice
};
```

**`CoffeeFactory.h` (Concrete Factory)**
```cpp
#pragma once
#include "HotDrink.h"
#include "HotDrinkFactory.h"
// ... (using namespace std;) ...

struct CoffeeFactory : HotDrinkFactory {
  std::unique_ptr<HotDrink> make() const override {
    return std::make_unique<Coffee>();
  }
};
```

**`DrinkFactory.h` (Client/Orchestrator Factory)**
```cpp
#pragma once
#include <string>
#include "HotDrink.h"
#include "TeaFactory.h"   // Concrete Factory
#include "CoffeeFactory.h" // Concrete Factory
#include <map>
#include <functional>
// ... (using namespace std;) ...

class DrinkFactory {
  std::map<std::string, std::unique_ptr<HotDrinkFactory>> hot_factories;
public:
  DrinkFactory() {
    hot_factories["coffee"] = std::make_unique<CoffeeFactory>();
    hot_factories["tea"] = std::make_unique<TeaFactory>();
  }

  std::unique_ptr<HotDrink> make_drink(const std::string& name) {
    auto drink = hot_factories[name]->make();
    // The prepare call here is a bit misplaced for a pure factory,
    // as the volume is fixed. Ideally, it would be passed or configured.
    drink->prepare(200);
    return drink;
  }
};
// ... (DrinkWithVolumeFactory provides an alternative approach) ...
```

## Builder Pattern

The Builder pattern separates the construction of a complex object from its representation, so that the same construction process can create different representations.

### `Builder.cpp` (HTML Element Builder)

Builds an `HtmlElement` object step-by-step using a fluent interface.

```cpp
#include <iostream>
#include <string>
#include <vector>
#include <sstream>
#include <memory>
// ... (using namespace std;) ...

struct HtmlBuilder; // Forward declaration

struct HtmlElement {
  std::string name;
  std::string text;
  std::vector<HtmlElement> elements;
  const size_t indent_size = 2;

  HtmlElement() {}
  HtmlElement(const std::string& name, const std::string& text)
    : name(name), text(text) {}

  std::string str(int indent = 0) const; // Implementation details omitted for brevity
  static std::unique_ptr<HtmlBuilder> build(std::string root_name);
};

struct HtmlBuilder {
  HtmlElement root;
  HtmlBuilder(std::string root_name) { root.name = root_name; }

  HtmlBuilder& add_child(std::string child_name, std::string child_text) {
    HtmlElement e{ child_name, child_text };
    root.elements.emplace_back(e);
    return *this;
  }
  // ... (add_child_2, str, operator HtmlElement) ...
};
// std::unique_ptr<HtmlBuilder> HtmlElement::build(std::string root_name) {
//   return std::make_unique<HtmlBuilder>(root_name);
// }
// ... (main/demo usage) ...
```

### `GroovyStyle.cpp` (Groovy-Style HTML Builder)

Demonstrates a builder using initializer lists and specific tag types (`P`, `IMG`) for a more declarative, "Groovy-like" syntax.

```cpp
#include <string>
#include <vector>
#include <iostream>
#include <utility> // For std::pair, std::make_pair

namespace html {
  struct Tag {
    std::string name;
    std::string text;
    std::vector<Tag> children;
    std::vector<std::pair<std::string, std::string>> attributes;
    // ... (constructor, operator<<) ...
  protected:
    Tag(const std::string& name, const std::string& text);
    Tag(const std::string& name, const std::vector<Tag>& children);
  };

  struct P : Tag {
    explicit P(const std::string& text);
    P(std::initializer_list<Tag> children);
  };

  struct IMG : Tag {
    explicit IMG(const std::string& url);
  };
}
// ... (main1 usage) ...
```

### Faceted Builder (`Facets.cpp`, `Person.h`, `Person.cpp`, `PersonBuilder.h`, `PersonBuilder.cpp`, `PersonAddressBuilder.h`, `PersonJobBuilder.h`)

This more complex builder example constructs a `Person` object with different aspects (address, employment) handled by separate builder facets (`PersonAddressBuilder`, `PersonJobBuilder`), all orchestrated by a main `PersonBuilder`.

**`Person.h` (The Product)**
```cpp
#pragma once
#include <string>
#include <iostream>
// ...

class PersonBuilder; // Forward declaration

class Person {
  // address
  std::string street_address, post_code, city;
  // employment
  std::string company_name, position;
  int annual_income = 0;

  Person(); // Private constructor
public:
  ~Person();
  static PersonBuilder create(); // Static method to get the builder
  // ... (move constructor/assignment, operator<<) ...
  friend class PersonBuilder;
  friend class PersonAddressBuilder;
  friend class PersonJobBuilder;
};
```

**`PersonBuilder.h` (Base and Main Builder)**
```cpp
#pragma once
#include "Person.h" // Includes <string>, <iostream>

class PersonAddressBuilder; // Forward declaration
class PersonJobBuilder;   // Forward declaration

class PersonBuilderBase {
protected:
  Person& person;
  explicit PersonBuilderBase(Person& person) : person{ person } {}
public:
  operator Person() const { return std::move(person); }
  PersonAddressBuilder lives() const;
  PersonJobBuilder works() const;
};

class PersonBuilder : public PersonBuilderBase {
  Person p; // Owns the person instance being built
public:
  PersonBuilder() : PersonBuilderBase{p} {}
};
```

**`PersonAddressBuilder.h` (Address Facet)**
```cpp
#pragma once
#include "PersonBuilder.h" // Includes Person.h
// ... (using Self = PersonAddressBuilder;) ...
class PersonAddressBuilder : public PersonBuilderBase { /* ... */ };
  // Methods like at(), with_postcode(), in()
```

**`PersonJobBuilder.h` (Job Facet)**
```cpp
#pragma once
#include "PersonBuilder.h" // Includes Person.h
// ... (using Self = PersonJobBuilder;) ...
class PersonJobBuilder : public PersonBuilderBase { /* ... */ };
  // Methods like at(), as_a(), earning()
```

**`Facets.cpp` (Usage)**
```cpp
// ... (Includes) ...
// Person p = Person::create()
//   .lives().at("123 London Road").with_postcode("SW1 1GB").in("London")
//   .works().at("PragmaSoft").as_a("Consultant").earning(10e6);
// std::cout << p << std::endl;
```

### `BuilderCodingExercise.cpp` (Code Builder Exercise)

An exercise to build a `CodeBuilder` that constructs a string representation of a class definition with fields.

```cpp
#include <string>
#include <vector>
#include <ostream>
// ... (using namespace std;) ...

struct Field { /* name, type, operator<< */ };
struct Class { /* name, fields, operator<< */ };

class CodeBuilder {
  Class the_class;
public:
  CodeBuilder(const std::string& class_name);
  CodeBuilder& add_field(const std::string& name, const std::string& type);
  friend std::ostream& operator<<(std::ostream& os, const CodeBuilder& obj);
};
// ... (GTest code) ...
```

## Prototype Pattern

The Prototype pattern specifies the kinds of objects to create using a prototypical instance, and creates new objects by copying this prototype.

### `Prototype.cpp` & `Serialization.cpp` (Contact Cloning)

These examples demonstrate cloning `Contact` objects which have an `Address`.
- **`Prototype.cpp`**: Shows manual deep copy implementation in the `Contact` copy constructor and then introduces cloning via Boost.Serialization as a more robust way to achieve deep copies. It also has an `EmployeeFactory` that uses prototype instances (`main`, `aux`) to create new employees.
- **`Serialization.cpp`**: Focuses solely on using Boost.Serialization for cloning `Contact` objects.

**`Prototype.cpp` (Conceptual - Manual Deep Copy and Factory)**
```cpp
// ... (Address and Contact struct definitions with manual deep copy in Contact's copy ctor) ...
// struct EmployeeFactory {
//   static Contact main_prototype; // Example prototype
//   static Contact aux_prototype;  // Another prototype
//   static std::unique_ptr<Contact> NewMainOfficeEmployee(std::string name, int suite) {
//     return NewEmployee(name, suite, main_prototype);
//   }
// private:
//   static std::unique_ptr<Contact> NewEmployee(std::string name, int suite, Contact& proto) {
//     auto result = std::make_unique<Contact>(proto); // Uses copy ctor for cloning
//     result->name = name;
//     result->address->suite = suite;
//     return result;
//   }
// };
```

**`Serialization.cpp` (Boost.Serialization for Cloning)**
```cpp
// ... (Address and Contact struct definitions with Boost.Serialization `serialize` methods) ...
// auto clone = [](const Contact& c) {
//   std::ostringstream oss;
//   boost::archive::text_oarchive oa(oss);
//   oa << c; // Serialize
//   std::string s = oss.str();
//   std::istringstream iss(s);
//   boost::archive::text_iarchive ia(iss);
//   Contact result;
//   ia >> result; // Deserialize
//   return result;
// };
// Contact jane = clone(john); // Jane is a deep copy of John
```

### `PrototypeCodingExercise.cpp` (Line Deep Copy Exercise)

An exercise to implement a `deep_copy` method for a `Line` struct, which consists of two `Point` pointers.

```cpp
struct Point { int x{0}, y{0}; /* ... */ };
struct Line {
  Point *start, *end;
  // ... (constructor, destructor) ...
  Line deep_copy() const {
    return Line{ new Point(start->x, start->y), new Point(end->x, end->y) };
  }
};
// ... (GTest code) ...
```

## Singleton Pattern

The Singleton pattern ensures a class only has one instance, and provides a global point of access to it.

### `Singleton.h` / `Singleton.hpp` (Singleton Database)

These files (they are very similar, `Singleton.hpp` might be a slight refinement or duplicate) implement a `SingletonDatabase`.
- The constructor is private.
- Copying and assignment are deleted.
- A static `get()` method returns a reference to the single instance (which is a static local variable, making it thread-safe since C++11).
- It also includes a `DummyDatabase` for testing and `SingletonRecordFinder` (uses Singleton) vs. `ConfigurableRecordFinder` (uses dependency injection).

**`Singleton.hpp` (Illustrative)**
```cpp
#pragma once
#include <iostream>
#include <fstream>
#include <string>
#include <map>
// ... (boost::lexical_cast, vector) ...

class Database { /* ... */ }; // Interface

class SingletonDatabase : public Database {
  SingletonDatabase() {
    std::cout << "Initializing database" << std::endl;
    // ... (load data from capitals.txt) ...
  }
  std::map<std::string, int> capitals;
public:
  SingletonDatabase(SingletonDatabase const&) = delete;
  void operator=(SingletonDatabase const&) = delete;

  static SingletonDatabase& get() {
    static SingletonDatabase db; // Meyers' Singleton
    return db;
  }
  int get_population(const std::string& name) override;
};
// ... (DummyDatabase, SingletonRecordFinder, ConfigurableRecordFinder) ...
```
*(`Singleton-x.hpp` appears to be a slightly condensed version of the same code, perhaps for slides or a different context.)*

### `SingletonTests.cpp`

Contains GTest unit tests for `SingletonRecordFinder` (using the singleton) and `ConfigurableRecordFinder` (using a `DummyDatabase` via dependency injection).

### `SingletonCodingExercise.cpp` (Singleton Tester)

An exercise to implement a `SingletonTester::is_singleton` template function that checks if a given factory function always returns the same instance.

```cpp
#include <functional>
// ... (using namespace std;) ...

struct SingletonTester {
  template <typename T>
  bool is_singleton(std::function<T*()> factory) {
    T* obj1 = factory();
    T* obj2 = factory();
    return obj1 == obj2;
  }
};
// ... (GTest code) ...
```

## Monostate Pattern

The Monostate pattern is an alternative to Singleton. All instances of a Monostate class share the same state (static members), but the class itself can be instantiated multiple times. It provides the "singular" nature of state without restricting instantiation.

### `Monostate.cpp` (Printer ID)

A simple `Printer` class where the `id` is a static member, so all `Printer` objects share and modify the same `id`.

```cpp
#include <string> // Not strictly needed for this example

class Printer {
  static int id; // All instances share this state
public:
  int get_id() const { return id; }
  void set_id(int value) { id = value; }
};

int Printer::id = 0; // Definition of the static member

// int main_73468() {
//   Printer p1;
//   Printer p2;
//   p1.set_id(10);
//   // p2.get_id() would also be 10
//   return 0;
// }
```

## Dependency Injection and SOLID Principles

While not creational patterns themselves, these concepts are crucial for flexible and maintainable object creation and are often used in conjunction with or as alternatives to some creational patterns (e.g., DI instead of Singleton for testability).

### `BoostDI.cpp` & `BoostDIDemo.hpp` (Boost.DI examples)

These files demonstrate using the Boost.DI library for dependency injection.
- **`BoostDI.cpp`**: Shows creating a `Car` with an `Engine` and `ILogger` (implemented by `ConsoleLogger`), first manually and then using `boost::di::make_injector`.
- **`BoostDIDemo.hpp`**: A demo using `di::bind<IFoo>().to<Foo>().in(di::singleton)` to show singleton scope management with Boost.DI.
- **`di.h`**: This is the header for the Boost.DI library itself (version 1.1.0), included in the project. It's a single-header library.

### SOLID Principles (`SRP.cpp`, `OCP.cpp`, `LSP.cpp`, `ISP.cpp`, `DIP.cpp`)

These files provide examples for each of the first five SOLID principles:
- **`SRP.cpp` (Single Responsibility Principle)**: A `Journal` class initially has `save` functionality. SRP is applied by moving `save` to a separate `PersistenceManager`.
- **`OCP.cpp` (Open/Closed Principle)**: Filtering `Product`s. Initially, `ProductFilter` is modified for new filter criteria (violating OCP). Improved with a `Specification` pattern (`ColorSpecification`, `SizeSpecification`, `AndSpecification`) and a `BetterFilter` that takes a specification, allowing new filter logic without modifying `BetterFilter`.
- **`LSP.cpp` (Liskov Substitution Principle)**: `Rectangle` and `Square` example. A `Square` changing width also changes height (and vice-versa) can violate LSP if code expects `set_width` on a `Rectangle` not to affect its height.
- **`ISP.cpp` (Interface Segregation Principle)**: An `IMachine` interface with `print`, `fax`, `scan` is broken down into smaller, more specific interfaces (`IPrinter`, `IScanner`) so clients only depend on methods they use.
- **`DIP.cpp` (Dependency Inversion Principle)**: A `Research` (high-level) module initially depends on `Relationships` (low-level). DIP is applied by introducing a `RelationshipBrowser` abstraction, which both modules depend on.

## Other Concepts

### `MaybeMonad.cpp`

This file implements a simple `Maybe` monad to handle sequences of operations on potentially null pointers more safely, avoiding nested null checks for accessing `Person->Address->house_name`.

```cpp
// ... (Address, Person structs) ...
// template <typename T> struct Maybe {
//   T* context;
//   Maybe(T *context);
//   template <typename TFunc> auto With(TFunc evaluator); // If context is not null, apply evaluator
//   template <typename TFunc> auto Do(TFunc action);     // If context is not null, perform action
// };
// // Usage:
// // maybe(p)
// //   .With([](auto x) { return x->address; })
// //   .With([](auto x) { return x->house_name; })
// //   .Do([](auto x) { std::cout << *x << std::endl; });
```

---
*This file was automatically generated.*
