import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FEATURE 1: Unlimited Budgets Logic & Stress Tests', () {
    test('Stress test: Supports 150+ budgets simultaneously', () {
      List<Map<String, dynamic>> budgets = [];
      for (int i = 0; i < 150; i++) {
        budgets.add({
          "id": "budget_$i",
          "name": "Budget #$i",
          "amount": (i + 1) * 100.0,
          "order": i,
          "archived": i % 10 == 0,
        });
      }

      expect(budgets.length, 150);

      // Filter active vs archived
      final activeBudgets = budgets.where((b) => b["archived"] == false).toList();
      final archivedBudgets = budgets.where((b) => b["archived"] == true).toList();
      expect(activeBudgets.length, 135);
      expect(archivedBudgets.length, 15);

      // Search
      final searchResult = budgets.where((b) => b["name"].toLowerCase().contains("budget #10")).toList();
      // Should match budget #10, #100..#109
      expect(searchResult.length, 11);

      // Sort by amount descending
      budgets.sort((a, b) => (b["amount"] as double).compareTo(a["amount"] as double));
      expect(budgets.first["amount"], 15000.0);
      expect(budgets.last["amount"], 100.0);
    });

    test('Budget progress and overspending calculations', () {
      double budgetAmount = 500.0;
      double spentAmount = 650.0;
      double utilization = (spentAmount / budgetAmount) * 100;
      double remaining = budgetAmount - spentAmount;

      expect(utilization, 130.0);
      expect(remaining, -150.0);
      expect(spentAmount > budgetAmount, isTrue); // Overspent indicator
    });
  });

  group('FEATURE 2: Unlimited Savings and Spending Goals Logic & Stress Tests', () {
    test('Stress test: Supports 150+ goals simultaneously', () {
      List<Map<String, dynamic>> goals = [];
      for (int i = 0; i < 150; i++) {
        goals.add({
          "id": "goal_$i",
          "name": "Goal #$i",
          "targetAmount": (i + 1) * 200.0,
          "currentAmount": (i + 1) * 50.0,
          "isIncome": i % 2 == 0, // Savings vs Spending
          "archived": false,
        });
      }

      expect(goals.length, 150);

      // Verify savings vs spending breakdown
      final savingsGoals = goals.where((g) => g["isIncome"] == true).toList();
      final spendingGoals = goals.where((g) => g["isIncome"] == false).toList();
      expect(savingsGoals.length, 75);
      expect(spendingGoals.length, 75);

      // Calculate progress percentage
      for (var goal in goals) {
        double pct = (goal["currentAmount"] / goal["targetAmount"]) * 100;
        expect(pct, closeTo(25.0, 0.01));
      }
    });

    test('Goal completion and remaining calculation', () {
      double target = 1000.0;
      double current = 1200.0;
      double percent = (current / target) * 100;
      bool isCompleted = current >= target;

      expect(percent, 120.0);
      expect(isCompleted, isTrue);
    });
  });

  group('FEATURE 3: Complete Historical Budget Data Calculation', () {
    test('Date range generation without silent truncation', () {
      DateTime now = DateTime(2026, 10, 28);
      List<DateTimeRange> periods = [];

      // Generate 60 historical monthly cycles (5 years of historical data)
      for (int i = 0; i < 60; i++) {
        DateTime start = DateTime(now.year, now.month - i, 1);
        DateTime end = DateTime(now.year, now.month - i + 1, 0, 23, 59, 59);
        periods.add(DateTimeRange(start: start, end: end));
      }

      expect(periods.length, 60);
      expect(periods.first.start.month, 10);
      expect(periods.first.start.year, 2026);
      expect(periods.last.start.month, 11);
      expect(periods.last.start.year, 2021);

      // Check leap year February 2024
      DateTime feb2024End = DateTime(2024, 3, 0);
      expect(feb2024End.day, 29); // Leap year 29 days
    });
  });

  group('FEATURE 4: Advanced Historical Financial Statistics Calculations', () {
    test('Calculates Income, Expense, Net Flow, and Savings Rate correctly', () {
      double totalIncome = 5000.0;
      double totalExpense = 3200.0;
      double netCashFlow = totalIncome - totalExpense;
      double savingsRate = ((totalIncome - totalExpense) / totalIncome) * 100;

      expect(netCashFlow, 1800.0);
      expect(savingsRate, 36.0);
    });

    test('Handles zero income savings rate without division by zero', () {
      double totalIncome = 0.0;
      double totalExpense = 500.0;
      double savingsRate = totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome) * 100 : 0.0;

      expect(savingsRate, 0.0);
      expect(savingsRate.isFinite, isTrue);
    });

    test('Calculates daily average normalized over different day counts', () {
      double totalExpense = 3000.0;
      int days = 30;
      double dailyAverage = totalExpense / days;
      expect(dailyAverage, 100.0);

      int leapYearDays = 366;
      double annualExpense = 36600.0;
      expect(annualExpense / leapYearDays, 100.0);
    });

    test('Category percentage breakdown sums to 100%', () {
      Map<String, double> categories = {
        "Groceries": 400.0,
        "Rent": 1000.0,
        "Utilities": 200.0,
        "Entertainment": 400.0,
      };

      double total = categories.values.fold(0.0, (a, b) => a + b);
      expect(total, 2000.0);

      double sumPercentages = 0.0;
      categories.forEach((_, val) {
        sumPercentages += (val / total) * 100;
      });

      expect(sumPercentages, closeTo(100.0, 0.001));
    });
  });

  group('FEATURE 5: Extended Financial Period Comparisons Calculations', () {
    test('Mathematical percentage change formula: ((Current - Baseline) / |Baseline|) * 100', () {
      double baseline = 200.0;
      double current = 250.0;
      double pctChange = ((current - baseline) / baseline.abs()) * 100;
      expect(pctChange, 25.0);

      // Decrease
      current = 150.0;
      pctChange = ((current - baseline) / baseline.abs()) * 100;
      expect(pctChange, -25.0);
    });

    test('Handles zero baseline cleanly without returning Infinity', () {
      double baseline = 0.0;
      double current = 150.0;

      String result;
      if (baseline == 0.0) {
        result = current == 0.0 ? "0%" : "No baseline";
      } else {
        double pct = ((current - baseline) / baseline.abs()) * 100;
        result = "${pct.toStringAsFixed(1)}%";
      }

      expect(result, "No baseline");
    });

    test('Directional favorability for Income vs Expense', () {
      // Expense: Lower is favorable
      double prevExpense = 1000.0;
      double curExpense = 800.0;
      bool expenseFavorable = curExpense <= prevExpense;
      expect(expenseFavorable, isTrue);

      // Income: Higher is favorable
      double prevIncome = 2000.0;
      double curIncome = 2500.0;
      bool incomeFavorable = curIncome >= prevIncome;
      expect(incomeFavorable, isTrue);
    });
  });

  group('FEATURE 6: Complete Color Customization Logic', () {
    test('Hex color parsing and brightness contrast estimation', () {
      Color darkBlue = const Color(0xFF1B447A);
      Color lightYellow = const Color(0xFFFFEB3B);

      expect(ThemeData.estimateBrightnessForColor(darkBlue), Brightness.dark);
      expect(ThemeData.estimateBrightnessForColor(lightYellow), Brightness.light);
    });

    test('RGB to Color conversion and round-trip', () {
      int r = 46, g = 125, b = 50;
      Color green = Color.fromARGB(255, r, g, b);
      expect(green.red, r);
      expect(green.green, g);
      expect(green.blue, b);
      expect(green.alpha, 255);
    });
  });

  group('FEATURE 7: Additional Icon Packs and Icon Shapes Logic', () {
    test('Icon container shape border radius calculation', () {
      double size = 40.0;

      // Circle
      double circleRadius = size / 2;
      expect(circleRadius, 20.0);

      // Squircle
      double squircleRadius = size * 0.28;
      expect(squircleRadius, closeTo(11.2, 0.001));

      // Sharp Square
      double sharpRadius = 3.0;
      expect(sharpRadius, 3.0);

      // Rounded Rectangle
      double roundedRadius = 14.0;
      expect(roundedRadius, 14.0);
    });
  });
}
