import 'package:flutter/services.dart';

import '../../document/models/attributes/paste-style.model.dart';
import '../../embeds/models/image.model.dart';

class PasteState {
  // === COPY TEXT ===

  // Used to restore the styles of a copied fragment of text.
  // This is necessary because Flutter remote input only stores the plain text.
  // Therefore a separate system is needed for tracking the styles of copied fragment of text.
  // As of Jan 2023 it works only on mobiles. To be extended for web as well.
  List<PasteStyleM> styles = [];
  String plainText = '';

  // === COPY IMAGE ===

  // Clipboard for image url and its corresponding style.
  // item1 is url and item2 is style string.
  // TODO Review. Add model class if needed
  ImageM? _copiedImageUrl;

  ImageM? get copiedImageUrl => _copiedImageUrl;

  set copiedImageUrl(ImageM? imgUrl) {
    _copiedImageUrl = imgUrl;
    Clipboard.setData(const ClipboardData(text: ''));
  }
}
