// Useful for creating new empty documents when initialising Visual Editor inputs.
// All keywords, titles, and text fields use delta format.
// So there are many places where this can be used as a failsafe value.
// Notice that Visual Editor requires an end of line character at the end of documents.
// And at least one insert operation.
const EMPTY_DELTA_DOC_JSON = '[{"insert":"\\n"}]';
const LOREM_LIPSUM_DOC_JSON = '[{"insert":"Lorem ipsum dolor sit amet, consectetur adipiscing elit, '
    'sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\\n"}]';
