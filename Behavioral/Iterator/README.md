# Iterator Pattern

The Iterator pattern is a behavioral design pattern that lets you traverse elements of a collection without exposing its underlying representation (like list, stack, tree, etc.).

It provides a way to access the elements of an aggregate object sequentially without exposing its underlying structure.

## C++ Code Examples

Below are the C++ source files and a header file demonstrating different aspects or implementations of the Iterator pattern, including tree traversal and custom list iteration.

### `IteratorCodingExercise.cpp`

This file defines a `Node` structure for a binary tree and implements a `preorder_traversal` method. While not a classic external iterator, it demonstrates a common traversal algorithm that iterators often encapsulate. It includes GTest unit tests.

```cpp
#include <iostream>
#include <vector>
using namespace std;

template <typename T>
struct Node
{
    T value;
    Node *left{nullptr}, *right{nullptr}, *parent{nullptr};

    Node(T value) : value(value) {}

    Node(T value, Node<T> *left, Node<T> *right) : value(value), left(left), right(right) {
      left->parent = right->parent = this;
    }

    void preorder_traversal_impl(Node<T>* current, vector<Node<T>*>& result)
    {
      result.push_back(current);
      if (current->left)
      {
        preorder_traversal_impl(current->left, result);
      }
      if (current->right)
      {
        preorder_traversal_impl(current->right, result);
      }
    }

    // traverse the node and its children preorder
    // and put all the results into `result`
    void preorder_traversal(vector<Node<T>*>& result)
    {
      preorder_traversal_impl(this, result);
    }
};

#include "gtest/gtest.h"

//#include "helpers/iohelper.h"

//#include "exercise.cpp"

namespace {

    class Evaluate : public ::testing::Test {};

    TEST_F(Evaluate, ExampleTest) {
      Node<char> c{'c'};
      Node<char> d{'d'};
      Node<char> e{'e'};
      Node<char> b{'b', &c, &d};
      Node<char> a{'a', &b, &e};

      vector<Node<char>*> result;
      a.preorder_traversal(result);

      ostringstream oss;
      for (auto n : result)
        oss << n->value;
      ASSERT_EQ("abcde", oss.str());
    }

}  // namespace

int main(int ac, char* av[])
{
  //::testing::GTEST_FLAG(catch_exceptions) = false;
  testing::InitGoogleTest(&ac, av);
  return RUN_ALL_TESTS();
}
```

### `iterator.cpp`

This file implements a `BinaryTree` class with a custom `PreOrderIterator`. It demonstrates how to create iterators (`begin`, `end` methods) that allow range-based for loops. It also shows an example of post-order traversal using C++ coroutines (`std::experimental::generator`), relying on `recursive_generator.h`.

```cpp
#include <iostream>
#include <string>
#include <vector>
#include <memory>
#include <experimental/coroutine>
#include <experimental/generator>
using namespace std;

#include "recursive_generator.h"

template <typename T> struct BinaryTree;

// todo: 전체 트리가 아니라 부모를 참조하도록 리펙토링
template <typename T> struct Node
{
  T value = T();
  Node<T> *left = nullptr;
  Node<T> *right = nullptr;
  Node<T> *parent = nullptr;
  BinaryTree<T>* tree = nullptr;

  explicit Node(const T& value)
    : value(value)
  {
  }

  Node(const T& value, Node<T>* const left, Node<T>* const right)
    : value(value),
      left(left),
      right(right)
  {
    this->left->tree = this->right->tree = tree;
    this->left->parent = this->right->parent = this;
  }

  void set_tree(BinaryTree<T>* t)
  {
    tree = t;
    if (left) left->set_tree(t);
    if (right) right->set_tree(t);
  }

  ~Node()
  {
    if (left) delete left;
    if (right) delete right;
  }
};

template <typename T> struct BinaryTree
{
  Node<T>* root = nullptr;

  explicit BinaryTree(Node<T>* const root)
    : root{ root }, pre_order{ *this }
  {
    root->set_tree(this);
  }

  ~BinaryTree() { if (root) delete root; }

  template <typename U>
  struct PreOrderIterator
  {
    Node<U>* current;

    explicit PreOrderIterator(Node<U>* current)
      : current(current)
    {
    }

    bool operator!=(const PreOrderIterator<U>& other)
    {
      return current != other.current;
    }

    // C++에는 C#의 continuation 기능이 없다
    PreOrderIterator<U>& operator++()
    {
      if (current->right)
      {
        current = current->right;
        while (current->left)
          current = current->left;
      }
      else
      {
        Node<T>* p = current->parent;
        while (p && current == p->right)
        {
          current = p;
          p = p->parent;
        }
        current = p;
      }
      return *this;
    }

    Node<U>& operator*() { return *current; }
  };

  typedef PreOrderIterator<T> iterator;

  iterator end()
  {
    return iterator{ nullptr };
  }

  iterator begin()
  {
    Node<T>* n = root;

    if (n)
      while (n->left)
        n = n->left;
    return iterator{ n };
  }

  // 순회 객체로서 노출
  // todo: 중위 순위 순회로 바꾸기
  class pre_order_traversal
  {
    BinaryTree<T>& tree;
  public:
    pre_order_traversal(BinaryTree<T>& tree) : tree{tree} {}
    iterator begin() { return tree.begin(); }
    iterator end() { return tree.end(); }
  } pre_order;

  // todo: 재귀 코루틴을 이용해 후위 순위 반복자 만들기

  experimental::generator<Node<T>*> post_order()
  {
    return post_order_impl(root);
  }

private:
  // 또는 recursive_generator를 사용
  experimental::generator<Node<T>*> post_order_impl(Node<T>* node)
  {
    if (node)
    {
      for (auto x : post_order_impl(node->left))
        co_yield x;
      for (auto y : post_order_impl(node->right))
        co_yield y;
      co_yield node;
    }
  }
};

void std_iterators()
{
  vector<string> names{ "john", "jane", "jill", "jack" };

  vector<string>::iterator it = names.begin(); // or begin(names)
  cout << "first name is " << *it << "\n";

  ++it; // advance the iterator
  it->append(string(" goodall"));
  cout << "second name is " << *it << "\n";

  while (++it != names.end())
  {
    cout << "another name: " << *it << "\n";
  }

  // vector 전체를 거꾸로 순회
  // 노트: rbegin/rend는 글로벌 함수임, 그리고 -- 가 아니라 ++ 임
  // expand auto here
  for (auto ri = rbegin(names); ri != rend(names); ++ri)
  {
    cout << *ri;
    if (ri + 1 != rend(names)) // iterator arithmetic
      cout << ", ";
  }
  cout << endl;

  // constant iterators
  vector<string>::const_reverse_iterator jack = crbegin(names);
  // won't work
  //*jack += "reacher";

  for (auto& name : names)
    cout << "name = " << name << "\n";
}

// 중위 순서 순회
void binary_tree_iterator()
{
  //         me
  //        /  \
  //   mother   father
  //      / \
  //   m'm   m'f

  BinaryTree<string> family{
    new Node<string>{"me",
      new Node<string>{"mother",
        new Node<string>{"mother's mother"},
        new Node<string>{"mother's father"}
      },
      new Node<string>{"father"}
    }
  };

  // 전위 순서 순회
  for (auto it = family.begin(); it != family.end(); ++it)
  {
    cout << (*it).value << "\n";
  }

  cout << "=== and now, through a dedicated object:\n";

  // 반복자 이름 사용
  for (const auto& it: family.pre_order)
  {
    cout << it.value << "\n";
  }

  cout << "=== postorder travesal with coroutines:\n";

  // 코루틴 사용 (포인터 중간 결과!)
  // postorder: m'm, m'f m f me
  for (auto it: family.post_order())
  {
    cout << it->value << endl;
  }
}


int main()
{
  //std_iterators();
  binary_tree_iterator();

  getchar();
  return 0;
}
```

### `facade.cpp`

This file uses `boost::iterator_facade` to simplify the creation of a custom iterator (`ListIterator`) for a simple singly-linked list structure (`Node`). This demonstrates how libraries can help in implementing the Iterator pattern.

```cpp
#include <iostream>
#include <string>
#include <algorithm>
using namespace std;

#include <boost/iterator/iterator_facade.hpp>


struct Node
{
  string value;
  Node* next = nullptr;

  explicit Node(const string& value)
    : value(value)
  {
  }


  Node(const string& value, Node* const parent)
    : value(value)
  {
    parent->next = this;
  }
};

struct ListIterator : boost::iterator_facade<ListIterator,
Node, boost::forward_traversal_tag>
{
  Node* current = nullptr;


  ListIterator()
  {
  }

  explicit ListIterator(Node* const current)
    : current(current)
  {
  }

private:
  friend class boost::iterator_core_access;

  void increment() { current = current->next; }

  bool equal(const ListIterator& other) const
  { return other.current == current; };

  Node& dereference() const
  { return *current; }
};

int main_0()
{
  Node alpha{ "alpha" };
  Node beta{ "beta", &alpha};
  Node gamma{ "gamma", &beta };

  for_each(ListIterator{ &alpha }, ListIterator{},
  [](const Node& n)
  {
    cout << n.value << endl;
  });

  getchar();
  return 0;
}
```

### `recursive_generator.h`

This header file provides a `recursive_generator` class template that uses C++ coroutines (`std::experimental::coroutine`) to implement generators. Generators are a powerful way to implement iterator-like behavior, especially for complex or recursive data structures, by allowing iteration logic to be written more like a sequential function using `co_yield`. This is used in `iterator.cpp` for post-order traversal.

```cpp
#pragma once

#include <experimental/coroutine>

// ÀÌ Å¬·¡½º´Â Àç±ÍÀûÀ¸·Î µ¿ÀÛÇÒ ¼ö ÀÖ´Â recursive_generator¿¡ À§ÀÓÇÏ´Â ¹æ½ÄÀÇ ±¸ÇöÀ» º¸¿©ÁØ´Ù.
// ´ÙÀ½°ú °°ÀÌ µÎ Á¾·ùÀÇ Áß°£ »êÃâ Ç¥ÇöÀ» Áö¿øÇÑ´Ù.
//
//    co_yield V;
//    co_yield G_of_T;
//
// ¿©±â¼­ V´Â T·Î º¯È¯µÉ ¼ö ÀÖ´Â ¾î¶² °ªÀÌ°í,
// G_of_T´Â recursive_generator<T> Å¸ÀÔ °´Ã¼ÀÌ´Ù.
//
// ´ÙÀ½Àº »ç¿ë¿¹´Ù:
//
//   #include <stdio.h>
//   #include "recursive_recursive_generator.h"
//
//   recursive_generator<int> range(int start, int end, int step = 1) {
//     for (; start < end; start += step)
//       co_yield start;
//   }
//
//   recursive_generator<int> f() {
//     co_yield 1;
//     co_yield range(10, 15);
//     co_yield -1;
//     co_yield range(1000, 9999, 1000);
//   }
//
//   int main() {
//     for (auto v : f())
//       printf("%d ", v);
//     puts("");
//   }
//
// Ãâ·Â °á°ú: 1 10 11 12 13 14 -1 1000 2000 3000 4000 5000 6000 7000 8000 9000


template <typename T> struct recursive_generator {
  struct promise_type;
  using handle = std::experimental::coroutine_handle<promise_type>;

  struct promise_type {
    T const *value;

    promise_type *prev;
    promise_type *top_or_root;

    promise_type *top() { return top_or_root; }
    promise_type *root() {
      if (is_root())
        return this;
      return top_or_root;
    }

    void set_top(promise_type *p) { top_or_root = p; }
    void set_root(promise_type *p) { top_or_root = p; }

    promise_type() : prev(this), top_or_root(this) {}

    bool is_root() { return prev == this; }

    T const &get() { return *value; }

    void resume() { handle::from_promise(*this)(); }
    bool done() { return handle::from_promise(*this).done(); }

    recursive_generator<T> get_return_object() { return { *this }; }

    auto initial_suspend() { return std::experimental::suspend_always{}; }

    auto final_suspend() { return std::experimental::suspend_always{}; }

    auto yield_value(T const &v) {
      value = &v;
      return std::experimental::suspend_always{};
    }

    auto yield_value(recursive_generator<T> &&v) {
      auto &inner = v.impl.promise();
      inner.prev = this;
      inner.top_or_root = root();
      inner.top_or_root->top_or_root = &v.impl.promise();

      inner.resume();

      struct suspend_if {
        bool _Ready;
        explicit suspend_if(bool _Condition) : _Ready(!_Condition) {}
        bool await_ready() { return _Ready; }
        void await_suspend(std::experimental::coroutine_handle<>) {}
        void await_resume() {}
      };

      return suspend_if(!top()->done());
    }

    void pull() {
      if (!top()->done()) {
        top()->resume();
      }
      while (top()->done()) {
        if (top()->is_root())
          return;

        top_or_root = top()->prev;
        top()->resume();
      }
    }
  };

  ~recursive_generator() {
    if (impl) {
      impl.destroy();
    }
  }

  struct iterator {
    handle rh;

    iterator(decltype(nullptr)) {}
    iterator(handle rh) : rh(rh) {}

    iterator &operator++() {
      rh.promise().pull();
      if (rh.done()) {
        rh = nullptr;
      }
      return *this;
    }

    bool operator!=(iterator const &rhs) { return rh != rhs.rh; }

    T const &operator*() { return rh.promise().top()->get(); }
  };

  iterator begin() {
    impl.promise().pull();
    if (impl.done())
      return { nullptr };
    return { impl };
  }

  iterator end() { return { nullptr }; }

  recursive_generator(recursive_generator const &) = delete;
  recursive_generator &operator=(recursive_generator const &) = delete;

  recursive_generator(recursive_generator &&rhs) : impl(rhs.impl) { rhs.impl = nullptr; }
  recursive_generator &operator=(recursive_generator &&rhs) = delete;

private:
  recursive_generator(promise_type &p) : impl(handle::from_promise(p)) {}

  handle impl;
};
```

## Execution Result

(Please provide instructions on how to compile and run these examples. The output will be placed here.)
---

*This file was automatically generated.*
