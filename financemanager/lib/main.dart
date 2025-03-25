import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  bool _isIncome = true;
  int _currentPage = 0;

  String? _selectedCategory;

  final int _transactionsPerPage = 10;

  final List<String> _incomeCategories = ['dividends', 'work', 'business', 'transfer'];
  final List<String> _expenseCategories = ['gas', 'shopping', 'groceries', 'miscellaneous', 'travel'];

  void _addTransaction() {
    if (_amountController.text.isEmpty || _selectedCategory == null) return;

    final newTx = Transaction(
      amount: double.parse(_amountController.text),
      category: _selectedCategory!,
      date: _selectedDate,
      note: _noteController.text,
      isIncome: _isIncome,
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
    _isIncome = true;
    _selectedCategory = null;
  }

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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

    final categoryOptions = _isIncome ? _incomeCategories : _expenseCategories;

    return Scaffold(
      appBar: AppBar(title: const Text('Income & Expense Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Input Form
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: categoryOptions
                  .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategory = value),
              decoration: const InputDecoration(labelText: 'Category'),
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
            Row(
              children: [
                const Text('Type:'),
                Radio(
                  value: true,
                  groupValue: _isIncome,
                  onChanged: (value) {
                    setState(() {
                      _isIncome = value!;
                      _selectedCategory = null;
                    });
                  },
                ),
                const Text('Income'),
                Radio(
                  value: false,
                  groupValue: _isIncome,
                  onChanged: (value) {
                    setState(() {
                      _isIncome = value!;
                      _selectedCategory = null;
                    });
                  },
                ),
                const Text('Expense'),
              ],
            ),
            ElevatedButton(
              onPressed: _addTransaction,
              child: const Text('Add Transaction'),
            ),
            const SizedBox(height: 20),
            // Transaction List
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
    );
  }
}
