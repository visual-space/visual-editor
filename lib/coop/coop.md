# Coop (WIP)

* **Collaborative editing**, when a change came from a different site and has already been normalized by heuristic rules on that site. Care must be taken to ensure that this change is based on the same revision of the document, and if not, transformed against any local changes before composing.
* **Change history and revisioning**, when a change came from a revision history stored on a server or a database. Similarly, care must be taken to transform the change against any local (uncommitted) changes before composing.

When composing a change which came from a different site or server make
sure to use `ChangeSource.remote` when calling `compose()`. This allows
you to distinguish such changes from local changes made by the user
when listening on `NotusDocument.changes` stream.
