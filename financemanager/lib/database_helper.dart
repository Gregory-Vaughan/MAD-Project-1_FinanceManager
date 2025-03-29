import 'models/transaction.dart';
import 'models/savings_goal.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  final List<Transaction> _transactions = [];
  final List<SavingsGoal> _savingsGoals = [];

  // Transactions
  List<Transaction> get transactions => List.unmodifiable(_transactions);

  void addTransaction(Transaction tx) => _transactions.insert(0, tx);

  void updateTransaction(int index, Transaction updatedTx) {
    if (index >= 0 && index < _transactions.length) {
      _transactions[index] = updatedTx;
    }
  }

  void deleteTransaction(int index) {
    if (index >= 0 && index < _transactions.length) {
      _transactions.removeAt(index);
    }
  }

  // Savings Goals
  List<SavingsGoal> get savingsGoals => List.unmodifiable(_savingsGoals);

  void addSavingsGoal(SavingsGoal goal) => _savingsGoals.add(goal);

  void updateSavedAmount(int index, double amount) {
    if (index >= 0 && index < _savingsGoals.length) {
      _savingsGoals[index].savedAmount += amount;
    }
  }

  void updateSavingsGoal(int index, SavingsGoal goal) {
    if (index >= 0 && index < _savingsGoals.length) {
      _savingsGoals[index] = goal;
    }
  }

  void deleteSavingsGoal(int index) {
    if (index >= 0 && index < _savingsGoals.length) {
      _savingsGoals.removeAt(index);
    }
  }

  void clearAll() {
    _transactions.clear();
    _savingsGoals.clear();
  }
}
