/// One dot on the days rail: its centre along the rail and its diameter.
typedef RailDot = ({double centre, double size});

/// Where the days rail puts its dots (SPEC BR-6).
abstract final class DaysRailLayout {
  static const double todaySize = 10;
  static const double laterSize = 6;
  static const double smallestSize = 2;

  /// The least space kept between two later dots.
  static const double minGap = 2;

  /// [count] dots across [width]: today at the start edge, the other days centred in equal slots
  /// over the rest, shrinking from [laterSize] towards [smallestSize] to keep [minGap].
  static List<RailDot> dots({required int count, required double width}) {
    final double slot = count > 1 ? (width - todaySize) / (count - 1) : 0;
    final double size = (slot - minGap).clamp(smallestSize, laterSize).toDouble();
    return <RailDot>[
      (centre: todaySize / 2, size: todaySize),
      for (int i = 1; i < count; i++) (centre: todaySize + slot * (i - 1) + slot / 2, size: size),
    ];
  }
}
