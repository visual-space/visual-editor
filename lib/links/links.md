# Links

- Links in text can be edited or added using the toolbar or link menu. The
  AutoFormatMultipleLinksRule automatically adds a link attribute to matching text.
- AutoFormatMultipleLinksRule: Applies link formatting to inserted text that matches the URL pattern.
  It determines the affected words by retrieving the word before and after the insertion point,
  and searches for matches within them. If there are no matches, the method does not apply any format.
  If there are matches, it builds a base delta for the insertion and a formatter delta for formatting changes.
  The formatter delta only includes link formatting when necessary. After processing all matches,
  the method composes the base delta and formatter delta to obtain the resulting change delta.

## Link menu

- The link menu displays the link's URL and has options to remove, edit, or copy it. The menu is
  placed using the Offset flutter API in the overlay.service.

