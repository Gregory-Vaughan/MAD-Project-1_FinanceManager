import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

void main() {
  runApp(const MaterialApp(home: IncomeExpenseTracker()));
}

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

class IncomeExpenseTracker extends StatefulWidget {
  const IncomeExpenseTracker({super.key});

  @override
  State<IncomeExpenseTracker> createState() => _IncomeExpenseTrackerState();
}

class _IncomeExpenseTrackerState extends State<IncomeExpenseTracker> {
  final List<Transaction> _transactions = [];
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool? _isIncome;
  int _currentPage = 0;

  String? _selectedCategory;

  final int _transactionsPerPage = 20;

  final List<String> _incomeCategories = ['Dividends', 'Work', 'Business', 'Crypto', 'Transfer', 'Other'];
  final List<String> _expenseCategories = ['Gas', 'Shopping', 'Restaurant', 'Groceries', 'Other', 'Travel'];

  @override
  void initState() {
    super.initState();
    _generateFakeTransactions(50); // Generate 50 test transactions on app start
  }

  void _generateFakeTransactions(int count) {
    final random = Random();
    for (int i = 0; i < count; i++) {
      bool isIncome = random.nextBool();
      final category = isIncome
          ? _incomeCategories[random.nextInt(_incomeCategories.length)]
          : _expenseCategories[random.nextInt(_expenseCategories.length)];
      _transactions.add(
        Transaction(
          amount: random.nextInt(500) + 50,
          category: category,
          date: DateTime.now().subtract(Duration(days: random.nextInt(30))),
          note: 'Test Transaction ${i + 1}',
          isIncome: isIncome,
        ),
      );
    }
  }

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

  double _totalIncome() {
    return _transactions.where((tx) => tx.isIncome).fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double _totalExpense() {
    return _transactions.where((tx) => !tx.isIncome).fold(0.0, (sum, tx) => sum + tx.amount);
  }

  List<Transaction> _paginatedTransactions() {
    int start = _currentPage * _transactionsPerPage;
    int end = start + _transactionsPerPage;
    return _transactions.sublist(start, end > _transactions.length ? _transactions.length : end);
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
      appBar: AppBar(title: const Text('Income & Expense Tracker')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Amount Input
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),

              // Type Dropdown
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

              // Category Dropdown - only shows if Type is selected
              if (_isIncome != null)
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categoryOptions
                      .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedCategory = value),
                ),

              // Note Input
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note'),
              ),

              // Date Picker
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

              // Add Transaction Button
              ElevatedButton(
                onPressed: _addTransaction,
                child: const Text('Add Transaction'),
              ),

              const SizedBox(height: 20),

              // Totals Section
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

              // Transaction List with Scrollable Container
              SizedBox(
                height: 400,
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

              // Pagination Controls
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
      ),
    );
  }
}
