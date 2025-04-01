#  Finance Manager App

A powerful personal finance tracking mobile application built with **Flutter**, designed to help users take control of their income, expenses, savings goals, and financial insights.

- Youtube Video: https://www.youtube.com/watch?v=DRoJ1QMNf4U&ab_channel=AGFinanceManager
- LinkTree: https://linktr.ee/Finance_Tracker

##  Features

- **Income & Expense Tracker**
  - Log income and expense transactions with category, date, amount, and notes.
  - Pagination support to efficiently manage large datasets.
  - Auto-calculates total income, expenses, and balance.

- **Savings Goals**
  - Create and manage savings goals with target amounts and deadlines.
  - Track how much has been saved so far.
  - Mark goals as completed automatically upon reaching targets.
  - Edit or delete savings goals dynamically.

- **Category Tracking**
  - Visual insights into spending/income by category.
  - Filter reports by:
    - This Week
    - This Month
    - This Year
    - All Time

- **Reports Dashboard**
  - Bar chart for Income vs. Expenses
  - Pie chart for spending by category
  - List of savings goals with completion percentages

- **User Interface**
  - Dashboard layout with animated GIFs
  - Clean material design theme
  - Responsive layouts with scrollable views

##  Architecture

- **State Management**: Native `setState()`
- **Local Storage**: Custom `DatabaseHelper` class with in-memory simulation
- **Structure**:
  - `main.dart` – All screen logic and UI components
  - `database_helper.dart` – Centralized data manager for transactions and goals


## Testing

We used a manual test-as-you-code approach:
- All features were tested immediately after implementation.
- Bugs were logged, fixed, and verified instantly using sample transactions and goals.
- Data persistence and UI responsiveness were validated on emulator and real device.

---

## Getting Started

You can Download the apk in the repo and install into an Android device or if you wish to run in your computer please do the following:

1. Clone the repo:
   ```bash
   git clone https://github.com/yourusername/finance-manager-app.git
   cd finance-manager-app
2. Get dependencies:
   flutter pub get

3. Make sure you are connected to an Android device or tro an emulator
   
4. Run app:
   Flutter Run
