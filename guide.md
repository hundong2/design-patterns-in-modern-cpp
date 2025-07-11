# C++ 디자인 패턴 프로젝트 Docker 빌드 및 실행 가이드

이 문서는 Docker를 사용하여 C++ 디자인 패턴 예제 프로젝트들을 빌드하고 실행하는 방법을 안내합니다.

## 사전 준비 사항

1.  **Docker 설치:** 시스템에 Docker가 설치되어 있어야 합니다. [Docker 공식 웹사이트](https://www.docker.com/get-started)에서 설치 가이드를 참조하세요.
2.  **소스 코드:** 이 저장소의 소스 코드를 로컬 컴퓨터에 클론하거나 다운로드합니다.

## Docker 이미지 빌드

프로젝트 루트 디렉토리에서 다음 명령어를 실행하여 Docker 이미지를 빌드합니다. 이 과정에는 시간이 다소 소요될 수 있습니다.

```bash
docker build -t cpp-design-patterns .
```

## CMakeLists.txt 파일 작성 (중요)

이 프로젝트는 원래 Visual Studio 솔루션(`.sln`) 파일을 기반으로 합니다. Linux 기반의 Docker 환경에서 C++ 프로젝트를 빌드하려면 `CMakeLists.txt` 파일이 필요합니다.

**각 프로젝트 폴더에 `CMakeLists.txt` 파일을 생성해야 합니다.** 예를 들어 `Behavioral/ChainOfResponsibility` 프로젝트를 빌드하려면 해당 폴더 내에 다음과 유사한 `CMakeLists.txt` 파일을 작성해야 합니다.

**예시: `Behavioral/ChainOfResponsibility/CMakeLists.txt`**

```cmake
cmake_minimum_required(VERSION 3.10)

project(ChainOfResponsibilityExample CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# Boost 라이브러리 찾기 (Dockerfile에서 설치됨)
find_package(Boost REQUIRED COMPONENTS system thread) # 필요한 Boost 컴포넌트에 따라 수정

# Google Test 라이브러리 찾기 (Dockerfile에서 설치됨)
find_package(GTest REQUIRED)

# 소스 파일 추가
add_executable(ChainOfResponsibility
    CoRCodingExercise.cpp
    cor_broker.cpp
    cor_pointer.cpp
    # 다른 .cpp 파일이 있다면 추가
)

# 필요한 라이브러리 링크
target_link_libraries(ChainOfResponsibility PRIVATE
    Boost::system
    Boost::thread
    GTest::GTest
    GTest::Main
)

# Google Test 사용을 위한 설정 (필요한 경우)
include(GoogleTest)
# gtest_discover_tests(ChainOfResponsibility) # 테스트 코드가 있다면 활성화

# 헤더 파일 경로 (필요한 경우)
# target_include_directories(ChainOfResponsibility PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
```

**참고:**

*   위 `CMakeLists.txt`는 예시이며, 각 프로젝트의 소스 파일, 필요한 Boost 컴포넌트, Google Test 사용 여부에 따라 수정해야 합니다.
*   `find_package(Boost ...)` 부분에서 `COMPONENTS`는 해당 프로젝트가 사용하는 Boost 라이브러리 모듈에 맞춰야 합니다. 어떤 모듈이 필요한지는 각 cpp 파일의 `#include <boost/...>` 부분을 확인하여 추론할 수 있습니다.
*   모든 프로젝트를 한 번에 빌드하는 최상위 `CMakeLists.txt`를 루트 디렉토리에 만들 수도 있습니다. 이 경우 각 하위 디렉토리의 `CMakeLists.txt`를 `add_subdirectory()` 명령으로 포함시킬 수 있습니다.

## Docker 컨테이너에서 프로젝트 빌드 및 실행

1.  **Docker 컨테이너 실행:**

    ```bash
    docker run -it --rm -v "$(pwd):/app" cpp-design-patterns bash
    ```

    *   `-it`: 대화형 터미널 세션을 시작합니다.
    *   `--rm`: 컨테이너 종료 시 자동으로 삭제합니다.
    *   `-v "$(pwd):/app"`: 현재 로컬 디렉토리 (소스 코드 포함)를 컨테이너 내부의 `/app` 디렉토리에 마운트합니다. 이렇게 하면 로컬에서 `CMakeLists.txt` 파일을 수정하고 바로 컨테이너에서 빌드할 수 있습니다.
    *   `cpp-design-patterns`: 이전에 빌드한 Docker 이미지 이름입니다.
    *   `bash`: 컨테이너 내에서 bash 쉘을 실행합니다.

2.  **컨테이너 내에서 프로젝트 빌드:**

    컨테이너 쉘에서 원하는 프로젝트 폴더로 이동하여 빌드합니다. 예를 들어 `Behavioral/ChainOfResponsibility` 프로젝트를 빌드하려면:

    ```bash
    cd /app/Behavioral/ChainOfResponsibility
    mkdir build
    cd build
    cmake ..
    make
    ```

3.  **프로젝트 실행:**

    빌드가 성공하면 실행 파일이 생성됩니다. (위 예시에서는 `ChainOfResponsibility`)

    ```bash
    ./ChainOfResponsibility
    ```

4.  **예상 결과:**

    각 프로젝트의 `main` (또는 `main_xxx`를 `main`으로 변경한) 함수 내의 코드 실행 결과가 콘솔에 출력됩니다.
    예를 들어, 간단한 "Hello World"를 출력하는 프로그램이라면 해당 메시지가 보일 것입니다. 각 패턴 예제의 구체적인 출력은 해당 소스 코드를 참조하십시오.

    *(추후 각 프로젝트별 주요 실행 파일 및 예상되는 일반적인 출력 형태를 여기에 추가할 수 있습니다.)*

## 예시: Behavioral/ChainOfResponsibility 프로젝트 빌드 및 실행 단계 요약

1.  로컬에서 `Behavioral/ChainOfResponsibility/CMakeLists.txt` 파일 작성 (위 예시 참조).
2.  터미널에서 `docker build -t cpp-design-patterns .` 실행 (이미지 빌드, 최초 한 번).
3.  터미널에서 `docker run -it --rm -v "$(pwd):/app" cpp-design-patterns bash` 실행 (컨테이너 시작).
4.  컨테이너 쉘에서:
    ```bash
    cd /app/Behavioral/ChainOfResponsibility/build
    cmake ..
    make
    ./ChainOfResponsibility
    ```
    (만약 `build` 디렉토리가 없다면 `mkdir build && cd build` 먼저 실행)

## 모든 프로젝트 빌드 (루트 CMakeLists.txt 사용 시)

만약 프로젝트 루트에 모든 하위 프로젝트를 포함하는 `CMakeLists.txt`를 작성했다면, Dockerfile의 빌드 단계(`RUN cmake ..` 및 `RUN make`)에서 이미 빌드가 시도되었을 것입니다. 이 경우, 컨테이너 실행 후 바로 각 실행 파일을 찾아 실행할 수 있습니다.

**루트 `CMakeLists.txt` 예시 (간략):**

```cmake
cmake_minimum_required(VERSION 3.10)
project(AllDesignPatterns CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# Google Test (전역적으로 필요하다면)
find_package(GTest REQUIRED)
include(GoogleTest)

# Boost (전역적으로 필요하다면)
find_package(Boost REQUIRED COMPONENTS system thread date_time ... ) # 필요한 모든 컴포넌트 명시
include_directories(${Boost_INCLUDE_DIRS})
link_libraries(${Boost_LIBRARIES})

add_subdirectory(Behavioral/ChainOfResponsibility)
add_subdirectory(Behavioral/Command)
# ... 다른 모든 Behavioral 프로젝트
add_subdirectory(Creational/Creational) # Creational 패턴은 하위 폴더 구조가 다를 수 있음
# ... 다른 모든 Creational 프로젝트
add_subdirectory(Structural/Adapter)
# ... 다른 모든 Structural 프로젝트

# 참고: Creational/Creational 폴더 내에도 많은 cpp 파일들이 직접 있습니다.
# 이들을 빌드하려면 해당 폴더의 CMakeLists.txt에서 적절히 add_executable() 해야 합니다.
# 예: Creational/Creational/CMakeLists.txt
# add_executable(AbstractFactoryPattern AbstractFactory.cpp)
# target_link_libraries(AbstractFactoryPattern PRIVATE Boost::boost GTest::GTest GTest::Main)
```

이러한 루트 `CMakeLists.txt`를 사용하면 Docker 이미지 빌드 시 모든 예제가 컴파일될 수 있으며, `guide.md`의 실행 부분은 각 실행 파일 경로를 안내하는 방식으로 변경될 수 있습니다.
