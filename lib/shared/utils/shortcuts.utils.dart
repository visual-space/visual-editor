import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../document/models/attributes/attributes-aliases.model.dart';
import '../../document/models/attributes/attributes.model.dart';
import '../../inputs/intents/apply-checklist.intent.dart';
import '../../inputs/intents/apply-header.intent.dart';
import '../../inputs/intents/indent-selection.intent.dart';
import '../../inputs/intents/open-searchbar.intent.dart';
import '../../inputs/intents/toggle-text-style.intent.dart';
import '../../shared/utils/platform.utils.dart';

// On macOs we don't have control and we need to switch to LogicalKeyboardKey.meta which is 'command' key on macOs and control on windows.
final _keyboardKeyByOs =
    isAppleOS() ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control;

// Shortcuts responsible for applying styling.
final Map<ShortcutActivator, Intent> shortcuts = {
  // === INDENTATION ===

  LogicalKeySet(
    _keyboardKeyByOs,
    LogicalKeyboardKey.bracketRight,
  ): const IndentSelectionIntent(true),

  LogicalKeySet(
    _keyboardKeyByOs,
    LogicalKeyboardKey.bracketLeft,
  ): const IndentSelectionIntent(false),

  // === SELECTION FORMATTING ===

  LogicalKeySet(
    _keyboardKeyByOs,
    LogicalKeyboardKey.keyB,
  ): ToggleTextStyleIntent(
    AttributesM.bold,
  ),

  LogicalKeySet(
    _keyboardKeyByOs,
    LogicalKeyboardKey.keyU,
  ): ToggleTextStyleIntent(
    AttributesM.underline,
  ),

  LogicalKeySet(
    _keyboardKeyByOs,
    LogicalKeyboardKey.keyI,
  ): ToggleTextStyleIntent(
    AttributesM.italic,
  ),

  LogicalKeySet(
    _keyboardKeyByOs,
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.keyS,
  ): ToggleTextStyleIntent(
    AttributesM.strikeThrough,
  ),

  LogicalKeySet(
    _keyboardKeyByOs,
    LogicalKeyboardKey.backquote,
  ): ToggleTextStyleIntent(
    AttributesM.inlineCode,
  ),

  LogicalKeySet(
    _keyboardKeyByOs,
    LogicalKeyboardKey.keyL,
  ): ToggleTextStyleIntent(
    AttributesAliasesM.bulletList,
  ),

  LogicalKeySet(
    _keyboardKeyByOs,
    LogicalKeyboardKey.keyO,
  ): ToggleTextStyleIntent(
    AttributesAliasesM.orderedList,
  ),

  LogicalKeySet(
    _keyboardKeyByOs,
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.keyB,
  ): ToggleTextStyleIntent(
    AttributesM.blockQuote,
  ),

  LogicalKeySet(
    _keyboardKeyByOs,
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.tilde,
  ): ToggleTextStyleIntent(
    AttributesM.codeBlock,
  ),

  // === HEADERS ===

  // H1
  LogicalKeySet(
    _keyboardKeyByOs,
    LogicalKeyboardKey.digit1,
  ): ApplyHeaderIntent(
    AttributesAliasesM.h1,
  ),

  // H2
  LogicalKeySet(
    _keyboardKeyByOs,
    LogicalKeyboardKey.digit2,
  ): ApplyHeaderIntent(
    AttributesAliasesM.h2,
  ),

  // H3
  LogicalKeySet(
    _keyboardKeyByOs,
    LogicalKeyboardKey.digit3,
  ): ApplyHeaderIntent(
    AttributesAliasesM.h3,
  ),

  // No heading
  LogicalKeySet(
    _keyboardKeyByOs,
    LogicalKeyboardKey.digit0,
  ): ApplyHeaderIntent(
    AttributesM.header,
  ),

  // === CHECKLIST ===

  LogicalKeySet(
    _keyboardKeyByOs,
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.keyL,
  ): const ApplyChecklistIntent(),

  // === SEARCHBAR ===

  LogicalKeySet(
    _keyboardKeyByOs,
    LogicalKeyboardKey.keyF,
  ): OpenSearchbarIntent(),
};
