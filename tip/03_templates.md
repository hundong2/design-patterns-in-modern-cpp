# 템플릿 (Templates)

> 타입을 매개변수로 받아 **범용 코드**를 작성하는 C++ 핵심 기능.

---

## 1. 기본 템플릿

```cpp
// 함수 템플릿
template <typename T>
Maybe<T> maybe(T* context)
{
    return Maybe<T>(context);
}

// 클래스 템플릿
template <typename T>
struct Maybe
{
    T* context;
    // ...
};
```

- `typename T` 또는 `class T` – 타입 매개변수 선언 (둘 다 동일)
- 호출 시 타입을 명시하거나 컴파일러가 자동 추론한다.

```cpp
maybe(p)           // T = Person으로 자동 추론
Maybe<Person>(p)   // T = Person 명시
```

---

## 2. 가변 인자 템플릿 (Variadic Templates)

```cpp
// Args... : 0개 이상의 타입을 받는 팩(pack)
template <typename...Args>
ColoredShape2(const string& color, Args ...args)
    : T(std::forward<Args>(args)...), color{color}
{
}
```

- `typename...Args` : 타입 팩 선언
- `Args ...args` : 매개변수 팩
- `args...` : 팩 확장(펼치기)
- `std::forward<Args>(args)...` : 완벽 전달과 함께 팩 확장

### 실제 활용 (decorator.cpp)
```cpp
// 가변 인자로 부모 생성자에 인자를 그대로 전달
TransparentShape2<ColoredShape2<Square>> sq = { "red", 51, 5 };
//                                                          ^^^^ 모두 args...로 전달됨
```

---

## 3. 템플릿 특수화 (Template Specialization)

```cpp
// 일반 선언 (구현 없음 – 특수화 강제)
template <typename> struct Logger3;

// 함수 타입 R(Args...)에 대한 부분 특수화
template <typename R, typename... Args>
struct Logger3<R(Args...)>
{
    Logger3(function<R(Args...)> func, const string& name)
        : func{func}, name{name}
    {
    }

    R operator()(Args ...args)
    {
        R result = func(args...);
        return result;
    }

    function<R(Args...)> func;
    string name;
};

// 사용
auto logged_add = make_logger3(add, "Add");  // R=double, Args=double,double 추론
```

---

## 4. CRTP (Curiously Recurring Template Pattern)

> **파생 클래스를 템플릿 인자로 베이스 클래스에 전달**하는 패턴.  
> 정적 다형성(virtual 없이 다형성)을 구현할 때 사용.

```cpp
// 베이스: Self가 실제 파생 클래스
template <typename Self>
struct SomeNeurons
{
    template <typename T>
    void connect_to(T& other)
    {
        for (Neuron& from : *static_cast<Self*>(this))  // Self로 캐스팅
        {
            for (Neuron& to : other)
            {
                from.out.push_back(&to);
                to.in.push_back(&from);
            }
        }
    }
};

// 파생: 자기 자신을 템플릿 인자로 전달
struct Neuron : SomeNeurons<Neuron>
{
    // ...
    Neuron* begin() { return this; }
    Neuron* end()   { return this + 1; }
};

struct NeuronLayer : vector<Neuron>, SomeNeurons<NeuronLayer>
{
    // ...
};
```

CRTP 덕분에 `n1.connect_to(n2)`, `n1.connect_to(layer)`, `layer.connect_to(n1)` 모두  
**같은 코드**로 동작한다.

---

## 5. `static_assert` – 컴파일 타임 타입 검사

```cpp
template <typename T>
struct ColoredShape2 : T
{
    // T가 Shape의 파생 클래스가 아니면 컴파일 에러
    static_assert(is_base_of<Shape, T>::value,
        "Template argument must be a Shape");
};
```

- `is_base_of<Base, Derived>::value` : Base가 Derived의 부모인지 확인
- `static_assert(조건, "메시지")` : 조건이 false이면 컴파일 에러

---

## 6. 타입 특성(Type Traits) 주요 목록

```cpp
#include <type_traits>

is_base_of<Base, T>::value    // T가 Base의 파생 클래스인가
is_same_v<T, string>          // T가 string과 같은 타입인가 (C++17 _v 접미사)
decay_t<decltype(arg)>        // const&, volatile, 배열 등을 제거한 순수 타입
remove_pointer<T>::type       // T* → T
```

### 실제 코드 예시 (std_visit.cpp)
```cpp
std::visit([](auto& arg) {
    using T = decay_t<decltype(arg)>;  // arg의 실제 타입을 T로 추론

    if constexpr (is_same_v<T, string>)  // 컴파일 타임 분기
    {
        cout << "A house called " << arg.c_str() << "\n";
    }
    else
    {
        cout << "House number " << arg << "\n";
    }
}, house);
```

---

## 7. 중첩 템플릿 (Nested Template)

```cpp
// BinaryTree 안에 중첩된 템플릿 이터레이터
template <typename T>
struct BinaryTree
{
    template <typename U>           // 바깥 T와 다른 타입 파라미터
    struct PreOrderIterator
    {
        Node<U>* current;
        // ...
    };

    typedef PreOrderIterator<T> iterator;  // typedef로 간소화
};
```

---

## 코드 내 사용 예시

| 파일 | 패턴 |
|------|------|
| `decorator.cpp` | 가변 인자 템플릿, 함수 타입 특수화 `Logger3<R(Args...)>` |
| `neurons.cpp` | CRTP `SomeNeurons<Self>` |
| `MaybeMonad.cpp` | 클래스 템플릿 `Maybe<T>` |
| `observer_book.cpp` | 클래스 템플릿 `Observable<T>`, `Observer<T>` |
| `std_visit.cpp` | `decay_t`, `is_same_v`, `if constexpr` |
| `iterator.cpp` | 중첩 템플릿, `typedef` |
