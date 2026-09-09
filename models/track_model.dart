import 'package:flutter/material.dart';

enum InstrumentType {
  guitar,
  keyboard,
  vocals,
  drums,
  bass,
  other,
}

class TrackModel {
  final String id;
  String name;
  final InstrumentType instrumentType;
  String? filePath;
  double volume; // 0.0 to 1.0
  double pan; // -1.0 to 1.0
  bool isMuted;
  bool isSolo;
  bool isArmedForRec;
  Duration duration;
  List<double> waveformSamples;
  Color trackColor;

  TrackModel({
    required this.id,
    required this.name,
    required this.instrumentType,
    this.filePath,
    this.volume = 0.8,
    this.pan = 0.0,
    this.isMuted = false,
    this.isSolo = false,
    this.isArmedForRec = false,
    this.duration = Duration.zero,
    List<double>? waveformSamples,
    Color? trackColor,
  })  : waveformSamples = waveformSamples ?? [],
        trackColor = trackColor ?? _getDefaultColor(instrumentType);

  static Color _getDefaultColor(InstrumentType type) {
    switch (type) {
      case InstrumentType.guitar:
        return const Color(0xFFFF9500); // Amber Orange
      case InstrumentType.keyboard:
        return const Color(0xFF00E5FF); // Cyan Neon
      case InstrumentType.vocals:
        return const Color(0xFFFF2A6D); // Neon Magenta
      case InstrumentType.drums:
        return const Color(0xFF00E676); // Emerald Green
      case InstrumentType.bass:
        return const Color(0xFF9D4EDD); // Electric Purple
      case InstrumentType.other:
        return const Color(0xFF536DFE); // Indigo
    }
  }

  IconData get icon {
    switch (instrumentType) {
      case InstrumentType.guitar:
        return Icons.music_note;
      case InstrumentType.keyboard:
        return Icons.piano;
      case InstrumentType.vocals:
        return Icons.mic;
      case InstrumentType.drums:
        return Icons.album;
      case InstrumentType.bass:
        return Icons.graphic_eq;
      case InstrumentType.other:
        return Icons.audiotrack;
    }
  }

  bool get hasAudio => filePath != null && filePath!.isNotEmpty;

  TrackModel copyWith({
    String? id,
    String? name,
    InstrumentType? instrumentType,
    String? filePath,
    double? volume,
    double? pan,
    bool? isMuted,
    bool? isSolo,
    bool? isArmedForRec,
    Duration? duration,
    List<double>? waveformSamples,
    Color? trackColor,
  }) {
    return TrackModel(
      id: id ?? this.id,
      name: name ?? this.name,
      instrumentType: instrumentType ?? this.instrumentType,
      filePath: filePath ?? this.filePath,
      volume: volume ?? this.volume,
      pan: pan ?? this.pan,
      isMuted: isMuted ?? this.isMuted,
      isSolo: isSolo ?? this.isSolo,
      isArmedForRec: isArmedForRec ?? this.isArmedForRec,
      duration: duration ?? this.duration,
      waveformSamples: waveformSamples ?? this.waveformSamples,
      trackColor: trackColor ?? this.trackColor,
    );
  }
}
