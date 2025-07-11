# Strategy Pattern

The Strategy pattern is a behavioral design pattern that enables selecting an algorithm at runtime. Instead of implementing a single algorithm directly, code receives runtime instructions as to which in a family of algorithms to use.

This pattern defines a family of algorithms, encapsulates each algorithm, and makes them interchangeable. Strategy lets the algorithm vary independently from clients that use it.

## C++ Code Examples

This directory contains examples of both dynamic and static strategy selection.

### `StrategyCodingExercise.cpp` (Quadratic Equation Solver)

This example demonstrates the Strategy pattern for solving quadratic equations (`ax^2 + bx + c = 0`).
- `DiscriminantStrategy` is an interface for calculating the discriminant (`b^2 - 4ac`).
- `OrdinaryDiscriminantStrategy` calculates it directly, allowing for complex roots.
- `RealDiscriminantStrategy` returns NaN if the discriminant is negative, indicating no real roots.
- `QuadraticEquationSolver` takes a `DiscriminantStrategy` to customize its solving behavior.

This is an example of **dynamic strategy** selection, as the strategy is provided to the solver at runtime.

```cpp
#include <iostream>
#include <vector>
#include <complex>
#include <tuple>
#include <cmath> // For std::sqrt, std::isnan
#include <limits> // For std::numeric_limits

using namespace std;

// Strategy Interface
struct DiscriminantStrategy
{
    virtual double calculate_discriminant(double a, double b, double c) = 0;
    virtual ~DiscriminantStrategy() = default;
};

// Concrete Strategy 1: Standard discriminant calculation
struct OrdinaryDiscriminantStrategy : DiscriminantStrategy
{
    double calculate_discriminant(double a, double b, double c) override {
      return b*b - 4*a*c;
    }
};

// Concrete Strategy 2: Discriminant calculation for real roots only
struct RealDiscriminantStrategy : DiscriminantStrategy
{
    double calculate_discriminant(double a, double b, double c) override {
      double result = b*b - 4*a*c;
      return result >= 0 ? result : numeric_limits<double>::quiet_NaN();
    }
};

// Context class
class QuadraticEquationSolver
{
    DiscriminantStrategy& strategy;
public:
    QuadraticEquationSolver(DiscriminantStrategy &strategy) : strategy(strategy) {}

    tuple<complex<double>, complex<double>> solve(double a, double b, double c)
    {
      // Use the strategy to calculate discriminant
      double disc_val = strategy.calculate_discriminant(a,b,c);
      complex<double> disc{disc_val, 0};

      // If strategy returned NaN, propagate NaN
      if (std::isnan(disc_val)) {
          complex<double> nan_val (numeric_limits<double>::quiet_NaN(), numeric_limits<double>::quiet_NaN());
          return make_tuple(nan_val, nan_val);
      }

      auto root_disc = sqrt(disc);
      return {
          (-b+root_disc) / (2*a),
          (-b-root_disc) / (2*a)
      };
    };
};

#include "gtest/gtest.h"
// ... (GTest code from file, ensure isnan checks are correct for complex numbers) ...

int main(int ac, char* av[])
{
  testing::InitGoogleTest(&ac, av);
  return RUN_ALL_TESTS();
}
```
*Note: The `solve` method was slightly adjusted to handle NaN propagation from `RealDiscriminantStrategy` more explicitly for complex results.*

### `strategy_dynamic.cpp` (Dynamic List Formatting)

This example shows a `TextProcessor` that can format a list of strings into different output formats (Markdown or HTML).
- `ListStrategy` is an interface defining how list items are added and how the list starts/ends.
- `MarkdownListStrategy` and `HtmlListStrategy` are concrete strategies.
- The `TextProcessor` holds a `unique_ptr<ListStrategy>` and can switch strategies at runtime using `set_output_format`.

```cpp
#include <iostream>
#include <string>
#include <sstream>
#include <memory>
#include <vector>
#include <stdexcept> // For std::runtime_error
using namespace std;

enum class OutputFormat
{
  Markdown,
  Html
};

// Strategy Interface
struct ListStrategy
{
  virtual ~ListStrategy() = default;
  virtual void add_list_item(ostringstream& oss, const string& item) {};
  virtual void start(ostringstream& oss) {};
  virtual void end(ostringstream& oss) {};
};

// Concrete Strategy: Markdown
struct MarkdownListStrategy : ListStrategy
{
  void add_list_item(ostringstream& oss, const string& item) override
  {
    oss << " * " << item << endl;
  }
};

// Concrete Strategy: HTML
struct HtmlListStrategy : ListStrategy
{
  void start(ostringstream& oss) override
  {
    oss << "<ul>" << endl;
  }

  void end(ostringstream& oss) override
  {
    oss << "</ul>" << endl;
  }

  void add_list_item(ostringstream& oss, const string& item) override
  {
    oss << "<li>" << item << "</li>" << endl;
  }
};

// Context
struct TextProcessor
{
  void clear()
  {
    oss.str("");
    oss.clear();
  }
  void append_list(const vector<string> items)
  {
    if (!list_strategy) throw runtime_error("List strategy not set.");
    list_strategy->start(oss);
    for (auto& item : items)
      list_strategy->add_list_item(oss, item);
    list_strategy->end(oss);
  }

  void set_output_format(const OutputFormat format)
  {
    switch(format)
    {
    case OutputFormat::Markdown:
      list_strategy = make_unique<MarkdownListStrategy>();
      break;
    case OutputFormat::Html:
      list_strategy = make_unique<HtmlListStrategy>();
      break;
    default:
      throw runtime_error("Unsupported strategy.");
    }
  }
  string str() const { return oss.str(); }
private:
  ostringstream oss;
  unique_ptr<ListStrategy> list_strategy;
};

int main_() // Example Usage
{
  TextProcessor tp;
  tp.set_output_format(OutputFormat::Markdown);
  tp.append_list({"foo", "bar", "baz"});
  cout << tp.str() << endl;

  tp.clear();
  tp.set_output_format(OutputFormat::Html);
  tp.append_list({"foo", "bar", "baz"});
  cout << tp.str() << endl;

  // getchar(); // Commented for non-interactive
  return 0;
}
```

### `strategy_static.cpp` (Static List Formatting)

This example is similar to `strategy_dynamic.cpp` but uses **static strategy** selection. The `TextProcessor` is a template class parameterized by the list strategy type (`LS`). The specific strategy (`MarkdownListStrategy` or `HtmlListStrategy`) is determined at compile time.

```cpp
#include <iostream>
#include <string>
#include <sstream>
#include <memory> // Not strictly needed here as strategy is a member object
#include <vector>
using namespace std;

// OutputFormat enum (can be omitted if only static strategy is used)
// enum class OutputFormat { Markdown, Html };

// Strategy Interface (can be a struct with non-virtual methods for static strategy)
struct ListStrategy
{
  // For static strategy, these don't strictly need to be virtual
  // but defining a common interface structure can still be useful.
  virtual void add_list_item(ostringstream& oss, const string& item) = 0;
  virtual void start(ostringstream& oss) = 0;
  virtual void end(ostringstream& oss) = 0;
  virtual ~ListStrategy() = default;
};

// Concrete Strategy: Markdown
struct MarkdownListStrategy : ListStrategy
{
  void start(ostringstream& oss) override {}
  void end(ostringstream& oss) override {}
  void add_list_item(ostringstream& oss, const string& item) override
  {
    oss << " * " << item << endl;
  }
};

// Concrete Strategy: HTML
struct HtmlListStrategy : ListStrategy
{
  void start(ostringstream& oss) override
  {
    oss << "<ul>" << endl;
  }
  void end(ostringstream& oss) override
  {
    oss << "</ul>" << endl;
  }
  void add_list_item(ostringstream& oss, const string& item) override
  {
    oss << "<li>" << item << "</li>" << endl;
  }
};

// Context (template parameterized by strategy type)
template <typename LS> // LS is the List Strategy type
struct TextProcessor
{
  void clear()
  {
    oss.str("");
    oss.clear();
  }
  void append_list(const vector<string> items)
  {
    list_strategy.start(oss); // Calls the specific strategy's method
    for (auto& item : items)
      list_strategy.add_list_item(oss, item);
    list_strategy.end(oss);
  }
  string str() const { return oss.str(); }
private:
  ostringstream oss;
  LS list_strategy; // Strategy object is a member, type determined at compile time
};

int main() // Example Usage
{
  TextProcessor<MarkdownListStrategy> tpm;
  tpm.append_list({"foo", "bar", "baz"});
  cout << tpm.str() << endl;

  TextProcessor<HtmlListStrategy> tph;
  tph.append_list({"foo", "bar", "baz"});
  cout << tph.str() << endl;

  // getchar(); // Commented for non-interactive
  return 0;
}
```

## Execution Result

(Please provide instructions on how to compile and run these examples. The output will be placed here.)
---

*This file was automatically generated.*
