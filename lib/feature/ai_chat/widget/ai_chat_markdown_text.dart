import 'package:demandium/util/core_export.dart';

/// Lightweight **bold** and bullet rendering for assistant messages.
class AiChatMarkdownText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? color;

  const AiChatMarkdownText({
    super.key,
    required this.text,
    this.style,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final base = style ?? robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault);
    final textColor = color ?? base.color ?? Theme.of(context).textTheme.bodyLarge?.color;

    return RichText(
      text: TextSpan(
        style: base.copyWith(color: textColor, height: 1.35),
        children: _parseSpans(text, base.copyWith(color: textColor)),
      ),
    );
  }

  List<InlineSpan> _parseSpans(String input, TextStyle base) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    var start = 0;
    for (final m in regex.allMatches(input)) {
      if (m.start > start) {
        spans.add(TextSpan(text: input.substring(start, m.start)));
      }
      spans.add(TextSpan(
        text: m.group(1),
        style: base.copyWith(fontWeight: FontWeight.w600),
      ));
      start = m.end;
    }
    if (start < input.length) {
      spans.add(TextSpan(text: input.substring(start)));
    }
    if (spans.isEmpty) {
      spans.add(TextSpan(text: input));
    }
    return spans;
  }
}
