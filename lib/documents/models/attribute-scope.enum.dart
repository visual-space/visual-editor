// TODO Better document what the attribute scope does.
// It's not immediately apparent what each onf of these scopes does.
// As far as I can tell for now, they are used to restrict styles to line or inline level when inserting new characters.
// Rules that apply to the line can't be applied inline.
enum AttributeScope {
  INLINE, // refer to https://quilljs.com/docs/formats/#inline
  BLOCK, // refer to https://quilljs.com/docs/formats/#block
  EMBEDS, // refer to https://quilljs.com/docs/formats/#embeds
  IGNORE, // attributes that can be ignored
}
