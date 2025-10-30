class IraqiCurrencyHelper {
  static const int minUnit = 250;

  static const List<int> availableUnits = [
    250,
    500,
    750,
    1000,
    1250,
    1500,
    1750,
    2000,
  ];

  static double roundToNearest250(double amount) {
    if (amount < 2000) {
      return 2000.0;
    }

    final remainder = amount % minUnit;
    if (remainder == 0) {
      return amount;
    }

    if (remainder < (minUnit / 2)) {
      return amount - remainder;
    } else {
      return amount + (minUnit - remainder);
    }
  }

  static double roundUpTo250(double amount) {
    if (amount < 2000) {
      return 2000.0;
    }

    final remainder = amount % minUnit;
    if (remainder == 0) {
      return amount;
    }

    return amount + (minUnit - remainder);
  }

  static double roundDownTo250(double amount) {
    if (amount < 2000) {
      return 2000.0;
    }

    final remainder = amount % minUnit;
    return amount - remainder;
  }

  static bool isValidAmount(double amount) {
    return amount >= 2000 && (amount % minUnit == 0);
  }

  static double getValidAmount(double amount) {
    return roundToNearest250(amount);
  }

  static String formatAmount(double amount) {
    final validAmount = roundToNearest250(amount);
    return '${validAmount.toInt()} د.ع';
  }

  static List<int> getSuggestedAmounts() {
    return [
      2000,
      5000,
      10000,
      20000,
      50000,
      100000,
    ];
  }
}
