
# CMake-lib storage component

Linux: ![buildbadge_github], Windows: ![buildbadge_github], Mac OS: ![buildbadge_github]

- [CMake-lib storage component](#cmake-lib-storage-component)
  - [Usage](#usage)
  - [General](#general)
    - [Remote GIT repository structure](#remote-git-repository-structure)
    - [CMLibStorage.cmake structure](#cmlibstoragecmake-structure)
    - [Variable templates](#variable-templates)
  - [Bug reports and feature requests](#bug-reports-and-feature-requests)

It is a mechanism for storing and retreiving build dependencies like CMake modules, build scrips,
build resources etc.

[CMake-lib] storage read dependencies from `CMLibStorage.cmake` file stored in
`CMAKE_CURRENT_SOURCE_DIR`.

Each dependency is downloaded and the `STORAGE.cmake` in the remote git repository is called.

## Usage

Requirements:

- [CMLIB] installed and works

then just call

```
FIND_PACKAGE(CMLIB COMPONENTS STORAGE)
```

it will initialize `CMLIB_STORAGE` and all shared storages registred in `CMLibStorage.cmake`.

Look at example at [example/] directory.

## General

[CMake-lib] storage tracks and maintain remote git repositories in a simple way.

It's intended for two main use-cases

- we want to store all URI in one place. We create repository and in the STORAGE.cmake
  we store all remote URIs which the project needs
- we have some CMake macros/modules, build scripts/resources etc which are all common for all
  components of our project. We just create  git repository and upload all shared dependencies
  into it.

### Remote GIT repository structure

Terminology:

- CMake-lib storage refers to this library and repository.
- CMake-lib shared storage refers to remote git repositories which are maintained by this library.
- CMake-lib shared storage is a "standard" - each repository which meet
  requirements noted in this section can be considered as CMake-lib shared storage.

CMake-lib shared storage requirements:

Shared storage is represented by Git repository. Let the `GIT_ROOT` is git root of the
storage repository. \
In the `GIT_ROOT` there must be file called `STORAGE.cmake` which is included
by cmake `INCLUDE` command once the repository is downloaded.

### CMLibStorage.cmake structure

CMLibStorage.cmake required variables

- `STORAGE_LIST` - nonempty, finite set of shared storage names,
- `STORAGE_LIST_<name>` - URI which represents shared storage 'name' - name must be from `STORAGE_LIST`
- `STORAGE_LIST_<name>_REVISION` - which represents shared storage 'name' - name must be from `STORAGE_LIST`

Look at example at [example/CMLibStorage.cmake]

### Variable templates

The Storage implements mechanism called "Variable template".

Let's imagine that we have a URI for Boost. We want to write an app for Windows, Mac and Linux. \
let "https://mystorage.com/boost_107400_windows_amd64.zip" be a URI for Boost 1.74.0 for 64-bit windows.

We define variable in form `SET(BOOST_URI_TEMPLATE "https://mystorage.com/boost_<version>_<OS>_<PlAtFoRm>.zip")`

Once we want to obtain URL for Boost 1.74.0 for 64-bit windows by template variable BOOST_URI_TEMPLATE we just call

```cmake
SET(BOOST_URI_TEMPLATE "https://mystorage.com/boost_<version>_<OS>_<PlAtFoRm>.zip")
CMLIB_STORAGE_TEMPLATE_INSTANCE(
  boost_uri
  BOOST_URI_TEMPLATE
  version  107400
  os       windows
  platform amd64
)
MESSAGE(STATUS "Boost URI: ${boost_uri}")
```

It prints "https://mystorage.com/boost_107400_windows_amd64.zip".

## Bug reports and feature requests

If you want to submit a Bug report/feature request create a [Github Issue].

If you have a question please use [Github Discussion]

[CMLIB]:             https://github.com/cmakelib
[CMake-lib]:         https://github.com/cmakelib
[Github Discussion]: https://github.com/cmakelib/cmakelib-component-storage/discussions
[Github Issue]:      https://github.com/cmakelib/cmakelib-component-storage/issues
[example/CMLibStorage.cmake]: example/CMLibStorage.cmake
[example/]: example/
[buildbadge_github]: https://github.com/cmakelib/cmakelib-component-storage/workflows/Tests/badge.svg
