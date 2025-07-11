# Interpreter Pattern

The Interpreter pattern is a behavioral design pattern that provides a way to evaluate language grammar or expressions. This pattern is used to define a grammatical representation for a language and provides an interpreter to deal with this grammar.

It involves implementing an expression interface which tells to interpret a particular context. This pattern is used in SQL parsing, symbol processing engine etc.

## C++ Code Examples

Below are the C++ source files demonstrating different aspects or implementations of the Interpreter pattern, primarily for parsing and evaluating mathematical expressions.

### `InterpreterCodingExercise.cpp`

This file presents an `ExpressionProcessor` that can calculate the result of simple arithmetic expressions involving numbers and single-letter variables. It includes GTest unit tests.

```cpp
#include <map>
#include <string>
#include <vector>
#include <regex>
#include <iostream>
using namespace std;


inline vector<string> split(const string& stringToSplit)
{
  vector<string> result;
  size_t pos = 0, lastPos = 0;
  while ((pos = stringToSplit.find_first_of("+-", lastPos)) != string::npos)
  {
    result.push_back(stringToSplit.substr(lastPos, pos-lastPos+1));
    lastPos = pos+1;
  }
  result.push_back(stringToSplit.substr(lastPos));
  return result;
}

struct ExpressionProcessor
{
  map<char,int> variables;

  enum NextOp
  {
    nothing,
    plus,
    minus
  };

  int calculate(const string& expression)
  {
    int current;
    auto next_op = nothing;

    auto parts = split(expression);

    cout << "parts (" << parts.size() << "): ";
    for (auto& part : parts)
      cout << "`" << part << "` ";
    cout << endl;

    for (auto& part : parts)
    {
      auto no_op = split(part);
      auto first = no_op[0];
      int value, z;

      try
      {
        value = stoi(first);
      }
      catch (const invalid_argument&)
      {
        if (first.length() == 1 &&
            variables.find(first[0]) != variables.end())
        {
          value = variables[first[0]];
        }
        else return 0;
      }

      switch (next_op)
      {
        case nothing:
          current = value;
          break;
        case plus:
          current += value;
          break;
        case minus:
          current -= value;
          break;
      }

      if (*part.rbegin() == '+') next_op = plus;
      else if (*part.rbegin() == '-') next_op = minus;
    }

    return current;
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

  TEST_F(Evaluate, LotsOfAccountTests)
  {
    ExpressionProcessor ep;
    ep.variables['x'] = 5;

    ASSERT_EQ(1, ep.calculate("1"));
    ASSERT_EQ(3, ep.calculate("1+2"));
    ASSERT_EQ(6, ep.calculate("1+x"));
    ASSERT_EQ(0, ep.calculate("1+xy"));
  }
} // namespace

int main(int ac, char* av[])
{
  testing::InitGoogleTest(&ac, av);
  return RUN_ALL_TESTS();
}
```

### `handmade.cpp`

This file implements a more traditional interpreter with distinct lexing and parsing stages.
- **Lexing:** The `lex` function tokenizes an input string into a sequence of `Token` objects (integer, plus, minus, parentheses).
- **Parsing:** The `parse` function builds an expression tree (using `Element`, `Integer`, `BinaryOperation` structures) from the token sequence. The `eval` method on these elements then calculates the result. This example supports parentheses for grouping expressions.

```cpp
#include <iostream>
#include <string>
#include <vector>
#include <cctype>
#include <sstream>
#include <memory>
using namespace std;
#include <boost/lexical_cast.hpp>

// lexing =================================================

struct Token
{
  enum Type { integer, plus, minus, lparen, rparen } type;
  string text;

  explicit Token(Type type, const string& text) :
    type{type}, text{text} {}

  friend ostream& operator<<(ostream& os, const Token& obj)
  {
    return os << "`" << obj.text << "`";
  }
};

vector<Token> lex(const string& input)
{
  vector<Token> result;

  for (int i = 0; i < input.size(); ++i)
  {
    switch (input[i])
    {
    case '+':
      result.push_back(Token{ Token::plus, "+" });
      break;
    case '-':
      result.push_back(Token{ Token::minus, "-" });
      break;
    case '(':
      result.push_back(Token{ Token::lparen, "(" });
      break;
    case ')':
      result.push_back(Token{ Token::rparen, ")" });
      break;
    default:
      // 숫자
      ostringstream buffer;
      buffer << input[i];
      for (int j = i + 1; j < input.size(); ++j)
      {
        if (isdigit(input[j]))
        {
          buffer << input[j];
          ++i;
        }
        else
        {
          result.push_back(Token{ Token::integer, buffer.str() });
          break;
        }
      }
    }
  }

  return result;
}

// parsing =====================================================

struct Element
{
  virtual ~Element() = default;
  virtual int eval() const = 0;
};

struct Integer : Element
{
  int value;
  explicit Integer(const int value)
    : value(value)
  {
  }
  int eval() const override { return value; }
};

struct BinaryOperation : Element
{
  enum Type { addition, subtraction } type;
  shared_ptr<Element> lhs, rhs;

  int eval() const override
  {
    if (type == addition)
      return lhs->eval() + rhs->eval();
    return lhs->eval() - rhs->eval();
  }
};

shared_ptr<Element> parse(const vector<Token>& tokens)
{
  auto result = make_unique<BinaryOperation>();
  bool have_lhs = false;
  for (size_t i = 0; i < tokens.size(); i++)
  {
    auto token = tokens[i];
    switch(token.type)
    {
    case Token::integer:
    {
      int value = boost::lexical_cast<int>(token.text);
      auto integer = make_shared<Integer>(value);
      if (!have_lhs) {
        result->lhs = integer;
        have_lhs = true;
      }
      else result->rhs = integer;
    }
      break;
    case Token::plus:
      result->type = BinaryOperation::addition;
      break;
    case Token::minus:
      result->type = BinaryOperation::subtraction;
      break;
    case Token::lparen:
    {
      int j = i;
      for (; j < tokens.size(); ++j)
        if (tokens[j].type == Token::rparen)
          break; // found it!

      vector<Token> subexpression(&tokens[i + 1], &tokens[j]);
      auto element = parse(subexpression);
      if (!have_lhs)
      {
        result->lhs = element;
        have_lhs = true;
      }
      else result->rhs = element;
      i = j; // advance
    }
    break;
    }
  }
  return result;
}



int main()
{
  string input{ "(13-4)-(12+1)" }; // 중첩된 괄호를 처리할 수 있는지 보자
  auto tokens = lex(input);

  // 토큰 확인
  for (auto& t : tokens)
    cout << t << "   ";
  cout << endl;

  try {
    auto parsed = parse(tokens);
    cout << input << " = " << parsed->eval() << endl;
  }
  catch (const exception& e)
  {
    cout << e.what() << endl;
  }

  getchar();
  return 0;
}
```

## Execution Result

(Please provide instructions on how to compile and run these examples. The output will be placed here.)
---

*This file was automatically generated.*
