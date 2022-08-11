# boost library install guide 

vcpkg : c++ package management program from microsoft 

## requirement before install

1. git 
2. Microsoft c++ build tool 

### step

#### 1. git clone repo from vcpkg

```bash
git clone https://github.com/microsoft/vcpkg
```

#### 2. vcpkg code build

##### 2.1 Move to vcpkg folder 

- `c:\vcpkg`
- execute file `.\bootstrap-vcpkg.bat -disableMetrics`  
[-disableMetrics option : don't make it telemetry file](https://github.com/microsoft/vcpkg/blob/master/docs/about/privacy.md)  

##### 2.2 install boost for window10/x64

- `./vcpkg install boost:x64-windows`

##### 2.3 current installed package list check

`./vcpkg list`

##### 2.4 set cmake

- u can use it boost library from vcpkg in visual studio  
`vcpkg integrate install` 

##### option 

`CMakgeList.txt` file write that 

```
find_package(Boost 1.73 REQUIRED)
include_directories(${Boost_INCLUDE_DIRS})
```

## reference 
https://int-i.github.io/cpp/2020-07-22/vcpkg-boost/  

