# Rules (WIP)
Visual Editor (as in Quill) has a list of rules that are executed after each document change Rules are contain logic to be executed once a certain trigger/condition is fulfilled. For ex: One rule is to break out of blocks when 2 new white lines are inserted. Such a rule will attempt to go trough the entire document and scan for lines of text that match the condition: 2 white lines one after the other. Once such a pair is detected, then we modify the second line styling to remove the block attribute. The example above illustrates one potential use case for rules. However there are many other operations that can be shared between multiple text editing operations. Most of them will need: index, length, document and the new attribute. Some rules will apply only to the current text selection, some will apply to the entire document. Each rule is free to decide how to approach solving it's particular problem. When the toolbar buttons are pressed, we prepare a style change for the document. Most of the toolbar buttons will use the current selection to apply style changes via controller.formatSelection(). However it's possible to write code that does not depend on the selection and can be given any arbitrary range (including the full doc).

## Applying Rules (WIP)

## Rules list (WIP)
TODO Document every rule.

### Auto Exit Block
Heuristic rule to exit current block when user inserts two consecutive newlines. This rule is only applied when the cursor is on the last line of a block. When the cursor is in the middle of a block we allow adding empty lines and preserving the block's style. For example, if you are in bullet list, pressing enter once will create a new bullet, pressing enter twice will terminate the bullet list. The same happens for any other block type (indents, code block, etc).

## Actions & Intents

Join on [discord](https://discord.gg/XpGygmXde4) to get advice and help or follow us on [YouTube Visual Coding](https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA) to learn more about the architecture of Visual Editor and other Flutter apps.