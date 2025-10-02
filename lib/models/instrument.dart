enum InstrumentType {
  ukulele,
  guitar,
}

extension InstrumentTypeX on InstrumentType {
  String get displayName {
    switch (this) {
      case InstrumentType.ukulele:
        return 'Ukulele';
      case InstrumentType.guitar:
        return 'Guitar';
    }
  }

  String get description {
    switch (this) {
      case InstrumentType.ukulele:
        return 'Bright four-string starter instrument.';
      case InstrumentType.guitar:
        return 'Six-string classic for versatile playing.';
    }
  }

  String get noun {
    switch (this) {
      case InstrumentType.ukulele:
        return 'ukulele';
      case InstrumentType.guitar:
        return 'guitar';
    }
  }
}
