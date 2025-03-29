class SavingsGoal {
  String name;
  double targetAmount;
  DateTime targetDate;
  double savedAmount;

  SavingsGoal({
    required this.name,
    required this.targetAmount,
    required this.targetDate,
    this.savedAmount = 0.0,
  });
}
