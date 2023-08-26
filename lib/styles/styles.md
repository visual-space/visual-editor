# Styles (WIP)


## Custom Style Builder (WIP)
Custom styles can be defined for custom attributes.


## Blocking the styles buttons when selecting code
When an user selects inline code or text inside a code block it makes no sense to enable the styling options in the toolbar. Code should not be styled. Therefore we disable the toolbar options when code is selected (newly created or existing). To ensure no such styles are applied at all we also disable `controller.formatSelection()` to apply styles to code blocks. That means both the GUI and the controller are blocked.

- **Architecture** - We did not create a new RuleM for blocking the styles because we need to modify the UI as well. Rules are purely functional and are not the right place to block styles. In fact, the rules are designed to apply additional manipulations/edits on the document. So It's clearly not the right place to write the styling blocking code for code blocks and inlines.