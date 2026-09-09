import 'package:flutter/material.dart';
import '../../services/synth_service.dart';
import '../../theme/app_theme.dart';

class VirtualPiano extends StatefulWidget {
  final ValueChanged<String>? onNotePressed;
  final String? highlightedNote; // Nota alvo da aula para iluminar no teclado
  final double height;

  const VirtualPiano({
    super.key,
    this.onNotePressed,
    this.highlightedNote,
    this.height = 140,
  });

  @override
  State<VirtualPiano> createState() => _VirtualPianoState();
}

class _VirtualPianoState extends State<VirtualPiano> {
  final Set<String> _activeNotes = {};

  // Teclas brancas e pretas organizadas (2 oitavas: C4 até B5)
  final List<String> _whiteNotes = ['C4', 'D4', 'E4', 'F4', 'G4', 'A4', 'B4', 'C5', 'D5', 'E5', 'F5', 'G5'];
  
  // Mapa de notas pretas e suas posições relativas às brancas
  final Map<int, String> _blackNotesMap = {
    0: 'C#4',
    1: 'D#4',
    3: 'F#4',
    4: 'G#4',
    5: 'A#4',
    7: 'C#5',
    8: 'D#5',
    10: 'F#5',
  };

  void _triggerNote(String note) {
    setState(() => _activeNotes.add(note));
    SynthService().playNote(note);
    widget.onNotePressed?.call(note);

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() => _activeNotes.remove(note));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF101014),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double whiteKeyWidth = constraints.maxWidth / _whiteNotes.length;
            final double blackKeyWidth = whiteKeyWidth * 0.62;
            final double blackKeyHeight = widget.height * 0.60;

            return Stack(
              children: [
                // 1. Camada de Teclas Brancas
                Row(
                  children: _whiteNotes.map((note) {
                    final isPressed = _activeNotes.contains(note);
                    final isTarget = widget.highlightedNote == note;

                    return GestureDetector(
                      onTapDown: (_) => _triggerNote(note),
                      child: Container(
                        width: whiteKeyWidth,
                        height: widget.height,
                        decoration: BoxDecoration(
                          color: isPressed
                              ? AppTheme.cyan.withOpacity(0.85)
                              : (isTarget
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFF0F0F3)),
                          border: Border.all(color: Colors.black54, width: 0.75),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
                          boxShadow: isPressed
                              ? [BoxShadow(color: AppTheme.cyan.withOpacity(0.5), blurRadius: 10)]
                              : null,
                        ),
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          note,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPressed
                                ? Colors.black
                                : (isTarget ? Colors.green.shade900 : Colors.black54),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // 2. Camada de Teclas Pretas
                ..._blackNotesMap.entries.map((entry) {
                  final index = entry.key;
                  final note = entry.value;
                  final isPressed = _activeNotes.contains(note);
                  final isTarget = widget.highlightedNote == note;

                  final double leftPos = (index + 1) * whiteKeyWidth - (blackKeyWidth / 2);

                  return Positioned(
                    left: leftPos,
                    top: 0,
                    child: GestureDetector(
                      onTapDown: (_) => _triggerNote(note),
                      child: Container(
                        width: blackKeyWidth,
                        height: blackKeyHeight,
                        decoration: BoxDecoration(
                          color: isPressed
                              ? AppTheme.cyan
                              : (isTarget ? Colors.green.shade700 : const Color(0xFF1E1E24)),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                          border: Border.all(color: Colors.black, width: 1),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black87,
                              blurRadius: 4,
                              offset: Offset(1, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.only(bottom: 4),
                        child: isTarget
                            ? Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
