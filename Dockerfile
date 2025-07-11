# Ubuntu 최신 LTS 버전을 기반 이미지로 사용
FROM ubuntu:latest

# 시스템 패키지 업데이트 및 C++ 컴파일러, CMake, Git, Boost 설치
RUN apt-get update && \
    apt-get install -y \
    g++ \
    cmake \
    git \
    libboost-all-dev \
    && rm -rf /var/lib/apt/lists/*

# 작업 디렉토리 설정
WORKDIR /app

# 소스 코드 복사
COPY . .

# Google Test 설치 (gtest.zip 파일이 프로젝트 루트에 있다고 가정)
RUN apt-get update && apt-get install -y unzip && \
    unzip gtest.zip -d /usr/src/gtest && \
    cd /usr/src/gtest/googletest && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    make install && \
    rm -rf /var/lib/apt/lists/*

# 빌드 디렉토리 생성
RUN mkdir build
WORKDIR /app/build

# CMake를 사용하여 프로젝트 빌드 (루트 CppDesignPatterns.sln 대신 CMakeLists.txt 필요)
# 참고: 현재 프로젝트는 Visual Studio 솔루션(.sln) 기반입니다.
# Docker 환경에서 빌드하려면 각 프로젝트 또는 전체 프로젝트를 위한 CMakeLists.txt 파일이 필요합니다.
# 이 Dockerfile은 최상위 CMakeLists.txt가 있다고 가정합니다.
# 만약 없다면, 각 프로젝트별로 CMakeLists.txt를 만들거나 전체를 빌드하는 CMakeLists.txt를 만들어야 합니다.
RUN cmake ..
RUN make

# 기본 실행 명령어 (예시: 특정 프로젝트 실행)
# CMD ["./Behavioral/ChainOfResponsibility/ChainOfResponsibility"]
