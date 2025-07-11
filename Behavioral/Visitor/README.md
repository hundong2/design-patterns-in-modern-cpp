# Visitor Pattern

The Visitor pattern is a behavioral design pattern that lets you add new operations to an object hierarchy without modifying the objects themselves. It achieves this by creating a separate "visitor" object that implements the new operation. The objects in the hierarchy then "accept" the visitor, effectively allowing the visitor to operate on them.

This pattern is useful when you have a stable object structure but need to perform various operations on its elements, and you want to avoid polluting their classes with these operations. It relies on double dispatch.

## C++ Code Examples

This directory contains numerous examples illustrating different facets and implementations of the Visitor pattern.

### `VisitorCodingExercise.cpp` (Expression Printer)

A basic example of an `Expression` hierarchy (`Value`, `AdditionExpression`, `MultiplicationExpression`) and an `ExpressionVisitor` interface with an `ExpressionPrinter` implementation. Each expression node has a `visit(ExpressionVisitor&)` method, and the visitor has overloaded `accept()` methods.

```cpp
#include <string>
#include <sstream>
using namespace std;

// Forward declarations for Visitor
struct Value;
struct AdditionExpression;
struct MultiplicationExpression;

// Visitor Interface
struct ExpressionVisitor
{
  virtual void accept(Value& value) = 0;
  virtual void accept(AdditionExpression& ae) = 0;
  virtual void accept(MultiplicationExpression& me) = 0;
  virtual ~ExpressionVisitor() = default;
};

// Element Interface
struct Expression
{
  virtual void visit(ExpressionVisitor& ev) = 0;
  virtual ~Expression() = default;
};

// Concrete Elements
struct Value : Expression
{
  int value;
  Value(int value) : value(value) {}
  void visit(ExpressionVisitor &ev) override { ev.accept(*this); }
};

struct AdditionExpression : Expression
{
  Expression &lhs, &rhs;
  AdditionExpression(Expression &lhs, Expression &rhs) : lhs(lhs), rhs(rhs) {}
  void visit(ExpressionVisitor &ev) override { ev.accept(*this); }
};

struct MultiplicationExpression : Expression
{
  Expression &lhs, &rhs;
  MultiplicationExpression(Expression &lhs, Expression &rhs) : lhs(lhs), rhs(rhs) {}
  void visit(ExpressionVisitor &ev) override { ev.accept(*this); }
};

// Concrete Visitor
struct ExpressionPrinter : ExpressionVisitor
{
  ostringstream oss;
  void accept(Value &value) override { oss << value.value; }
  void accept(AdditionExpression &ae) override {
    oss << "("; ae.lhs.visit(*this); oss << "+"; ae.rhs.visit(*this); oss << ")";
  }
  void accept(MultiplicationExpression &me) override {
    // Minor fix: Should probably visit children if it's a pre-order print
    // For this exercise, it seems to be direct print: (lhs)* (rhs)
    // If it were (2+3)*4, it should be:
    // me.lhs.visit(*this); oss << "*"; me.rhs.visit(*this); -> (2+3)*4
    // The test case implies the structure (lhs.visit)* (rhs.visit)
    // Let's assume the intent was to print compound expressions like (A*B)
    // The original code for MultiplicationExpression was:
    // me.lhs.visit(*this); oss << "*"; me.rhs.visit(*this);
    // This seems correct. The test case `ProductOfAdditionAndValue` uses `ep.accept(expr)` directly
    // which is a bit unusual, normally it would be `expr.visit(ep)`.
    // The provided solution structure seems to rely on `ExpressionPrinter::accept` being the entry point.
    // Let's stick to the provided structure for the exercise.

    // If MultiplicationExpression is the top-level element given to printer:
    oss << ""; // Potential adjustment based on how it's called.
              // The test `ProductOfAdditionAndValue` calls `ep.accept(expr)`
              // where expr is MultiplicationExpression.
    me.lhs.visit(*this);
    oss << "*";
    me.rhs.visit(*this);
  }
  string str() const { return oss.str(); }
};

#include "gtest/gtest.h"
// ... (GTest code from file) ...
```
*Note: The `VisitorCodingExercise` has a slightly unconventional `visit`/`accept` call pattern in tests but illustrates the core idea.*

### Classic Visitor (`visitor.hpp`, `visitor.cpp`, `model.hpp`, `single_double.cpp`)

These files demonstrate a more traditional Visitor setup for an HTML/Markdown document model.
- **`model.hpp`**: Defines `Element` (visitable interface with `accept(Visitor&)`), and concrete elements like `Paragraph`, `BoldParagraph`, `ListItem`, `List`, `Div`.
- **`visitor.hpp`**: Defines the `Visitor` interface with `visit()` methods for each concrete element type.
- **`visitor.cpp`** (Expression Example): Implements a visitor for a mathematical `Expression` hierarchy (`Literal`, `Addition`). `PrintVisitor` is a concrete visitor. This file also discusses single vs. double dispatch.
- **`single_double.cpp`**: Uses the document model from `model.hpp` and `Visitor` from `visitor.hpp`. It implements `HtmlVisitor` and `MarkdownVisitor`. `MarkdownVisitor` shows using `dynamic_cast` as an alternative if the strict double dispatch visitor isn't fully fleshed out for all types or if handling a base `Element&` directly.

**`visitor.hpp` (Document Model Visitor Interface)**
```cpp
#pragma once
#include <string>

// Forward declarations of Element types
struct Paragraph;
struct BoldParagraph;
struct ListItem;
struct List;
struct Div;

struct Visitor
{
	virtual ~Visitor() = default;
	virtual void visit(const Paragraph& p) = 0;
	virtual void visit(const BoldParagraph& p) = 0; // Added for BoldParagraph
	virtual void visit(const ListItem& li) = 0;
	virtual void visit(const List& l) = 0;
    virtual void visit(const Div& div) = 0; // Added for Div
	virtual std::string str() const = 0; // Method to get result
};
```

**`model.hpp` (Excerpt - Element and Paragraph)**
```cpp
// ... (Includes and forward declaration for Visitor) ...
struct Element {
    virtual ~Element() = default;
    virtual void accept(Visitor& v) const = 0;
    // ... other methods like print_html (violates OCP for new formats)
};

struct Paragraph : TextElement { // Assuming TextElement is a base or part of model
    // ... constructor ...
    std::string text; // Example member
    void accept(Visitor& v) const override { v.visit(*this); }
    // ...
};
```

### Intrusive Visitor (`visitor_intrusive.cpp`)

In this approach, operations (like `print`) are directly part of the `Expression` hierarchy. This is **not** the Visitor pattern but is often contrasted with it. The Visitor pattern aims to add operations *without* modifying the element classes.

```cpp
// Example: Expression elements have a print(ostringstream&) method.
struct Expression {
  virtual void print(ostringstream& oss) = 0;
};
// ... (DoubleExpression, AdditionExpression implement print) ...
```

### Reflective Visitor (`visitor_reflective.cpp`)

This uses `dynamic_cast` within the visitor's `print` method to determine the concrete type of the `Expression` and perform the appropriate action. This avoids the need for `accept` methods in the elements and overloaded `visit` methods in the visitor for each type, but relies on RTTI and can be less clean than true double dispatch.

```cpp
struct ExpressionPrinter {
  ostringstream oss;
  void print(Expression *e) {
    if (auto de = dynamic_cast<DoubleExpression*>(e)) { /* print de */ }
    else if (auto ae = dynamic_cast<AdditionExpression*>(e)) { /* print ae recursively */ }
  }
  string str() const { return oss.str(); }
};
```

### Double Dispatch Visitor (`visitor_double.cpp`)

This example clearly shows double dispatch for an `Expression` hierarchy (DoubleExpression, AdditionExpression, SubtractionExpression).
- `Expression` has `accept(ExpressionVisitor*)`.
- `ExpressionVisitor` has `visit(DoubleExpression*)`, `visit(AdditionExpression*)`, etc.
- `ExpressionPrinter` and `ExpressionEvaluator` are concrete visitors.
The `accept` method in a concrete expression calls the appropriate `visit` method on the visitor, passing `this`.

```cpp
// ... (Expression, DoubleExpression, AdditionExpression with accept methods) ...
// ... (ExpressionVisitor, ExpressionPrinter, ExpressionEvaluator with visit methods) ...

// In AdditionExpression::accept(ExpressionVisitor* visitor):
//   visitor->visit(this); // Calls visitor->visit(AdditionExpression* this)
```

### Acyclic Visitor (`visitor_acyclic.cpp`)

This pattern variant aims to break the dependency cycle that can occur with the classic Visitor (where Elements know Visitors and Visitors know Elements).
- `VisitorBase` is a marker interface.
- `Visitor<T>` is a template for visitors of a specific type `T`.
- `Expression` (and its derivatives) `accept(VisitorBase&)` and use `dynamic_cast` to see if the passed `VisitorBase` is a `Visitor<SpecificExpressionType>`.
- `ExpressionPrinter` inherits from `VisitorBase` and multiple `Visitor<T>` specializations.
This allows adding new Visitable types without changing existing Visitor interfaces, and new Visitors without changing Visitable types, but uses `dynamic_cast`.

```cpp
// template <typename Visitable> struct Visitor { virtual void visit(Visitable& obj) = 0; };
// struct VisitorBase { virtual ~VisitorBase() = default; };
// struct Expression { virtual void accept(VisitorBase& obj) { ... dynamic_cast ... } };
// struct ExpressionPrinter : VisitorBase, Visitor<Expression>, Visitor<AdditionExpression> { ... };
```

### `std::visit` with `std::variant` (`std_visit.cpp`)

This C++17 approach uses `std::variant` to hold different types (e.g., `variant<string, int> house`) and `std::visit` to apply a visitor (which can be a struct with `operator()` overloads or a lambda) to the currently active type in the variant. This is a modern, type-safe way to achieve visitor-like behavior for a closed set of types managed by `std::variant`.

```cpp
// struct AddressPrinter {
//   void operator()(const string& house_name) const;
//   void operator()(const int house_number) const;
// };
// variant<string, int> house = ...;
// std::visit(AddressPrinter{}, house);
```

### Multimethods (`multimethods.cpp`)

This file explores achieving behavior similar to multiple dispatch (where the function called depends on the dynamic type of multiple arguments) using `std::type_index` and a map to simulate collision outcomes between different `GameObject` types (`Planet`, `Asteroid`, `Spaceship`). While not strictly the Visitor pattern, it tackles a related problem of type-dependent behavior.

```cpp
// map<pair<type_index,type_index>, void(*)(void)> outcomes;
// void collide(GameObject& first, GameObject& second) {
//   // lookup in outcomes map based on first.type() and second.type()
// }
```

## Execution Result

(Please provide instructions on how to compile and run these examples. The output will be placed here.)
---

*This file was automatically generated.*
