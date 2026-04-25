# 람다 표현식 & std::function

> 함수를 **값처럼** 다루는 현대 C++ 핵심 기능.  
> `<functional>` 헤더 필요.

---

## 1. 람다(Lambda) 기본 구조

```
[캡처](매개변수) -> 반환타입 { 본문 }
```

```cpp
// 기본 람다
auto greet = []() { cout << "Hello!" << endl; };
greet();  // 호출

// 매개변수 있는 람다
auto add = [](double a, double b) { return a + b; };
double result = add(2.0, 3.0);

// auto 매개변수 (제네릭 람다, C++14)
maybe(p).With([](auto x) { return x->address; });
//             ^^^^ 타입 자동 추론
```

---

## 2. 캡처(Capture) 종류

```cpp
int x = 10;
string name = "test";

auto f1 = [=]() { cout << x; };      // [=] : 외부 변수 값 복사로 캡처
auto f2 = [&]() { x += 1; };         // [&] : 외부 변수 참조로 캡처
auto f3 = [x]() { cout << x; };      // 특정 변수만 복사 캡처
auto f4 = [&x]() { x += 1; };        // 특정 변수만 참조 캡처
auto f5 = [&, x]() { /* ... */ };    // 나머지는 참조, x만 복사
```

### 실제 코드 예시 (cor_broker.cpp)
```cpp
// [&] : game, creature를 참조로 캡처
conn = game.queries.connect([&](Query& q)
{
    if (q.creature_name == creature.name &&
        q.argument == Query::Argument::attack)
        q.result *= 2;
});
```

---

## 3. 람다를 변수에 저장 – `std::function`

```cpp
// std::function<반환타입(매개변수타입...)>
std::function<void()> func;

// 일반 함수 저장
func = []() { cout << "Hello" << endl; };
func();  // 호출

// 매개변수가 있는 경우
function<R(Args...)> func2;
```

### 실제 코드 예시 (decorator.cpp)
```cpp
struct Logger
{
    std::function<void()> func;  // 어떤 callable이든 저장 가능
    string name;

    void operator()() const
    {
        cout << "Entering " << name << endl;
        func();                   // 저장된 함수 호출
        cout << "Exiting " << name << endl;
    }
};

// 사용
Logger logger{[]() { cout << "작업 실행" << endl; }, "MyFunc"};
logger();  // operator() 호출
```

---

## 4. 클로저(Closure) – 람다로 함수 생성

```cpp
// clone 람다: 직렬화/역직렬화로 깊은 복사 수행
auto clone = [](const Contact& c)
{
    ostringstream oss;
    boost::archive::text_oarchive oa(oss);
    oa << c;
    // ...
    return result;
};
```

람다는 **클로저(closure)** 를 형성한다 – 외부 변수를 함수 내부에 "가둘" 수 있다.

---

## 5. operator() – 호출 가능 객체(Functor)

```cpp
// operator()를 정의하면 객체를 함수처럼 호출 가능
void operator()() const
{
    func();
}

Logger log{...};
log();  // log.operator()() 와 동일
```

---

## 비교 요약

| 구분 | 람다 | `std::function` |
|------|------|-----------------|
| 타입 | 컴파일러가 생성한 고유 타입 | 타입 소거된 범용 래퍼 |
| 성능 | 매우 빠름 (인라인 가능) | 약간의 오버헤드 |
| 저장 | `auto`로만 저장 가능 | 변수/멤버에 저장 가능 |
| 전달 | 템플릿 파라미터로 전달 | 일반 함수 인자로 전달 |

---

## 코드 내 사용 예시

| 파일 | 사용 패턴 |
|------|-----------|
| `Prototype.cpp` | `auto clone = [](const Contact& c) {...}` |
| `cor_broker.cpp` | `game.queries.connect([&](Query& q) {...})` |
| `MaybeMonad.cpp` | `.With([](auto x) { return x->address; })` |
| `decorator.cpp` | `std::function<void()>` 멤버, `make_logger2` |
| `std_visit.cpp` | `std::visit([](auto& arg) {...}, house)` |
