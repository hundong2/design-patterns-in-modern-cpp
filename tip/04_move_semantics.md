# 이동 의미론 (Move Semantics)

> C++11에서 도입. 불필요한 복사를 **이동**으로 대체해 성능을 향상시킨다.

---

## 1. lvalue vs rvalue

```cpp
int x = 10;   // x = lvalue (이름이 있고 주소를 취할 수 있음)
10            // rvalue (임시 값, 이름 없음)
```

- **lvalue** : 표현식 이후에도 존재하는 값 (변수)
- **rvalue** : 표현식이 끝나면 사라지는 임시 값

---

## 2. `std::move` – lvalue를 rvalue로 변환

```cpp
// Person.h – 이동 생성자
Person(Person&& other)                  // && : rvalue 참조
    : street_address{move(other.street_address)},  // move로 자원 이동
      post_code{move(other.post_code)},
      city{move(other.city)},
      company_name{move(other.company_name)},
      position{move(other.position)},
      annual_income{other.annual_income}  // int는 그냥 복사
{
}
```

- `std::move(x)` : x를 rvalue로 캐스팅 (실제로 이동이 일어나진 않음)
- 이동 후 `other`의 string들은 비어있는 상태가 된다.
- int 같은 기본 타입은 이동이나 복사나 동일하므로 move 불필요.

---

## 3. 이동 대입 연산자

```cpp
// Person.h
Person& operator=(Person&& other)  // && : rvalue 참조
{
    if (this == &other)            // 자기 대입 방지
        return *this;
    street_address = move(other.street_address);
    // ...
    return *this;
}
```

---

## 4. `operator Person()` – 변환 연산자에서 move 활용

```cpp
// PersonBuilder.h
operator Person() const
{
    return std::move(person);  // 빌더에서 Person 추출 시 이동
}
```

빌더 패턴에서 최종 객체를 돌려줄 때 불필요한 복사 없이 이동한다.

---

## 5. `std::forward` – 완벽 전달 (Perfect Forwarding)

```cpp
// 가변 인자를 부모 생성자에 그대로 전달
template <typename...Args>
ColoredShape2(const string& color, Args ...args)
    : T(std::forward<Args>(args)...), color{color}
{
}
```

- `std::forward<T>(arg)` : lvalue이면 lvalue로, rvalue이면 rvalue로 **그대로** 전달
- `std::move`는 무조건 rvalue로 바꾸지만,  
  `std::forward`는 **원래의 값 카테고리를 보존**한다.

| 함수 | 동작 |
|------|------|
| `std::move(x)` | 항상 rvalue로 변환 |
| `std::forward<T>(x)` | T가 lvalue ref면 lvalue, rvalue ref면 rvalue 유지 |

---

## 6. 이동 의미론이 중요한 이유

```cpp
// 복사 (비용 큼): 문자열 전체를 새로 할당하고 복사
string a = "hello";
string b = a;        // deep copy

// 이동 (비용 적음): 내부 포인터만 이전
string c = std::move(a);  // a의 내부 버퍼를 c가 가져감
// 이후 a는 빈 문자열 상태
```

---

## 7. 반환값 최적화 (RVO / NRVO)

```cpp
unique_ptr<Contact> NewEmployee(string name, int suite, Contact& proto)
{
    auto result = make_unique<Contact>(proto);
    result->name = name;
    return result;  // RVO: 복사/이동 없이 직접 반환
}
```

컴파일러는 함수 반환 시 복사/이동을 생략하는 **RVO(Return Value Optimization)** 를  
자동으로 적용한다. `return std::move(result)` 라고 쓰면 오히려 RVO를 방해할 수 있다.

---

## 코드 내 사용 예시

| 파일 | 패턴 |
|------|------|
| `Person.h` | 이동 생성자, 이동 대입 연산자 (`&&`, `std::move`) |
| `PersonBuilder.h` | `operator Person()` 에서 `std::move(person)` |
| `decorator.cpp` | `std::forward<Args>(args)...` 완벽 전달 |
| `AbstractFactory.cpp` | `unique_ptr` 반환 (이동 의미론 활용) |
