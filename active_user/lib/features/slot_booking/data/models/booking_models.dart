enum BookingSlotStatus { available, fullyBooked, past }

class CourtModel {
  final String id;
  final String name;
  final double price;
  final List<String> features;
  final String activity;
  final String venueType;
  final String turfType;
  final String slotId;
  final int availableQuantity;
  final DateTime startsAt;
  final DateTime endsAt;

  const CourtModel({
    required this.id,
    required this.name,
    required this.price,
    required this.features,
    required this.activity,
    required this.venueType,
    required this.turfType,
    required this.slotId,
    required this.availableQuantity,
    required this.startsAt,
    required this.endsAt,
  });

  bool get isAvailable => availableQuantity > 0;
}

class BookingSlotModel {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final BookingSlotStatus status;
  final List<CourtModel> availableCourts;
  final double startingPrice;

  const BookingSlotModel({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.availableCourts,
    required this.startingPrice,
  });

  bool get isAvailable => status == BookingSlotStatus.available;

  int get availableCourtCount => availableCourts.length;
}

class PlayerRangeModel {
  final int minimum;
  final int recommended;
  final int maximum;

  const PlayerRangeModel({
    required this.minimum,
    required this.recommended,
    required this.maximum,
  });

  List<int> get options {
    return List<int>.generate(
      maximum - minimum + 1,
      (index) => minimum + index);
  }
}

class BookingFormatters {
  const BookingFormatters._();

  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    if (minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      return hours == 1 ? '1 hr' : '$hours hrs';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '$hours hr $remainingMinutes min';
  }
}