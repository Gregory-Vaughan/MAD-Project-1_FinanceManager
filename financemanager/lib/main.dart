import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'models/transaction.dart';
import 'models/savings_goal.dart';
import 'package:fl_chart/fl_chart.dart';


void main() 
{
  runApp(const MaterialApp(home: DashboardScreen()));
  
   runApp(MaterialApp
   (
    theme: ThemeData(
      scaffoldBackgroundColor: Colors.green, 
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.yellow,
          foregroundColor: Colors.black, 
        ),
      ),
      textButtonTheme: TextButtonThemeData
      (
        style: TextButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.yellow,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black, 
      ),
      fontFamily: 'Roboto', 
    ),
    home: const DashboardScreen(),
  ));
}
  

// ---------------------- Main Screen ----------------------
class IncomeExpenseTracker extends StatefulWidget {
  const IncomeExpenseTracker({super.key});

  @override
  State<IncomeExpenseTracker> createState() => _IncomeExpenseTrackerState();
}

class _IncomeExpenseTrackerState extends State<IncomeExpenseTracker> {
  final db = DatabaseHelper();

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
      db.addTransaction(newTx);
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

  double _totalIncome() => db.transactions.where((tx) => tx.isIncome).fold(0.0, (sum, tx) => sum + tx.amount);
  double _totalExpense() => db.transactions.where((tx) => !tx.isIncome).fold(0.0, (sum, tx) => sum + tx.amount);

  List<Transaction> _paginatedTransactions() {
    int start = _currentPage * _transactionsPerPage;
    int end = start + _transactionsPerPage;
    return db.transactions.sublist(start, end > db.transactions.length ? db.transactions.length : end);
  }

void _navigateToSavingsGoals(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (ctx) => SavingsGoalsScreen(
        savingsGoals: db.savingsGoals,
        onAddGoal: (name, amount, date) {
          db.addSavingsGoal(SavingsGoal(
            name: name,
            targetAmount: amount,
            targetDate: date,
          ));
        },
        onUpdateSavedAmount: db.updateSavedAmount,
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
                          fontSize: 18,
                          fontFamily: 'Courier',
                          ),
                          
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
                                 //fontFamily: 'Courier', 
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
                  onPressed: (_currentPage + 1) * _transactionsPerPage < db.transactions.length

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
class SavingsGoalsScreen extends StatefulWidget {
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
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  void _showAddGoalDialog({int? editIndex}) {
    final isEditing = editIndex != null;

    if (isEditing) {
      final goal = widget.savingsGoals[editIndex];
      _nameController.text = goal.name;
      _amountController.text = goal.targetAmount.toString();
      _selectedDate = goal.targetDate;
    } else {
      _nameController.clear();
      _amountController.clear();
      _selectedDate = DateTime.now();
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? "Edit Goal" : "Add New Savings Goal"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Goal Name"),
              ),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: "Target Amount"),
                keyboardType: TextInputType.number,
              ),
              Row(
                children: [
                  Text("Target Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}"),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
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
              final name = _nameController.text;
              final amount = double.tryParse(_amountController.text);
              if (name.isEmpty || amount == null) return;

              setState(() {
                if (isEditing) {
                  final goal = widget.savingsGoals[editIndex];
                  goal.name = name;
                  goal.targetAmount = amount;
                  goal.targetDate = _selectedDate;
                } else {
                  widget.onAddGoal(name, amount, _selectedDate);
                }
              });

              Navigator.of(ctx).pop();
            },
            child: Text(isEditing ? "Save" : "Add"),
          ),
        ],
      ),
    );
  }

  void _showAddAmountDialog(int index) {
    final TextEditingController savedAmountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
              final amount = double.tryParse(savedAmountController.text);
              if (amount != null && amount > 0) {
                setState(() {
                  widget.onUpdateSavedAmount(index, amount);
                });
              }
              Navigator.of(ctx).pop();
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _deleteGoal(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Goal"),
        content: const Text("Are you sure you want to delete this goal?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                DatabaseHelper().deleteSavingsGoal(index);
              });
              Navigator.of(ctx).pop();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final savingsGoals = DatabaseHelper().savingsGoals;

    return Scaffold(
      appBar: AppBar(title: const Text("Savings Goals")),
      body: savingsGoals.isEmpty
          ? const Center(child: Text("No savings goals added."))
          : ListView.builder(
              itemCount: savingsGoals.length,
              itemBuilder: (ctx, index) {
                final goal = savingsGoals[index];
                final isCompleted = goal.savedAmount >= goal.targetAmount;
                final percent = (goal.savedAmount / goal.targetAmount * 100).clamp(0, 100);

                return Card(
                  child: ListTile(
                    title: Text(goal.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Target: \$${goal.targetAmount.toStringAsFixed(2)}"),
                        Text("Saved: \$${goal.savedAmount.toStringAsFixed(2)}"),
                        Text("Due: ${DateFormat('yyyy-MM-dd').format(goal.targetDate)}"),
                        Text(
                          isCompleted
                              ? "Status: ✅ Completed"
                              : "Progress: ${percent.toStringAsFixed(1)}%",
                          style: TextStyle(
                            color: isCompleted ? Colors.green : Colors.blueGrey,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Courier', 
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showAddGoalDialog(editIndex: index);
                        } else if (value == 'delete') {
                          _deleteGoal(index);
                        } else if (value == 'save') {
                          _showAddAmountDialog(index);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'save', child: Text('Add Amount')),
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ---------------------- Dashboard Screen ---------------------
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseHelper();

    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to Finance Manager')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Tools:",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
                textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Income & Expense Tracker
            Column(
              children: [
                Image.asset("assets/income_expense.gif", height: 120),
                ElevatedButton.icon(
                  icon: const Icon(Icons.account_balance_wallet),
                  label: const Text('Income & Expense Tracker'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const IncomeExpenseTracker()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Savings Goals
            Column(
              children: [
                Image.asset("assets/piggy2.gif", height: 120),
                ElevatedButton.icon(
                  icon: const Icon(Icons.savings),
                  label: const Text('Savings Goals'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SavingsGoalsScreen(
                          savingsGoals: db.savingsGoals,
                          onAddGoal: (name, amount, date) {
                            db.addSavingsGoal(SavingsGoal(
                              name: name,
                              targetAmount: amount,
                              targetDate: date,
                            ));
                          },
                          onUpdateSavedAmount: db.updateSavedAmount,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Reports
            Column(
              children: [
                Image.asset("assets/report.gif", height: 120),
                ElevatedButton.icon(
                  icon: const Icon(Icons.assessment),
                  label: const Text('View Reports'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ReportsScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Category Tracking
            Column(
              children: [
                Image.asset("assets/scales.gif", height: 120),
                ElevatedButton.icon(
                  icon: const Icon(Icons.pie_chart),
                  label: const Text('Category Tracking'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CategoryTrackingScreen(
                          transactions: db.transactions,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------- Category Tracking Screen ----------------------
class CategoryTrackingScreen extends StatelessWidget {
  final List<Transaction> transactions;

  const CategoryTrackingScreen({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final ranges = {
      'This Week': now.subtract(Duration(days: now.weekday - 1)),
      'This Month': DateTime(now.year, now.month, 1),
      'This Year': DateTime(now.year, 1, 1),
      'All Time': DateTime(2000),
    };

    String selectedRange = 'This Month';
    DateTime rangeStart = ranges[selectedRange]!;

    return StatefulBuilder(
      builder: (context, setState) {
        final filtered = transactions
            .where((tx) => tx.date.isAfter(rangeStart) || selectedRange == 'All Time')
            .toList();

        final incomeCategories = <String, double>{};
        final expenseCategories = <String, double>{};

        for (var tx in filtered) {
          final map = tx.isIncome ? incomeCategories : expenseCategories;
          map[tx.category] = (map[tx.category] ?? 0) + tx.amount;
        }

        return Scaffold(
          appBar: AppBar(title: const Text("Category Tracking")),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButton<String>(
                  value: selectedRange,
                  isExpanded: true,
                  items: ranges.keys
                      .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedRange = val!;
                      rangeStart = ranges[val]!;
                    });
                  },
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      const Text(
                        "Expenses by Category",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Arial Narrow'),
                      ),
                      ...expenseCategories.entries.map((e) => ListTile(
                            title: Text(e.key),
                            trailing: Text("- \$${e.value.toStringAsFixed(2)}", style: const TextStyle(color: Colors.red)),
                          )),
                      const SizedBox(height: 16),
                      const Text(
                        "Income by Category",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Arial Narrow'),
                      ),
                      ...incomeCategories.entries.map((e) => ListTile(
                            title: Text(e.key),
                            trailing: Text("+ \$${e.value.toStringAsFixed(2)}", style: const TextStyle(color: Colors.green)),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
// ---------------------- Reports Window ----------------------


class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseHelper();
    final totalIncome = db.transactions.where((tx) => tx.isIncome).fold(0.0, (sum, tx) => sum + tx.amount);
    final totalExpenses = db.transactions.where((tx) => !tx.isIncome).fold(0.0, (sum, tx) => sum + tx.amount);

    final Map<String, double> categorySpending = {};
    for (var tx in db.transactions.where((t) => !t.isIncome)) {
      categorySpending[tx.category] = (categorySpending[tx.category] ?? 0) + tx.amount;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Financial Reports')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text("Income vs Expenses", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Arial Narrow')),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [
                      BarChartRodData(toY: totalIncome, color: Colors.blue, width: 20),
                    ]),
                    BarChartGroupData(x: 1, barRods: [
                      BarChartRodData(toY: totalExpenses, color: Colors.red, width: 20),
                    ]),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text("\$${value.toInt()}", style: const TextStyle(fontSize: 10, fontFamily: 'Arial Narrow')),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(value == 0 ? 'Income' : 'Expenses', style: const TextStyle(fontSize: 12, fontFamily: 'Arial Narrow'));
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  maxY: (totalIncome > totalExpenses ? totalIncome : totalExpenses) * 1.2,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text("Spending by Category", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Arial Narrow')),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: categorySpending.entries.map((entry) {
                    final index = categorySpending.keys.toList().indexOf(entry.key);
                    final color = Colors.primaries[index % Colors.primaries.length];
                    return PieChartSectionData(
                      value: entry.value,
                      title: '${entry.key} (\$${entry.value.toStringAsFixed(0)})',
                      color: color,
                      radius: 60,
                      titleStyle: const TextStyle(fontSize: 12, fontFamily: 'Arial Narrow', color: Colors.white),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text("Savings Goals Progress", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
            const SizedBox(height: 10),
            ...db.savingsGoals.map((goal) {
              final percent = (goal.savedAmount / goal.targetAmount * 100).clamp(0, 100);
              final isComplete = goal.savedAmount >= goal.targetAmount;
              return ListTile(
                title: Text(goal.name),
                subtitle: Text("Saved: \$${goal.savedAmount.toStringAsFixed(2)} / \$${goal.targetAmount.toStringAsFixed(2)}"),
                trailing: Text(
                  isComplete ? "✅" : "${percent.toStringAsFixed(0)}%",
                  style: TextStyle(color: isComplete ? Colors.green : Colors.blue),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
