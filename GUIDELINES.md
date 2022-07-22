# Contributing Guidelines
All the Pull Requests raised on the Visual Editor repository will have to comply with the following list of rules. The list is made of common sense clean code practices adapted to Flutter projects.

## SETTING UP THE ENVIRONMENT
* To reduce the number of files when you search in your IDE (CTRL + SHIFT + F) is recommended to exclude `/ios` and `/android` files from the search. In Android Studio, in the project panel, rightClick on folder / Mark as / Excluded.

## CODE DIAGRAM
**Keep the build(), initState(), subscribe() methods as skinny as possible - They are the "diagram" of the entire class**

The code flow has to be easily distinguishable and identifiable. Every single class and entry method such as: build(), initState(). subscribe(). All entry points will must be boiled down form large blobs of code down to small clearly named methods. This will improve the readability of the code by leaps and bounds. This advice applies to every single project where you work. Make an effort to always break down large methods into tiny small methods from the very beginning. We as programmers have a very bad tendency of aiming for the finish line and then tidying up the details. The problem with this approach is that it creates more clutter during the development, it increases the changes of introducing bugs and it's highly likely that the code will remain ungroomed. This is an unacceptable practice for any self-respecting programmer. Make your life easier by making the choke points / entry points easy to read. Clearly express what is going on there.

For example: The old build() method in editor.dart used to have 100 lines of code. Now it has less than 20. This makes the entire logic far easier to study at first read. The most important facts about the architecture are exposed on top. Everything else is hidden down bellow at the lower levels of the call stack.

**Before**

<img src="https://github.com/visual-space/visual-editor/blob/develop/example/assets/guidelines/1a-build-before.png" width="350"/>

**After**

<img src="https://github.com/visual-space/visual-editor/blob/develop/example/assets/guidelines/1b-build-after.png" width="350"/>
