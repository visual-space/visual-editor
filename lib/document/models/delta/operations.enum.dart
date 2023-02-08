// Retains length of characters and optionally applies attributes.
// Does not change the characters indicated by the length param.
const String RETAIN_KEY = 'retain';
const String INSERT_KEY = 'insert';
const String DELETE_KEY = 'delete';

const String ATTRIBUTES_KEY = 'attributes';

const List<String> VALID_OP_KEYS = [INSERT_KEY, DELETE_KEY, RETAIN_KEY];