# Actions

- Responsible for handling the logic for manipulating the document when specific intents are paired with actions.
- For example when user uses `CTRL + 1` hotkey, we are using the `Shortcuts` flutter API which is responsible for triggering specific intents when a specific combination of keys are pressed by using the `LogicalKeySet` API, it triggers the `Intent` with the h1 attribute which further triggers the action `ApplyHeaderAction` with our logic, that applies the changes in the document.