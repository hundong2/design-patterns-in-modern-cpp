# 모던 C++ 문법 핵심 요약

> C++11/14/17에서 새로 추가된 문법 요소들. 코드를 더 간결하고 안전하게 만든다.

---

## 1. `auto` – 타입 자동 추론

```cpp
// 컴파일러가 우변을 보고 타입을 자동으로 결정
auto text = "hello";                            // const char*
auto builder = HtmlElement::build("ul");        // unique_ptr<HtmlBuilder>
auto d = make_drink("tea");                     // unique_ptr<HotDrink>
auto result = make_unique<Contact>(proto);      // unique_ptr<Contact>

// 반환 타입에도 사용 (C++14)
template <typename Func>
auto make_logger2(Func func, const string& name)
{
    return Logger2<Func>{ func, name };  // 반환 타입 자동 추론
}
```

- 코드가 간결해지고 타입 변경 시 수정 포인트가 줄어든다.
- 단, **가독성을 위해 타입이 명확하지 않으면 명시적으로 쓰는 것이 나을 수도 있다.**

---

## 2. Range-based for 루프

```cpp
vector<string> words = {"hello", "world"};

// 전통 for
for (int i = 0; i < words.size(); i++)
    cout << words[i];

// Range-based for (C++11)
for (auto w : words)          // 값 복사
    cout << w;

for (auto& w : words)         // 참조 (수정 가능, 복사 없음)
    w += "!";

for (const auto& w : words)   // const 참조 (읽기 전용, 복사 없음) ← 가장 권장
    cout << w;

// 역방향 순회
for (auto ri = rbegin(words); ri != rend(words); ++ri)
    cout << *ri;
```

### 실제 코드 예시
```cpp
// observer_book.cpp
for (auto obs : observers_copy)
    if (obs)
        obs->field_changed(source, name);

// Singleton.h
for (auto& name : names)
    result += db.get_population(name);
```

---

## 3. `enum class` – 강타입 열거형

```cpp
// 기존 enum (오염 위험)
enum PointType { cartesian, polar };
int x = cartesian;    // ❌ 의도치 않은 암시적 변환 가능

// enum class (C++11) – 타입 안전
enum class PointType
{
    cartesian,
    polar
};

enum class OutputFormat
{
    Markdown,
    Html
};

// 반드시 클래스명::멤버 형태로 접근
PointType t = PointType::cartesian;
OutputFormat fmt = OutputFormat::Html;

// switch에서 사용
switch(format)
{
case OutputFormat::Markdown:
    list_strategy = make_unique<MarkdownListStrategy>();
    break;
case OutputFormat::Html:
    list_strategy = make_unique<HtmlListStrategy>();
    break;
}
```

- 다른 enum이나 int와 암시적으로 섞이지 않아 **타입 안전** 하다.
- 네임스페이스 오염 없음 (같은 이름이 다른 enum에 있어도 충돌 없음).

---

## 4. 통일된 초기화 문법 (Uniform Initialization) – `{}`

```cpp
// 전통 방식
HtmlElement e("li", "hello");
vector<int> v;
v.push_back(1);

// 통일된 초기화 (C++11)
HtmlElement e{ "li", "hello" };          // 구조체/클래스
HtmlBuilder builder{ "ul" };
vector<string> names{ "john", "jane" };  // 벡터 초기화
Creature c{ 5, 10 };                     // 집합 초기화
auto addr = new Address{ "London", "SW1", 0 };

// 초기화 리스트로 컨테이너 채우기
tp.append_list({"foo", "bar", "baz"});   // initializer_list<string>
```

`{}` 초기화는 **좁히기 변환(narrowing conversion)** 을 허용하지 않아 더 안전하다.

---

## 5. `if constexpr` – 컴파일 타임 조건 분기 (C++17)

```cpp
std::visit([](auto& arg) {
    using T = decay_t<decltype(arg)>;

    if constexpr (is_same_v<T, string>)  // 컴파일 타임에 분기
    {
        // T가 string일 때만 컴파일 – 다른 타입엔 이 코드 자체가 없어짐
        cout << "A house called " << arg.c_str() << "\n";
    }
    else
    {
        cout << "House number " << arg << "\n";
    }
}, house);
```

- 일반 `if`는 런타임 분기 / `if constexpr`는 **컴파일 타임 분기**
- 분기에 맞지 않는 코드는 **아예 컴파일되지 않음** (타입 오류도 발생하지 않음)

---

## 6. `std::variant` / `std::visit` (C++17) – 타입 안전 유니온

```cpp
#include <variant>

// string 또는 int 중 하나를 담을 수 있는 타입
variant<string, int> house;
house = "Montefiore Castle";   // string 저장
house = 221;                   // int 저장

// 방문자 패턴으로 처리
struct AddressPrinter
{
    void operator()(const string& name) const { cout << "House: " << name; }
    void operator()(const int num)      const { cout << "Number: " << num; }
};

std::visit(AddressPrinter{}, house);  // 현재 저장된 타입에 맞는 operator() 호출

// 인라인 람다로 처리
std::visit([](auto& arg) {
    // arg는 현재 저장된 타입 (string 또는 int)
}, house);
```

- 기존 `union`과 달리 어떤 타입이 저장돼 있는지 **안전하게 추적**
- `std::get<T>(v)` : 특정 타입으로 꺼내기 (타입 불일치 시 예외)
- `std::visit(visitor, v)` : 현재 타입에 맞는 visitor 호출

---

## 7. `typedef` / `using` – 타입 별칭

```cpp
// 전통 typedef
typedef mutex mutex_t;
typedef PreOrderIterator<T> iterator;

// 현대 C++ using (더 직관적, 템플릿 별칭 가능)
using mutex_t = mutex;
using iterator = PreOrderIterator<T>;
```

---

## 8. `nullptr` – 널 포인터

```cpp
// 기존 NULL (int 0과 혼동 가능)
int* p = NULL;

// nullptr (C++11) – 포인터 타입만 해당
Node* left = nullptr;
Node* right = nullptr;
Bitmap* bmp{nullptr};  // {} 초기화와 함께

// nullptr 체크
if (!bmp)
    bmp = new Bitmap(filename);
```

---

## 9. `co_yield` – 코루틴 (C++20/experimental)

```cpp
#include <experimental/coroutine>
#include <experimental/generator>

// co_yield: 값을 하나씩 생성하며 실행 일시 중단
experimental::generator<Node<T>*> post_order_impl(Node<T>* node)
{
    if (node)
    {
        for (auto x : post_order_impl(node->left))
            co_yield x;    // 값 반환 후 일시 중단
        for (auto y : post_order_impl(node->right))
            co_yield y;
        co_yield node;
    }
}

// 사용 – generator를 일반 컨테이너처럼 순회
for (auto it : family.post_order())
    cout << it->value << endl;
```

- `co_yield` : 값을 반환하고 함수 실행을 **일시 중단** (나중에 재개 가능)
- `generator<T>` : 코루틴이 생성하는 값들을 순회하는 타입

---

## 10. 스레드 안전 – `mutex` / `lock_guard`

```cpp
#include <mutex>

struct Observable
{
    typedef mutex mutex_t;  // 타입 별칭
    mutex_t mtx;            // 뮤텍스 멤버

    void subscribe(Observer<T>* f)
    {
        lock_guard<mutex_t> lock{ mtx };  // 스코프 내 자동 락/언락
        observers.push_back(f);
    }
    // lock_guard가 소멸되면 자동으로 mtx.unlock() 호출
};
```

- `lock_guard<mutex>` : 생성 시 lock, 소멸 시 unlock (RAII 방식)
- 예외가 발생해도 소멸자가 호출되므로 **데드락 없이 안전**

---

## 코드 내 사용 예시

| 파일 | 패턴 |
|------|------|
| `Builder.cpp` | `auto`, range-for, `{}` 초기화 |
| `strategy_dynamic.cpp` | `enum class OutputFormat`, `make_unique` 교체 |
| `std_visit.cpp` | `variant`, `std::visit`, `if constexpr`, `decay_t` |
| `iterator.cpp` | `typedef`, `nullptr`, `co_yield`, `experimental::generator` |
| `observer_book.cpp` | `typedef mutex mutex_t`, `lock_guard` |
