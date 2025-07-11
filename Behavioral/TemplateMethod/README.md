# Template Method Pattern

The Template Method pattern is a behavioral design pattern that defines the skeleton of an algorithm in a superclass but lets subclasses override specific steps of the algorithm without changing its structure.

This pattern allows subclasses to redefine certain steps of an algorithm without changing the algorithm's overall structure.

## C++ Code Examples

This directory provides two examples of the Template Method pattern.

### `TemplateMethodCodingExercise.cpp` (Card Game Combat)

This example implements a `CardGame` where the overall structure of a `combat` between two creatures is defined, but the specifics of how a `hit` is handled (damage calculation) are deferred to subclasses.
- `CardGame` is an abstract class with a `combat` method that calls the `hit` method.
- `hit` is a pure virtual function (the customizable step).
- `TemporaryCardDamageGame`: Implements `hit` such that damage is temporary (health reverts if the creature survives the hit).
- `PermanentCardDamageGame`: Implements `hit` such that damage is permanent.

The `combat` method is the template method, and `hit` is the step that subclasses customize.

```cpp
#include <iostream>
#include <vector>
// #include <complex> // Not used in this specific exercise code
// #include <tuple>   // Not used in this specific exercise code
using namespace std;

struct Creature
{
    int attack, health;

    Creature(int attack, int health) : attack(attack), health(health) {}
};

// Abstract Base Class defining the template method
struct CardGame
{
    vector<Creature> creatures;

    CardGame(const vector<Creature> &creatures) : creatures(creatures) {}
    virtual ~CardGame() = default; // Good practice: virtual destructor

    // Template Method
    // Defines the skeleton of the combat algorithm
    int combat(int creature1_idx, int creature2_idx)
    {
      Creature& first = creatures[creature1_idx];
      Creature& second = creatures[creature2_idx];

      // Call to customizable step
      hit(first, second);
      // Call to customizable step
      hit(second, first);

      bool first_alive = first.health > 0;
      bool second_alive = second.health > 0;

      if (first_alive == second_alive) return -1; // Draw or both dead
      return first_alive ? creature1_idx : creature2_idx; // Return winner index
    }

    // Abstract step to be implemented by subclasses
    virtual void hit(Creature& attacker, Creature& other) = 0;
};

// Concrete subclass 1
struct TemporaryCardDamageGame : CardGame
{
    TemporaryCardDamageGame(const vector<Creature> &creatures) : CardGame(creatures) {}

    // Implementation of the customizable step
    void hit(Creature &attacker, Creature &other) override {
      auto old_health = other.health;
      other.health -= attacker.attack;
      if (other.health > 0) // If survived
        other.health = old_health; // Health reverts (damage was temporary)
    }
};

// Concrete subclass 2
struct PermanentCardDamageGame : CardGame
{
    PermanentCardDamageGame(const vector<Creature> &creatures) : CardGame(creatures) {}

    // Implementation of the customizable step
    void hit(Creature &attacker, Creature &other) override
    {
      other.health -= attacker.attack; // Damage is permanent
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

### `template_method.cpp` (General Game Execution)

This file shows a more general `Game` class that has a `run` method. The `run` method is the template method, outlining the sequence of game operations: `start`, loop `take_turn` until `have_winner`, then `get_winner`. These individual operations are abstract and implemented by concrete game subclasses like `Chess`.

```cpp
#include <iostream>
#include <string>
using namespace std;

// Abstract Base Class
class Game
{
public:
	explicit Game(int number_of_players)
		: number_of_players(number_of_players)
	{
	}
    virtual ~Game() = default; // Good practice: virtual destructor

	// Template Method
	void run()
	{
		start(); // Customizable step
		while (!have_winner()) // Customizable step
			take_turn(); // Customizable step
		cout << "Player " << get_winner() << " wins.\n"; // Customizable step
	}

protected:
	// Abstract steps to be implemented by subclasses
	virtual void start() = 0;
	virtual bool have_winner() = 0;
	virtual void take_turn() = 0;
	virtual int get_winner() = 0;

	int current_player{ 0 };
	int number_of_players;
};

// Concrete Subclass
class Chess : public Game
{
public:
	explicit Chess() : Game{ 2 } {} // Chess has 2 players

protected:
	// Implementation of customizable steps
	void start() override
	{
		cout << "Starting a game of chess with " << number_of_players << " players\n";
        current_player = 0; // Reset current player for Chess
        turns = 0; // Reset turns for Chess
	}

	bool have_winner() override
	{
		return turns == max_turns; // Game ends after max_turns
	}

	void take_turn() override
	{
		cout << "Turn " << turns << " taken by player " << current_player << "\n";
		turns++;
		current_player = (current_player + 1) % number_of_players;
	}

	int get_winner() override
	{
        // In this simple Chess game, the winner is just the player whose turn it would have been
        // if the game continued, or simply the one who didn't make the "last" move.
        // For a real game, winner logic would be more complex.
        // Here, it implies the player *before* current_player (after increment) made the last move
        // or based on game rules. The example returns `current_player` which might be ambiguous.
        // Let's assume the "winner" is the player whose turn it is when have_winner becomes true.
		return current_player;
	}

private:
	int turns{ 0 };
    int max_turns{ 10 }; // Game ends after 10 turns for simplicity
};

int main() // Example Usage
{
	Chess chess;
	chess.run();

	// getchar(); // Commented for non-interactive
	return 0;
}
```

## Execution Result

(Please provide instructions on how to compile and run these examples. The output will be placed here.)
---

*This file was automatically generated.*
