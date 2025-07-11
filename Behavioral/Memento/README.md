# Memento Pattern

The Memento pattern is a behavioral design pattern that lets you save and restore the previous state of an object without revealing the details of its implementation.

This is useful for implementing undo/redo functionality or for checkpointing an object's state to allow rollback to a previous stable state.

## C++ Code Examples

Below are C++ source files demonstrating different aspects or implementations of the Memento pattern.

### `MementoCodingExercise.cpp`

This file defines a `TokenMachine` that can add tokens (simple integer values). The `add_token` method returns a `Memento` object that stores the state of the machine (the list of tokens) at that point. The `revert` method can restore the machine to a state captured in a `Memento`. This example focuses on ensuring that the memento stores a deep copy of the state. It includes GTest unit tests.

```cpp
#include <iostream>
#include <vector>
#include <memory>
using namespace std;

struct Token
{
  int value;

  Token(int value) : value(value) {}
};

struct Memento
{
  vector<shared_ptr<Token>> tokens;
};

struct TokenMachine
{
  vector<shared_ptr<Token>> tokens;

  Memento add_token(int value)
  {
    return add_token(make_shared<Token>(value));
  }

  // Adds a token and returns a memento of the current state
  Memento add_token(const shared_ptr<Token>& token)
  {
    tokens.push_back(token);
    Memento m;
    // Create a deep copy for the memento
    for (auto t : tokens)
      m.tokens.emplace_back(make_shared<Token>(t->value));
    return m;
  }

  // Reverts the token machine to the state stored in memento m
  void revert(const Memento& m)
  {
    tokens.clear();
    // Restore from deep copy
    for (auto t : m.tokens)
      tokens.emplace_back(make_shared<Token>(t->value));
  }
};

#include "gtest/gtest.h"
//#include "helpers/iohelper.h"
//#include "exercise.cpp"

namespace {

  class Evaluate : public ::testing::Test {};

  TEST_F(Evaluate, SingleTokenTest) {
    TokenMachine tm;
    auto m = tm.add_token(123);
    tm.add_token(456);
    tm.revert(m);
    ASSERT_EQ(1, tm.tokens.size());
    ASSERT_EQ(123, tm.tokens[0]->value);
  }

  TEST_F(Evaluate, TwoTokenTest)
  {
    TokenMachine tm;
    tm.add_token(1);
    auto m = tm.add_token(2);
    tm.add_token(3);
    tm.revert(m);
    ASSERT_EQ(2, tm.tokens.size());
    ASSERT_EQ(1, tm.tokens[0]->value)
            << "First toke should have value 1, you got "
            << tm.tokens[0]->value;
    ASSERT_EQ(2, tm.tokens[1]->value);
  }

  TEST_F(Evaluate, FiddledTokenTest)
  {
    TokenMachine tm;
    cout << "Made a token with value=111 and kept a reference\n";
    auto token = make_shared<Token>(111);
    cout << "Added this token to the list\n";
    tm.add_token(token);
    auto m = tm.add_token(222);
    cout << "Changed this token's value to 333 :)\n";
    token->value = 333; // Original token modified after memento taken
    tm.revert(m); // Revert to state m

    ASSERT_EQ(2, tm.tokens.size())
      << "At this point, token machine should have exactly "
      << "two tokens, you got " << tm.tokens.size();

    // This assertion checks if the memento stored a snapshot
    // independent of the original token object.
    ASSERT_EQ(111, tm.tokens[0]->value)
      << "You got the token value wrong here. "
      << "Hint: did you init the memento by-value?";
  }

}  // namespace

int main(int ac, char* av[])
{
  //::testing::GTEST_FLAG(catch_exceptions) = false;
  testing::InitGoogleTest(&ac, av);
  return RUN_ALL_TESTS();
}
```

### `memento.cpp`

This file demonstrates two variations of the Memento pattern with a `BankAccount` example:
1.  **Simple Memento**: `BankAccount` class can `deposit` money (returning a `Memento` of the new state) and `restore` to a previous state using a `Memento`. The `Memento` class here is simple and only stores the balance.
2.  **Undo/Redo Memento**: `BankAccount2` class maintains a list of `Memento` objects to support `undo` and `redo` operations. Each deposit creates a memento and adds it to a history.

```cpp
#include <iostream>
#include <string>
#include <vector>
#include <memory>
using namespace std;

// Memento for BankAccount state
class Memento
{
  int balance; // State to be saved
public:
  Memento(int balance)
    : balance(balance)
  {
  }
  // Friend classes can access private members of Memento
  friend class BankAccount;  // For simple restore
  friend class BankAccount2; // For undo/redo
};

// Originator: BankAccount (simple version)
class BankAccount
{
  int balance = 0;
public:
  explicit BankAccount(const int balance)
    : balance(balance)
  {
  }

  // Creates a memento after an operation
  Memento deposit(int amount)
  {
    balance += amount;
    return { balance }; // Return a memento of the current state
  }

  // Restores state from a memento
  void restore(const Memento& m)
  {
    balance = m.balance;
  }

  friend ostream& operator<<(ostream& os, const BankAccount& obj)
  {
    return os << "balance: " << obj.balance;
  }
};

// Originator: BankAccount2 (with undo/redo history)
class BankAccount2
{
  int balance = 0;
  vector<shared_ptr<Memento>> changes; // History of mementos
  int current; // Index of the current state in 'changes'

public:
  explicit BankAccount2(const int balance)
  : balance(balance)
  {
    // Initial state
    changes.emplace_back(make_shared<Memento>(balance));
    current = 0;
  }

  // Deposit money, save state, and advance current pointer
  shared_ptr<Memento> deposit(int amount)
  {
    balance += amount;
    auto m = make_shared<Memento>(balance);
    changes.push_back(m);
    ++current;
    return m;
  }

  // Restore to a specific memento (less common for typical undo/redo)
  // This effectively makes the provided memento the current state,
  // and potentially truncates redo history if not handled carefully.
  void restore(const shared_ptr<Memento>& m)
  {
    if (m)
    {
      balance = m->balance;
      changes.push_back(m); // Adds this restored state as a new point in history
      current = changes.size() - 1;
    }
  }

  // Undo to the previous state
  shared_ptr<Memento> undo()
  {
    if (current > 0)
    {
      --current;
      auto m = changes[current];
      balance = m->balance;
      return m;
    }
    return{}; // No more undos
  }

  // Redo to the next state
  shared_ptr<Memento> redo()
  {
    if (current + 1 < changes.size())
    {
      ++current;
      auto m = changes[current];
      balance = m->balance;
      return m;
    }
    return{}; // No more redos
  }

  friend ostream& operator<<(ostream& os, const BankAccount2& obj)
  {
    return os << "balance: " << obj.balance;
  }
};

void memento_example() // Renamed from memento to avoid conflict
{
  BankAccount ba{ 100 };
  auto m1 = ba.deposit(50); // balance: 150
  auto m2 = ba.deposit(25); // balance: 175
  cout << ba << "\n";

  // undo to m1 (state after first deposit)
  ba.restore(m1);
  cout << ba << "\n"; // balance: 150

  // redo to m2 (state after second deposit)
  ba.restore(m2);
  cout << ba << "\n"; // balance: 175
}

void undo_redo_example() // Renamed from undo_redo
{
  BankAccount2 ba{ 100 };
  ba.deposit(50); // balance: 150, current: 1
  ba.deposit(25); // balance: 175, current: 2
  cout << ba << "\n";

  ba.undo();
  cout << "Undo 1: " << ba << "\n"; // balance: 150, current: 1
  ba.undo();
  cout << "Undo 2: " << ba << "\n"; // balance: 100, current: 0
  ba.redo();
  cout << "Redo 1: " << ba << "\n"; // balance: 150, current: 1 (Note: text was "Redo 2", corrected to "Redo 1")
  ba.redo();
  cout << "Redo 2: " << ba << "\n"; // balance: 175, current: 2

  // Example of further undo
  ba.undo();
  cout << "Undo after Redo: " << ba << "\n"; // balance: 150, current: 1
}

int main()
{
  cout << "Simple Memento Example:\n";
  memento_example();
  cout << "\nUndo/Redo Example:\n";
  undo_redo_example();

  getchar();
  return 0;
}
```

## Execution Result

(Please provide instructions on how to compile and run these examples. The output will be placed here.)
---

*This file was automatically generated.*
