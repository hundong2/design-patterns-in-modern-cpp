# Command Pattern

The Command pattern is a behavioral design pattern that turns a request into a stand-alone object that contains all information about the request. This transformation lets you parameterize methods with different requests, delay or queue a request's execution, and support undoable operations.

## C++ Code Examples

Below are the C++ source files demonstrating different aspects or implementations of the Command pattern, often in the context of bank account operations.

### `CommandCodingExercise.cpp`

This file provides a basic structure for a `Command` that can be processed by an `Account`, with support for deposit and withdraw actions. It includes GTest unit tests.

```cpp
#include <iostream>
#include <vector>
using namespace std;

struct Command
{
  enum Action { deposit, withdraw } action;
  int amount{0};
  bool success{false};
};

struct Account
{
  int balance{0};

  void process(Command& cmd)
  {
    switch (cmd.action)
    {
      case Command::deposit:
        balance += cmd.amount;
        cmd.success = true;
        break;
      case Command::withdraw:
        cmd.success = (balance >= cmd.amount);
        if (cmd.success) balance -= cmd.amount;
        break;
    }
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
    Account a;
    Command command{Command::deposit, 100};
    a.process(command);

    ASSERT_EQ(100, a.balance);
    ASSERT_TRUE(command.success);

    command = Command{Command::withdraw, 50};
    a.process(command);

    ASSERT_EQ(50, a.balance);
    ASSERT_TRUE(command.success);

    command = Command{Command::withdraw, 150};
    a.process(command);

    ASSERT_EQ(50, a.balance);
    ASSERT_FALSE(command.success);
  }
} // namespace

int main(int ac, char* av[])
{
  testing::InitGoogleTest(&ac, av);
  return RUN_ALL_TESTS();
}
```

### `command.cpp`

This file defines a `BankAccount` and a `Command` interface (`BankAccountCommand`) for deposit and withdraw operations, including an `undo` capability. It also introduces a `CompositeBankAccountCommand` to group multiple commands.

```cpp
#include <iostream>
#include <string>
#include <vector>
using namespace std;

struct BankAccount
{
  int balance = 0;
  int overdraft_limit = -500;

  void deposit(int amount)
  {
    balance += amount;
    cout << "deposited " << amount << ", balance now " <<
      balance << "\n";
  }

  void withdraw(int amount)
  {
    if (balance - amount >= overdraft_limit)
    {
      balance -= amount;
      cout << "withdrew " << amount << ", balance now " <<
        balance << "\n";
    }
  }
};

struct Command
{
  virtual ~Command() = default;
  virtual void call() const = 0;
  virtual void undo() const = 0;
};

// should really be BankAccountCommand
struct BankAccountCommand : Command
{
  BankAccount& account;
  enum Action { deposit, withdraw } action;
  int amount;

  BankAccountCommand(BankAccount& account,
    const Action action, const int amount)
    : account(account), action(action), amount(amount) {}

  void call() const override
  {
    switch (action)
    {
    case deposit:
      account.deposit(amount);
      break;
    case withdraw:
      account.withdraw(amount);
      break;
    default: break;
    }
  }

  void undo() const override
  {
    switch (action)
    {
    case withdraw:
      account.deposit(amount);
      break;
    case deposit:
      account.withdraw(amount);
      break;
    default: break;
    }
  }
};

// vector는 버추얼 소멸자가 없다. 어쩌겠는가? ...
struct CompositeBankAccountCommand
  : vector<BankAccountCommand>, Command
{
  CompositeBankAccountCommand(const initializer_list<value_type>& items)
    : vector<BankAccountCommand>(items) {}

  void call() const override
  {
    for (auto& cmd : *this)
      cmd.call();
  }

  void undo() const override
  {
    for (auto& cmd : *this)
      cmd.undo();
  }
};

int main_987()
{
  BankAccount ba;
  /*vector<BankAccountCommand> commands{*/
  CompositeBankAccountCommand commands {
    BankAccountCommand{ba, BankAccountCommand::deposit, 100},
    BankAccountCommand{ba, BankAccountCommand::withdraw, 200}
  };

  cout << ba.balance << endl;

  // 모든 명령을 적용
  /*for (auto& cmd : commands)
  {
    cmd.call();
  }*/
  commands.call();

  cout << ba.balance << endl;

  /*for_each(commands.rbegin(), commands.rend(),
    [](const BankAccountCommand& cmd) { cmd.undo(); });*/
  commands.undo();

  cout << ba.balance << endl;

  getchar();
  return 0;
}
```

### `command_composite.cpp`

This file expands on the composite command idea, introducing `DependentCompositeCommand` where commands might only execute if previous ones succeeded, and `MoneyTransferCommand` as a specific example of a dependent composite command.

```cpp
#include <iostream>
#include <string>
#include <memory>
#include <vector>
#include <algorithm>
using namespace std;

struct BankAccount
{
  int balance = 0;
  int overdraft_limit = -500;

  void deposit(int amount)
  {
    balance += amount;
    cout << "deposited " << amount << ", balance now " <<
      balance << "\n";
  }

  bool withdraw(int amount)
  {
    if (balance - amount >= overdraft_limit)
    {
      balance -= amount;
      cout << "withdrew " << amount << ", balance now " <<
        balance << "\n";
      return true;
    }
    return false;
  }
};

struct Command
{
  bool succeeded;
  virtual void call() = 0;
  virtual void undo() = 0;
};

// should really be BankAccountCommand
struct BankAccountCommand : Command
{
  BankAccount& account;
  enum Action { deposit, withdraw } action;
  int amount;

  BankAccountCommand(BankAccount& account, const Action action,
    const int amount)
    : account(account),
      action(action), amount(amount)
  {
    succeeded = false;
  }

  void call() override
  {
    switch (action)
    {
    case deposit:
      account.deposit(amount);
      succeeded = true;
      break;
    case withdraw:
      succeeded = account.withdraw(amount);
      break;
    }
  }

  void undo() override
  {
    if (!succeeded) return;

    switch (action)
    {
    case withdraw:
      if (succeeded)
        account.deposit(amount);
      break;
    case deposit:
      account.withdraw(amount);
      break;
    }
  }
};

// vector doesn't have virtual dtor, but who cares?
struct CompositeBankAccountCommand : vector<BankAccountCommand>, Command
{
  CompositeBankAccountCommand(const initializer_list<value_type>& _Ilist)
    : vector<BankAccountCommand>(_Ilist)
  {
  }

  void call() override
  {
    for (auto& cmd : *this)
      cmd.call();
  }

  void undo() override
  {
    for (auto it = rbegin(); it != rend(); ++it)
      it->undo();
  }
};

struct DependentCompositeCommand : CompositeBankAccountCommand
{
  explicit DependentCompositeCommand(
    const initializer_list<value_type>& _Ilist)
    : CompositeBankAccountCommand{ _Ilist } {}

  void call() override
  {
    bool ok = true;
    for (auto& cmd : *this)
    {
      if (ok)
      {
        cmd.call();
        ok = cmd.succeeded;
      }
      else
      {
        cmd.succeeded = false;
      }
    }
  }
};

struct MoneyTransferCommand : DependentCompositeCommand
{
  MoneyTransferCommand(BankAccount& from,
    BankAccount& to, int amount):
    DependentCompositeCommand
    {
      BankAccountCommand{from, BankAccountCommand::withdraw, amount},
      BankAccountCommand{to, BankAccountCommand::deposit, amount}
    } {}
};


int main()
{
  BankAccount ba;
  /*vector<BankAccountCommand> commands{*/
  CompositeBankAccountCommand commands{
    BankAccountCommand{ ba, BankAccountCommand::deposit, 100 },
    BankAccountCommand{ ba, BankAccountCommand::withdraw, 200 }
  };

  cout << ba.balance << endl;

  // apply all the commands
  /*for (auto& cmd : commands)
  {
  cmd.call();
  }*/
  commands.call();

  cout << ba.balance << endl;

  /*for_each(commands.rbegin(), commands.rend(),
  [](const BankAccountCommand& cmd) { cmd.undo(); });*/
  commands.undo();

  cout << ba.balance << endl;

  getchar();
  return 0;
}
```

### `command_undo.cpp`

This file focuses on the undo mechanism for bank account commands. It shows a list of commands being executed and then undone in reverse order.

```cpp
#include <iostream>
#include <string>
#include <vector>

using namespace std;

struct BankAccount
{
  int balance{0};
  int overdraft_limit{-500};

  void deposit(int amount)
  {
    balance += amount;
    cout << "deposited " << amount
         << ", balance is now " << balance << endl;
  }

  bool withdraw(int amount)
  {
    if (balance - amount >= overdraft_limit)
    {
      balance -= amount;
      cout << "withdrew " << amount
           << ", balance is now " << balance << endl;
      return true;
    }
    return false;
  }

  friend ostream &operator<<(ostream &os, const BankAccount &account) {
    os << "balance: " << account.balance;
    return os;
  }
};

struct Command
{
  bool succeeded;
  virtual void call() = 0;
  virtual void undo() = 0;
};

struct BankAccountCommand : Command
{
  BankAccount& account;
  enum Action { deposit, withdraw } action;
  int amount;

  BankAccountCommand(BankAccount &account, Action action, int amount) : account(account), action(action),
                                                                        amount(amount) {
    succeeded = false;
  }

  void call() override {
    switch (action)
    {
      case deposit:
        account.deposit(amount);
        succeeded = true;
        break;
      case withdraw:
        succeeded = account.withdraw(amount);
        break;
    }
  }

  void undo() override {
    if (!succeeded) return;

    switch (action)
    {
      case deposit:
        account.withdraw(amount);
        break;
      case withdraw:
        account.deposit(amount);
        break;
    }
  }


};

int main()
{
  BankAccount ba;

  vector<BankAccountCommand> commands
    {
      BankAccountCommand{ba, BankAccountCommand::deposit, 100},
      BankAccountCommand{ba, BankAccountCommand::withdraw, 200}
    };

  cout << ba << endl;

  for (auto& cmd : commands)
    cmd.call();

  for (auto it = commands.rbegin(); it != commands.rend(); ++it)
  {
    it->undo();
  }

  cout << ba << endl;

  return 0;
}
```

## Execution Result

(Please provide instructions on how to compile and run these examples. The output will be placed here.)
---

*This file was automatically generated.*
