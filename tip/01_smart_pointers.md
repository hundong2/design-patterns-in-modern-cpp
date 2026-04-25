# 스마트 포인터 (Smart Pointers)

> C++11 이후 `new`/`delete`를 직접 쓰는 대신 **자동 메모리 관리**를 위해 사용한다.  
> `<memory>` 헤더 필요.

---

## 1. `unique_ptr` – 단독 소유권

```cpp
// 생성: make_unique 권장 (C++14)
unique_ptr<HtmlBuilder> ptr = make_unique<HtmlBuilder>(root_name);

// 함수 반환값으로 사용 (소유권 이전)
static unique_ptr<HtmlBuilder> build(string root_name)
{
    return make_unique<HtmlBuilder>(root_name);  // 복사 없이 이동
}
```

- **단 하나**의 포인터만 해당 객체를 소유한다.
- 스코프를 벗어나면 **자동으로 `delete`** 된다.
- 복사(`copy`)는 불가, **이동(`move`)만** 가능하다.

```cpp
// 잘못된 예 – 컴파일 에러
unique_ptr<Foo> a = make_unique<Foo>();
unique_ptr<Foo> b = a;   // ❌ 복사 불가

// 올바른 예 – 소유권 이전
unique_ptr<Foo> b = std::move(a);  // ✅ a는 nullptr이 됨
```

---

## 2. `shared_ptr` – 공유 소유권

```cpp
// 생성: make_shared 권장
auto b = make_shared<CurrentAccount>(123);

// 원시 포인터 꺼내기
BankAccount* actual = b.get();

// 역참조
b->deposit(321);   // 멤버 접근 (-> 사용)
cout << *b;        // 객체 역참조 (* 사용)
```

- **참조 카운팅** 방식으로 여러 포인터가 공유한다.
- 마지막 `shared_ptr`가 소멸될 때 객체가 `delete` 된다.
- `b.get()` : 내부 원시 포인터를 반환(소유권 이전 아님).

---

## 3. 비교 요약

| 구분 | `unique_ptr` | `shared_ptr` |
|------|-------------|-------------|
| 소유권 | 단독 | 공유 (참조 카운팅) |
| 복사 | ❌ 불가 | ✅ 가능 |
| 이동 | ✅ 가능 | ✅ 가능 |
| 오버헤드 | 거의 없음 | 참조 카운트 관리 비용 |
| 주 용도 | 단순 자원 관리 | 여러 곳에서 공유 |

---

## 4. 가상 소멸자와 스마트 포인터

```cpp
struct BankAccount
{
    virtual ~BankAccount() = default;  // 스마트 포인터 + 다형성 → 반드시 virtual 소멸자
};
```

베이스 클래스 포인터로 `delete`할 때 파생 클래스 소멸자가 호출되려면  
**반드시 virtual 소멸자**가 필요하다.

---

## 코드 내 사용 예시

| 파일 | 사용 패턴 |
|------|-----------|
| `Builder.cpp` | `make_unique<HtmlBuilder>()` 반환 |
| `AbstractFactory.cpp` | `unique_ptr<HotDrink>` 팩토리 반환 |
| `strategy_dynamic.cpp` | `unique_ptr<ListStrategy>` 교체 |
| `proxy.cpp` | `make_shared<CurrentAccount>()` 공유 |
