import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../../../rules/services/insert.dart';
import '../../../shared/models/quill-dialog-theme.model.dart';
import '../../../shared/translations/toolbar.i18n.dart';

class LinkStyleDialog extends StatefulWidget {
  final QuillDialogThemeM? dialogTheme;
  final String? link;
  final String? text;

  const LinkStyleDialog({
    this.dialogTheme,
    this.link,
    this.text,
    Key? key,
  }) : super(key: key);

  @override
  _LinkStyleDialogState createState() => _LinkStyleDialogState();
}

class _LinkStyleDialogState extends State<LinkStyleDialog> {
  late String _link;
  late String _text;
  late TextEditingController _linkController;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _link = widget.link ?? '';
    _text = widget.text ?? '';
    _linkController = TextEditingController(text: _link);
    _textController = TextEditingController(text: _text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.dialogTheme?.dialogBackgroundColor,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          TextField(
            keyboardType: TextInputType.multiline,
            style: widget.dialogTheme?.inputTextStyle,
            decoration: InputDecoration(
                labelText: 'Text'.i18n,
                labelStyle: widget.dialogTheme?.labelTextStyle,
                floatingLabelStyle: widget.dialogTheme?.labelTextStyle),
            autofocus: true,
            onChanged: _textChanged,
            controller: _textController,
          ),
          const SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.multiline,
            style: widget.dialogTheme?.inputTextStyle,
            decoration: InputDecoration(
                labelText: 'Link'.i18n,
                labelStyle: widget.dialogTheme?.labelTextStyle,
                floatingLabelStyle: widget.dialogTheme?.labelTextStyle),
            autofocus: true,
            onChanged: _linkChanged,
            controller: _linkController,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _canPress() ? _applyLink : null,
          child: Text(
            'Ok'.i18n,
            style: widget.dialogTheme?.labelTextStyle,
          ),
        ),
      ],
    );
  }

  bool _canPress() {
    if (_text.isEmpty || _link.isEmpty) {
      return false;
    }

    if (!AutoFormatMultipleLinksRule.linkRegExp.hasMatch(_link)) {
      return false;
    }

    return true;
  }

  void _linkChanged(String value) {
    setState(() {
      _link = value;
    });
  }

  void _textChanged(String value) {
    setState(() {
      _text = value;
    });
  }

  void _applyLink() {
    Navigator.pop(context, Tuple2(_text.trim(), _link.trim()));
  }
}
