import 'package:flutter/material.dart';

class AlphaScrollList<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) labelOf;
  final Widget Function(BuildContext, T) itemBuilder;
  final EdgeInsets padding;

  const AlphaScrollList({
    super.key,
    required this.items,
    required this.labelOf,
    required this.itemBuilder,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 4, 16),
  });

  @override
  State<AlphaScrollList<T>> createState() => _AlphaScrollListState<T>();
}

class _AlphaScrollListState<T> extends State<AlphaScrollList<T>> {
  final _scrollController = ScrollController();
  String? _activeLetter;

  static const _letters = [
    'A','B','C','Ç','D','E','F','G','Ğ','H','I','İ','J','K','L','M',
    'N','O','Ö','P','R','S','Ş','T','U','Ü','V','Y','Z','#'
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLetter(String letter) {
    final items = widget.items;
    int index = -1;
    if (letter == '#') {
      index = items.indexWhere((item) {
        final first = widget.labelOf(item).toUpperCase()[0];
        return !RegExp(r'[A-ZÇĞİÖŞÜ]').hasMatch(first);
      });
    } else {
      index = items.indexWhere((item) =>
          _normalize(widget.labelOf(item))
              .toUpperCase()
              .startsWith(_normalize(letter).toUpperCase()));
    }
    if (index < 0) return;

    const itemHeight = 72.0;
    final topPadding = widget.padding.top;
    final offset = (topPadding + index * (itemHeight + 8)).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  String _normalize(String s) {
    return s
        .replaceAll('ç', 'c').replaceAll('Ç', 'C')
        .replaceAll('ğ', 'g').replaceAll('Ğ', 'G')
        .replaceAll('ı', 'i').replaceAll('İ', 'I')
        .replaceAll('ö', 'o').replaceAll('Ö', 'O')
        .replaceAll('ş', 's').replaceAll('Ş', 'S')
        .replaceAll('ü', 'u').replaceAll('Ü', 'U');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            padding: widget.padding,
            itemCount: widget.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                widget.itemBuilder(context, widget.items[index]),
          ),
        ),
        _LetterBar(
          letters: _letters,
          activeLetter: _activeLetter,
          onLetter: (letter) {
            setState(() => _activeLetter = letter);
            _scrollToLetter(letter);
          },
        ),
      ],
    );
  }
}

class _LetterBar extends StatelessWidget {
  final List<String> letters;
  final String? activeLetter;
  final void Function(String) onLetter;

  const _LetterBar({
    required this.letters,
    required this.activeLetter,
    required this.onLetter,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) =>
          _handleDrag(context, details.localPosition.dy),
      onTapDown: (details) =>
          _handleDrag(context, details.localPosition.dy),
      child: Container(
        width: 24,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: letters.map((letter) {
                final isActive = letter == activeLetter;
                return Text(
                  letter,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  void _handleDrag(BuildContext context, double dy) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final height = box.size.height - 16;
    final index =
        ((dy - 8) / height * letters.length).floor().clamp(0, letters.length - 1);
    onLetter(letters[index]);
  }
}
