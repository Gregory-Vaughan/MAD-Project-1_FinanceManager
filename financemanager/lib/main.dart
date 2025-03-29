import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MaterialApp(home: IncomeExpenseTracker()));
}

// ---------------------- Models ----------------------
class Transaction {
  final double amount;
  final String category;
  final DateTime date;
  final String note;
  final bool isIncome;

  Transaction({
    required this.amount,
    required this.category,
    required this.date,
    required this.note,
    required this.isIncome,
  });
}

class SavingsGoal {
  final String name;
  final double targetAmount;
  final DateTime targetDate;
  double savedAmount;

  SavingsGoal({
    required this.name,
    required this.targetAmount,
    required this.targetDate,
    this.savedAmount = 0.0,
  });
}

// ---------------------- Main Screen ----------------------
class IncomeExpenseTracker extends StatefulWidget {
  const IncomeExpenseTracker({super.key});

  @override
  State<IncomeExpenseTracker> createState() => _IncomeExpenseTrackerState();
}

class _IncomeExpenseTrackerState extends State<IncomeExpenseTracker> {
  final List<Transaction> _transactions = [];
  final List<SavingsGoal> _savingsGoals = [];

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool? _isIncome;
  String? _selectedCategory;
  int _currentPage = 0;
  final int _transactionsPerPage = 20;

  final List<String> _incomeCategories = ['Dividends', 'Work', 'Business', 'Crypto', 'Transfer', 'Other'];
  final List<String> _expenseCategories = ['Gas', 'Shopping', 'Restaurant', 'Groceries', 'Other', 'Travel'];

  void _addTransaction() {
    if (_amountController.text.isEmpty || _selectedCategory == null || _isIncome == null) return;

    final newTx = Transaction(
      amount: double.parse(_amountController.text),
      category: _selectedCategory!,
      date: _selectedDate,
      note: _noteController.text,
      isIncome: _isIncome!,
    );

    setState(() {
      _transactions.insert(0, newTx);
      _clearInputs();
    });
  }

  void _clearInputs() {
    _amountController.clear();
    _noteController.clear();
    _selectedDate = DateTime.now();
    _isIncome = null;
    _selectedCategory = null;
  }

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  double _totalIncome() => _transactions.where((tx) => tx.isIncome).fold(0.0, (sum, tx) => sum + tx.amount);
  double _totalExpense() => _transactions.where((tx) => !tx.isIncome).fold(0.0, (sum, tx) => sum + tx.amount);

  List<Transaction> _paginatedTransactions() {
    int start = _currentPage * _transactionsPerPage;
    int end = start + _transactionsPerPage;
    return _transactions.sublist(start, end > _transactions.length ? _transactions.length : end);
  }

  void _addSavingsGoal(String name, double targetAmount, DateTime targetDate) {
    setState(() {
      _savingsGoals.add(SavingsGoal(name: name, targetAmount: targetAmount, targetDate: targetDate));
    });
  }

  void _updateSavedAmount(int index, double amount) {
    setState(() {
      _savingsGoals[index].savedAmount += amount;
    });
  }

  void _navigateToSavingsGoals(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => SavingsGoalsScreen(
          savingsGoals: _savingsGoals,
          onAddGoal: _addSavingsGoal,
          onUpdateSavedAmount: _updateSavedAmount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final paginatedTx = _paginatedTransactions();
    final totalIncome = _totalIncome();
    final totalExpense = _totalExpense();
    final netBalance = totalIncome - totalExpense;
    final categoryOptions = _isIncome == true ? _incomeCategories : _expenseCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Income & Expense Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.savings),
            tooltip: "Savings Goals",
            onPressed: () => _navigateToSavingsGoals(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            DropdownButtonFormField<bool>(
              value: _isIncome,
              decoration: const InputDecoration(labelText: 'Transaction Type'),
              items: const [
                DropdownMenuItem(value: true, child: Text('Income')),
                DropdownMenuItem(value: false, child: Text('Expense')),
              ],
              onChanged: (value) {
                setState(() {
                  _isIncome = value;
                  _selectedCategory = null;
                });
              },
            ),
            if (_isIncome != null)
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categoryOptions
                    .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
              ),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Date: ${formatter.format(_selectedDate)}"),
                TextButton(
                  onPressed: _pickDate,
                  child: const Text('Pick Date'),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _addTransaction,
              child: const Text('Add Transaction'),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.grey[200],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text('Total Income: \$${totalIncome.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.green, fontSize: 16)),
                    Text('Total Expense: \$${totalExpense.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.red, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      'Balance: \$${netBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                          color: netBalance >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: paginatedTx.isEmpty
                  ? const Center(child: Text('No transactions yet.'))
                  : ListView.builder(
                      itemCount: paginatedTx.length,
                      itemBuilder: (ctx, index) {
                        final tx = paginatedTx[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: tx.isIncome ? Colors.green : Colors.red,
                              child: Text(
                                tx.isIncome ? '+' : '-',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text('${tx.category} - \$${tx.amount.toStringAsFixed(2)}'),
                            subtitle: Text('${formatter.format(tx.date)} | ${tx.note}'),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null,
                  child: const Text('Previous'),
                ),
                Text('Page ${_currentPage + 1}'),
                TextButton(
                  onPressed: (_currentPage + 1) * _transactionsPerPage < _transactions.length
                      ? () => setState(() => _currentPage++)
                      : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------- Savings Goal Screen ----------------------
class SavingsGoalsScreen extends StatelessWidget {
  final List<SavingsGoal> savingsGoals;
  final Function(String, double, DateTime) onAddGoal;
  final Function(int, double) onUpdateSavedAmount;

  const SavingsGoalsScreen({
    super.key,
    required this.savingsGoals,
    required this.onAddGoal,
    required this.onUpdateSavedAmount,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    void _showAddGoalDialog() {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Add New Savings Goal"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Goal Name"),
                ),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: "Target Amount"),
                  keyboardType: TextInputType.number,
                ),
                Row(
                  children: [
                    Text("Target Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}"),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          selectedDate = picked;
                        }
                      },
                      child: const Text("Pick Date"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                onAddGoal(
                  nameController.text,
                  double.parse(amountController.text),
                  selectedDate,
                );
                Navigator.of(ctx).pop();
                (context as Element).markNeedsBuild(); // Triggers widget rebuild
              },

              child: const Text("Add"),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Savings Goals")),
      body: ListView.builder(
        itemCount: savingsGoals.length,
        itemBuilder: (ctx, index) {
          final goal = savingsGoals[index];
          return Card(
            child: ListTile(
              title: Text(goal.name),
              subtitle: Text(
                  "Target: \$${goal.targetAmount.toStringAsFixed(2)}\nSaved: \$${goal.savedAmount.toStringAsFixed(2)}\nDue: ${DateFormat('yyyy-MM-dd').format(goal.targetDate)}"),
              trailing: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) {
                      final TextEditingController savedAmountController = TextEditingController();
                      return AlertDialog(
                        title: const Text("Add to Saved Amount"),
                        content: TextField(
                          controller: savedAmountController,
                          decoration: const InputDecoration(labelText: "Amount"),
                          keyboardType: TextInputType.number,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              onUpdateSavedAmount(index, double.parse(savedAmountController.text));
                              Navigator.of(ctx).pop();
                            },
                            child: const Text("Add"),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
