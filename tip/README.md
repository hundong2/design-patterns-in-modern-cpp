# Modern C++ 문법 팁 모음

이 폴더는 `design-patterns-in-modern-cpp` 저장소의 코드에서 등장하는  
**Modern C++ 핵심 문법 요소**를 빠르게 복습할 수 있도록 정리한 가이드입니다.

---

## 파일 목록

| 파일 | 주요 내용 |
|------|-----------|
| [01_smart_pointers.md](./01_smart_pointers.md) | `unique_ptr`, `shared_ptr`, `make_unique`, `make_shared` |
| [02_lambda_and_function.md](./02_lambda_and_function.md) | 람다 표현식, 캡처, `std::function`, `operator()` |
| [03_templates.md](./03_templates.md) | 함수/클래스 템플릿, 가변 인자 템플릿, CRTP, `static_assert`, 타입 특성 |
| [04_move_semantics.md](./04_move_semantics.md) | `std::move`, `std::forward`, 이동 생성자/대입, RVO |
| [05_class_keywords.md](./05_class_keywords.md) | `virtual`, `override`, `= 0`, `= delete`, `= default`, `explicit`, `friend`, 연산자 오버로딩, 초기화 리스트 |
| [06_modern_syntax.md](./06_modern_syntax.md) | `auto`, range-for, `enum class`, `{}` 초기화, `if constexpr`, `std::variant`/`visit`, `co_yield`, `lock_guard` |

---

## 빠른 참조

```
새로운 객체를 안전하게 생성?     → 01 스마트 포인터
함수를 값처럼 넘기고 싶어?       → 02 람다 & std::function
범용 코드 / 다형성?              → 03 템플릿
불필요한 복사를 없애고 싶어?      → 04 이동 의미론
클래스 설계 시 헷갈리는 키워드?  → 05 클래스 키워드
C++11/14/17 새 문법 총정리?      → 06 모던 문법
```
