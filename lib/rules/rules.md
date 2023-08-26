# Rules
Visual Editor (as in Quill) has a list of rules that are executed after each document change. Custom rules can be added on top of the core rules. Rules are split in 3 sets: delete, format, insert. Rules are contain logic to be executed once a certain trigger/condition is fulfilled. For ex: One rule is to break out of blocks when 2 new white lines are inserted. Such a rule will attempt to go trough the entire document and scan for lines of text that match the condition: 2 white lines one after the other. Once such a pair is detected, then we modify the second line styling to remove the block attribute. 

The example above illustrates one potential use case for rules. However there are many other operations that can be shared between multiple text editing operations. Most of them will need: index, length, document and the new attribute. Some rules will apply only to the current text selection, some will apply to the entire document. Each rule is free to decide how to approach solving it's particular problem. When the toolbar buttons are pressed, we prepare a style change for the document. Most of the toolbar buttons will use the current selection to apply style changes via controller.formatSelection(). However it's possible to write code that does not depend on the selection and can be given any arbitrary range (including the full doc).


## Architecture (WIP)
The rules list is applied in pure functional fashion. No GUI operations are executed in the rules code.


## Delete Rules
- **Catch All Delete Rule** - Fallback rule for delete operations which simply deletes specified text range without any special handling.
- **Ensure Embed Line Rule** - Prevents user from merging a line containing an embed with other lines.
- **Ensure Last Line Break Delete Rule**
- **Preserve Line Style On Merge Rule** - Preserves line format when user deletes the line's newline character effectively merging it with the next line. This rule makes sure to apply all style attributes of deleted newline to the next available newline, which may reset any style attributes already present there.


## Format Rules
- **Format Link AtCaret Position Rule** - Allows updating link format with collapsed selection.
- **Resolve Image Format Rule** - Produces Delta with attributes applied to image leaf node
- **Resolve Inline Format Rule** - Produces Delta with inline-level attributes applied to all characters except newlines.
- **Resolve Line Format Rule** - Produces Delta with line-level attributes applied strictly to newline characters.

## Insert Rules
- **Auto Exit Block Rule** - Heuristic rule to exit current block when user inserts two consecutive newlines. This rule is only applied when the cursor is on the last line of a block. When the cursor is in the middle of a block we allow adding empty lines and preserving the block's style. For example, if you are in bullet list, pressing enter once will create a new bullet, pressing enter twice will terminate the bullet list. The same happens for any other block type (indents, code block, etc).
- **Auto Format Links Rule** - Applies link format to text segment (which looks like a link) when user inserts space character after it.
- **Auto Format Multiple Links Rule** - Applies link formatting to inserted text that matches the URL pattern. It determines the affected words by retrieving the word before and after the insertion point, and searches for matches within them. If there are no matches, the method does not apply any format. If there are matches, it builds a base delta for the insertion and a formatter delta for formatting changes. The formatter delta only includes link formatting when necessary. After processing all matches, the method composes the base delta and formatter delta to obtain the resulting change delta.
- **Catch All Insert Rule** - Fallback rule which simply inserts text as-is without any special handling.
- **Insert Embeds Rule** - Handles all format operations which manipulate embeds. This rule wraps line breaks around video, not image.
- **Preserve Block Style On Insert Rule** - Preserves block style when user inserts text containing newlines.  This rule handles:  inserting a new line in a block and pasting text containing multiple lines of text in a block. This rule may also be activated for changes triggered by auto-correct.  
- **Preserve Inline Styles Rule** - Preserves inline styles when user inserts text inside formatted segment.
- **Preserve Line Style On Split Rule** - Preserves line format when user splits the line into two. This rule ignores scenarios when the line is split on its edge,  meaning a newline is inserted at the beginning or the end of a line.
- **Reset Line Format On New Line Rule** - Resets format for a newly inserted line when insert occurred at the end of a line (right before a newline). This handles scenarios when a new line is added when at the end of a heading line. The newly added line should be a regular paragraph.


## Actions & Intents

