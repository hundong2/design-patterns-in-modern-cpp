# Null Object Pattern

The Null Object pattern is a behavioral design pattern that provides an object as a surrogate for the lack of an object of a given type. Instead of using a `null` reference to convey absence of an object, one uses an object which implements the expected interface, but whose method body is empty.

The advantage of this approach over a working default implementation is that a null object is very predictable and has no side effects: it does nothing.

## C++ Code Example

The file `null_object.cpp` demonstrates this pattern with a logging example.

### `null_object.cpp`

This file defines a `Log` interface and a concrete `ConsoleLog`. The key part is the `NullLog` struct, which also implements the `Log` interface but its `LogInfo` method does nothing. A `PaymentProcessing` class template can then be instantiated with either `ConsoleLog` for actual logging or `NullLog` when no logging is desired, avoiding null checks for the logger.

*Note: A small correction was made to the original code in this documentation: `log.LogMessage` was changed to `log.LogInfo` to match the interface.*

```cpp
#include <iostream>
#include <string>
#include <type_traits> // Required for std::is_base_of

// Abstract Log interface
struct Log
{
  virtual ~Log() = default; // Good practice to have a virtual destructor
  virtual void LogInfo(const std::string& message) const = 0;
};

// Concrete implementation of Log
struct ConsoleLog : Log
{
  void LogInfo(const std::string& message) const override
  {
    std::cout << message << std::endl;
  }
};

// Null Object implementation of Log
struct NullLog : Log
{
  void LogInfo(const std::string& message) const override
  {
    // Does nothing
  }
};

// Class that uses a logger
template <typename LogType>
struct PaymentProcessing
{
  // Ensure LogType is derived from Log
  static_assert(std::is_base_of<Log, LogType>::value, "LogType must be a Log");

  LogType log; // Can be ConsoleLog or NullLog

  void Process()
  {
    log.LogInfo("Processing payments..."); // Corrected from LogMessage to LogInfo
  }
};

int main()
{
  // Example using ConsoleLog
  PaymentProcessing<ConsoleLog> pp_with_log;
  std::cout << "Processing with ConsoleLog:\n";
  pp_with_log.Process();

  std::cout << "\n";

  // Example using NullLog - no output will be generated from logging
  PaymentProcessing<NullLog> pp_without_log;
  std::cout << "Processing with NullLog:\n";
  pp_without_log.Process();
  // No logging output here, but Process() is called safely.

  // getchar(); // Commented out for non-interactive execution if needed
  return 0;
}

```

## Execution Result

(Please provide instructions on how to compile and run these examples. The output will be placed here.)

If compiled and run, the expected output for the corrected code would be:

```
Processing with ConsoleLog:
Processing payments...

Processing with NullLog:
Processing payments...
```
(Wait, the `NullLog` version should not print "Processing payments..." from the logger. The `log.LogInfo` in `PaymentProcessing::Process` calls the `NullLog::LogInfo` which is empty. The "Processing with NullLog:" line is from `main`.)

Corrected expected output:
```
Processing with ConsoleLog:
Processing payments...

Processing with NullLog:
```

---

*This file was automatically generated.*
