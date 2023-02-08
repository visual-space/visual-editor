enum TextLineSlot {

  // The leading slot is usually used by bullets or checkboxes.
  LEADING,

  // This used to be named BODY, but using this convention in other parts of the code was not helpful.
  // It was difficult to trace the meaning of the tokens.
  UNDERLYING_TEXT,
}
