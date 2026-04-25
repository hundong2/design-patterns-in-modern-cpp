# 클래스 관련 핵심 키워드

> C++ 클래스 설계에서 자주 등장하는 키워드들을 정리한다.

---

## 1. `virtual` / `override` / `= 0` – 가상 함수와 순수 가상 함수

```cpp
// 베이스 클래스
struct Shape
{
    virtual string str() const = 0;  // 순수 가상 함수 → 추상 클래스
    //      ↑ 가상함수 선언    ↑ = 0 : 구현 없음, 파생 클래스가 반드시 구현해야 함
};

struct Database
{
    virtual int get_population(const std::string& name) = 0;
    virtual ~Database() = default;  // 가상 소멸자 (다형성 사용 시 필수)
};

// 파생 클래스
struct Circle : Shape
{
    string str() const override  // override: 베이스 가상 함수를 재정의함을 명시
    {
        return "circle";
    }
};
```

- `virtual` : 런타임에 올바른 함수가 호출되도록 **가상 디스패치** 활성화
- `= 0` : **순수 가상 함수** – 해당 클래스는 인스턴스화 불가 (추상 클래스)
- `override` : 실수로 다른 함수를 만드는 것을 컴파일러가 검사해줌

```cpp
// override 없을 때의 함정
struct Derived : Base
{
    int func(float x);  // 의도: Base::func(int) 재정의 → 실제: 새 함수 생성!
};

// override 있을 때
struct Derived : Base
{
    int func(float x) override;  // ❌ 컴파일 에러: 베이스에 일치하는 함수 없음
};
```

---

## 2. `= default` / `= delete` – 특수 멤버 함수 제어

```cpp
// = default : 컴파일러가 자동 생성하는 기본 구현 사용
struct BankAccount
{
    virtual ~BankAccount() = default;  // 기본 소멸자 사용
};

struct ListStrategy
{
    virtual ~ListStrategy() = default;
    virtual void start(ostringstream& oss) {};  // 빈 기본 구현
};

// = delete : 해당 함수를 완전히 금지
class SingletonDatabase
{
    SingletonDatabase() { /* ... */ }  // private 생성자
public:
    SingletonDatabase(SingletonDatabase const&) = delete;   // 복사 생성 금지
    void operator=(SingletonDatabase const&) = delete;      // 복사 대입 금지
};
```

싱글톤 패턴에서 복사/대입을 막을 때 `= delete`를 사용한다.

---

## 3. `explicit` – 암시적 변환 방지

```cpp
struct Circle : Shape
{
    float radius;

    explicit Circle(const float radius)  // explicit: 암시적 변환 차단
        : radius{radius}
    {
    }
};

// explicit 없으면:
Circle c = 5.0f;   // ✅ 암시적 변환으로 생성됨 (의도치 않은 동작 가능)

// explicit 있으면:
Circle c = 5.0f;   // ❌ 컴파일 에러
Circle c{5.0f};    // ✅ 직접 초기화는 허용
Circle c(5.0f);    // ✅ 직접 초기화는 허용
```

---

## 4. `friend` – 외부에서 private 접근 허용

```cpp
class Point
{
    Point(float x, float y) : x(x), y(y){}  // private 생성자
public:
    float x, y;
    friend class PointFactory;  // PointFactory가 private 멤버 접근 가능
};

// 연산자 오버로딩에서의 friend
struct Address
{
    friend ostream& operator<<(ostream& os, const Address& obj)
    {
        return os << obj.street << " " << obj.city;  // private 멤버 접근
    }
};

// 여러 클래스에 friend 선언
class Person
{
    friend class PersonBuilder;
    friend class PersonAddressBuilder;
    friend class PersonJobBuilder;
};
```

---

## 5. 연산자 오버로딩 (Operator Overloading)

```cpp
// << 연산자: cout << obj 사용 가능하게
friend ostream& operator<<(ostream& os, const Person& obj)
{
    return os << "name: " << obj.name << " age: " << obj.age;
}

// 변환 연산자: PersonBuilder를 Person으로 자동 변환
operator Person() const
{
    return std::move(person);
}

// = 연산자: 대입
Contact& operator=(const Contact& other)
{
    if (this == &other) return *this;  // 자기 대입 방지
    name = other.name;
    return *this;
}

// () 연산자: 객체를 함수처럼 호출
void operator()() const
{
    func();
}

// T 변환 연산자 (Property 프록시)
operator T()
{
    return value;
}

T operator=(T newValue)
{
    return value = newValue;
}
```

---

## 6. 생성자 초기화 리스트 (Member Initializer List)

```cpp
struct Address
{
    string street, city;
    int suite;

    Address(const string& street, const string& city, const int suite)
        : street{ street },   // ← 초기화 리스트
          city{ city },       //   순서는 멤버 선언 순서와 맞춰야 함
          suite{ suite }
    {
        // 여기서 대입하는 것보다 초기화 리스트가 더 효율적
    }
};

// 기본값 지정 (C++11)
struct Node
{
    int value = 0;        // 멤버 선언 시 기본값
    Node* left = nullptr;
    Node* right = nullptr;
};
```

- 초기화 리스트는 대입보다 **효율적** (객체 생성과 동시에 초기화)
- `const` 멤버나 참조 멤버는 반드시 초기화 리스트에서 초기화해야 한다.

---

## 7. `#pragma once` – 헤더 가드

```cpp
#pragma once  // 이 헤더 파일을 여러 번 include해도 한 번만 처리
```

전통적인 `#ifndef` / `#define` / `#endif` 헤더 가드와 동일한 역할.  
대부분의 현대 컴파일러에서 지원하며, 더 간결하다.

---

## 코드 내 사용 예시

| 파일 | 패턴 |
|------|------|
| `Singleton.h` | `= delete` (복사/대입 금지), `virtual = 0` |
| `Person.h` | `friend class`, `operator<<`, move 생성자/대입 |
| `decorator.cpp` | `explicit`, `override`, `virtual = default` |
| `proxy.cpp` | `operator T()`, `T operator=()` 프로퍼티 프록시 |
| `Factory.cpp` | `friend class PointFactory`, private 생성자 |
| `PersonBuilder.h` | `operator Person()` 변환 연산자 |
