# Core
The core folder currently contains all the legacy files as present in Flutter Quill. We took the decision to split the code base in modules mainly for reasons:
- The architecture was really obscure and hard to follow
- The dependencies between modules was hard to trace
- Many files had over 1000 lines of code. Our goal is to keep them bellow 300.