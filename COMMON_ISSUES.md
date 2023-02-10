# Common Issues

## FormatException: Control character in string
A string can contain 31 different control characters. See this list for an overview of all control characters in the UTF-8 character encoding standard (https://www.charset.org/utf-8). These control characters are invisible by default in almost every text editor. To fix this issue, make sure to replace them with the following code.

<details>
  <summary>Code sample</summary>
  
  ### 1. Generate a list with all control characters as a String
  <details>
    <summary>List of controlCharacters</summary>

  ```dart
  List<String> controlCharacters = [
  String.fromCharCodes([00]),
  String.fromCharCodes([01]),
  String.fromCharCodes([02]),
  String.fromCharCodes([03]),
  String.fromCharCodes([04]),
  String.fromCharCodes([05]),
  String.fromCharCodes([06]),
  String.fromCharCodes([07]),
  String.fromCharCodes([08]),
  String.fromCharCodes([09]),
  String.fromCharCodes([10]),
  String.fromCharCodes([11]),
  String.fromCharCodes([12]),
  String.fromCharCodes([13]),
  String.fromCharCodes([14]),
  String.fromCharCodes([15]),
  String.fromCharCodes([16]),
  String.fromCharCodes([17]),
  String.fromCharCodes([18]),
  String.fromCharCodes([19]),
  String.fromCharCodes([20]),
  String.fromCharCodes([21]),
  String.fromCharCodes([22]),
  String.fromCharCodes([23]),
  String.fromCharCodes([24]),
  String.fromCharCodes([25]),
  String.fromCharCodes([26]),
  String.fromCharCodes([27]),
  String.fromCharCodes([28]),
  String.fromCharCodes([29]),
  String.fromCharCodes([30]),
  String.fromCharCodes([31]),
];
```
  </details>


  ### 2. Replace all control characters in string
  <details>
  <summary>Replace all control characters</summary>

  ```dart
  controlCharacters.forEach((element) {
      text = text.replaceAll(element, '');
    });
  ```
</details>
</details>
