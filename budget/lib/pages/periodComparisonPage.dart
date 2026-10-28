import 'dart:math';
import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/categoryIcon.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/util/showDatePicker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum ComparisonMode { monthOverMonth, yearOverYear, weekOverWeek, quarterOverQuarter, custom }

class PeriodComparisonPage extends StatefulWidget {
  const PeriodComparisonPage({Key? key}) : super(key: key);

  @override
  State<PeriodComparisonPage> createState() => _PeriodComparisonPageState();
}

class _PeriodComparisonPageState extends State<PeriodComparisonPage> {
  ComparisonMode _selectedMode = ComparisonMode.monthOverMonth;
  late DateTimeRange _currentPeriod;
  late DateTimeRange _previousPeriod;

  @override
  void initState() {
    super.initState();
    _computePeriods(ComparisonMode.monthOverMonth);
  }

  void _computePeriods(ComparisonMode mode) {
    final now = DateTime.now();
    switch (mode) {
      case ComparisonMode.monthOverMonth:
        // Current: this month
        final curStart = DateTime(now.year, now.month, 1);
        final curEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        // Previous: last month
        final prevStart = DateTime(now.year, now.month - 1, 1);
        final prevEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
        _currentPeriod = DateTimeRange(start: curStart, end: curEnd);
        _previousPeriod = DateTimeRange(start: prevStart, end: prevEnd);
        break;

      case ComparisonMode.yearOverYear:
        // Current: this year
        final curStart = DateTime(now.year, 1, 1);
        final curEnd = DateTime(now.year, 12, 31, 23, 59, 59);
        // Previous: last year
        final prevStart = DateTime(now.year - 1, 1, 1);
        final prevEnd = DateTime(now.year - 1, 12, 31, 23, 59, 59);
        _currentPeriod = DateTimeRange(start: curStart, end: curEnd);
        _previousPeriod = DateTimeRange(start: prevStart, end: prevEnd);
        break;

      case ComparisonMode.weekOverWeek:
        // Current: past 7 days
        final curEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        final curStart = curEnd.subtract(const Duration(days: 6));
        // Previous: 7 days before that
        final prevEnd = curStart.subtract(const Duration(seconds: 1));
        final prevStart = prevEnd.subtract(const Duration(days: 6));
        _currentPeriod = DateTimeRange(start: curStart, end: curEnd);
        _previousPeriod = DateTimeRange(start: prevStart, end: prevEnd);
        break;

      case ComparisonMode.quarterOverQuarter:
        int currentQuarter = ((now.month - 1) ~/ 3) + 1;
        int currentQuarterStartMonth = (currentQuarter - 1) * 3 + 1;
        final curStart = DateTime(now.year, currentQuarterStartMonth, 1);
        final curEnd = DateTime(now.year, currentQuarterStartMonth + 3, 0, 23, 59, 59);

        int prevQuarter = currentQuarter == 1 ? 4 : currentQuarter - 1;
        int prevYear = currentQuarter == 1 ? now.year - 1 : now.year;
        int prevQuarterStartMonth = (prevQuarter - 1) * 3 + 1;
        final prevStart = DateTime(prevYear, prevQuarterStartMonth, 1);
        final prevEnd = DateTime(prevYear, prevQuarterStartMonth + 3, 0, 23, 59, 59);

        _currentPeriod = DateTimeRange(start: curStart, end: curEnd);
        _previousPeriod = DateTimeRange(start: prevStart, end: prevEnd);
        break;

      case ComparisonMode.custom:
        // Keep existing
        break;
    }
  }

  void _onModeSelected(ComparisonMode mode) async {
    if (mode == ComparisonMode.custom) {
      // Pick custom periods
      DateTime? curStart = await showCustomDatePicker(context, _currentPeriod.start, helpText: "Current Period Start");
      if (curStart != null && mounted) {
        DateTime? curEnd = await showCustomDatePicker(context, _currentPeriod.end, helpText: "Current Period End");
        if (curEnd != null && mounted) {
          DateTime? prevStart = await showCustomDatePicker(context, _previousPeriod.start, helpText: "Baseline Period Start");
          if (prevStart != null && mounted) {
            DateTime? prevEnd = await showCustomDatePicker(context, _previousPeriod.end, helpText: "Baseline Period End");
            if (prevEnd != null && mounted) {
              setState(() {
                _selectedMode = ComparisonMode.custom;
                _currentPeriod = DateTimeRange(start: curStart, end: curEnd);
                _previousPeriod = DateTimeRange(start: prevStart, end: prevEnd);
              });
            }
          }
        }
      }
    } else {
      setState(() {
        _selectedMode = mode;
        _computePeriods(mode);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allWallets = Provider.of<AllWallets>(context, listen: true);

    return PageFramework(
      title: "financial-period-comparison".tr(),
      backButton: true,
      dragDownToDismiss: true,
      horizontalPaddingConstrained: true,
      slivers: [
        // Mode Selector Chips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip("month-over-month".tr(), ComparisonMode.monthOverMonth, theme),
                      const SizedBox(width: 8),
                      _buildChip("year-over-year".tr(), ComparisonMode.yearOverYear, theme),
                      const SizedBox(width: 8),
                      _buildChip("week-over-week".tr(), ComparisonMode.weekOverWeek, theme),
                      const SizedBox(width: 8),
                      _buildChip("quarter-over-quarter".tr(), ComparisonMode.quarterOverQuarter, theme),
                      const SizedBox(width: 8),
                      _buildChip("custom".tr(), ComparisonMode.custom, theme),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFont(
                              text: "current-period".tr().toUpperCase(),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              textColor: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(height: 2),
                            TextFont(
                              text: "${getWordedDateShort(_currentPeriod.start)} – ${getWordedDateShort(_currentPeriod.end)}",
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFont(
                              text: "baseline-period".tr().toUpperCase(),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              textColor: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 2),
                            TextFont(
                              text: "${getWordedDateShort(_previousPeriod.start)} – ${getWordedDateShort(_previousPeriod.end)}",
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Calculations and Comparative Cards
        StreamBuilder<List<Transaction>>(
          stream: database.watchAllTransactions(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }

            final allTx = snapshot.data ?? [];

            // Calculate Period 1 (Current)
            double curIncome = 0.0;
            double curExpense = 0.0;
            int curTxCount = 0;
            Map<String, double> curCategoryExpenses = {};

            for (var tx in allTx) {
              if (tx.paid != true) continue;
              if (tx.dateCreated.isAfter(_currentPeriod.start) && tx.dateCreated.isBefore(_currentPeriod.end)) {
                double amount = amountRatioToPrimaryCurrency(allWallets, tx.walletFk) * tx.amount;
                curTxCount++;
                if (amount > 0) {
                  curIncome += amount;
                } else if (amount < 0) {
                  double posExp = amount.abs();
                  curExpense += posExp;
                  curCategoryExpenses[tx.categoryFk] = (curCategoryExpenses[tx.categoryFk] ?? 0.0) + posExp;
                }
              }
            }

            // Calculate Period 2 (Previous)
            double prevIncome = 0.0;
            double prevExpense = 0.0;
            int prevTxCount = 0;
            Map<String, double> prevCategoryExpenses = {};

            for (var tx in allTx) {
              if (tx.paid != true) continue;
              if (tx.dateCreated.isAfter(_previousPeriod.start) && tx.dateCreated.isBefore(_previousPeriod.end)) {
                double amount = amountRatioToPrimaryCurrency(allWallets, tx.walletFk) * tx.amount;
                prevTxCount++;
                if (amount > 0) {
                  prevIncome += amount;
                } else if (amount < 0) {
                  double posExp = amount.abs();
                  prevExpense += posExp;
                  prevCategoryExpenses[tx.categoryFk] = (prevCategoryExpenses[tx.categoryFk] ?? 0.0) + posExp;
                }
              }
            }

            double curNet = curIncome - curExpense;
            double prevNet = prevIncome - prevExpense;

            double curSavingsRate = curIncome > 0 ? (curNet / curIncome) * 100 : 0.0;
            double prevSavingsRate = prevIncome > 0 ? (prevNet / prevIncome) * 100 : 0.0;

            int curDays = max(1, _currentPeriod.end.difference(_currentPeriod.start).inDays);
            int prevDays = max(1, _previousPeriod.end.difference(_previousPeriod.start).inDays);

            double curDailySpend = curExpense / curDays;
            double prevDailySpend = prevExpense / prevDays;

            return SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 16),
                  child: Column(
                    children: [
                      // Expenses Comparison Card (Lower is Favorable)
                      _buildComparisonCard(
                        title: "expenses".tr(),
                        currentValue: curExpense,
                        prevValue: prevExpense,
                        allWallets: allWallets,
                        lowerIsBetter: true,
                        theme: theme,
                      ),
                      const SizedBox(height: 12),
                      // Income Comparison Card (Higher is Favorable)
                      _buildComparisonCard(
                        title: "income".tr(),
                        currentValue: curIncome,
                        prevValue: prevIncome,
                        allWallets: allWallets,
                        lowerIsBetter: false,
                        theme: theme,
                      ),
                      const SizedBox(height: 12),
                      // Net Cash Flow Comparison Card
                      _buildComparisonCard(
                        title: "net-cash-flow".tr(),
                        currentValue: curNet,
                        prevValue: prevNet,
                        allWallets: allWallets,
                        lowerIsBetter: false,
                        theme: theme,
                      ),
                      const SizedBox(height: 12),
                      // Normalized Daily Average Comparison Card (Especially when days differ)
                      _buildComparisonCard(
                        title: curDays == prevDays ? "daily-average".tr() : "${'daily-average'.tr()} (${'normalized'.tr()})",
                        currentValue: curDailySpend,
                        prevValue: prevDailySpend,
                        allWallets: allWallets,
                        lowerIsBetter: true,
                        theme: theme,
                      ),
                      const SizedBox(height: 12),
                      // Savings Rate Comparison Card
                      _buildPercentageMetricCard(
                        title: "savings-rate".tr(),
                        currentPercent: curSavingsRate,
                        prevPercent: prevSavingsRate,
                        theme: theme,
                      ),
                      const SizedBox(height: 12),
                      // Transaction Count
                      _buildCountMetricCard(
                        title: "total-transactions".tr(),
                        currentCount: curTxCount,
                        prevCount: prevTxCount,
                        theme: theme,
                      ),
                    ],
                  ),
                ),

                // Category-by-Category Comparative Breakdown
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 32),
                  child: Container(
                    padding: const EdgeInsetsDirectional.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFont(
                          text: "category-comparisons".tr(),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: 14),
                        FutureBuilder<List<TransactionCategory>>(
                          future: database.getAllCategories(),
                          builder: (context, catSnapshot) {
                            final categories = catSnapshot.data ?? [];
                            final Map<String, TransactionCategory> catMap = {
                              for (var c in categories) c.categoryPk: c
                            };

                            final allCatKeys = {...curCategoryExpenses.keys, ...prevCategoryExpenses.keys}.toList();
                            if (allCatKeys.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: TextFont(
                                    text: "no-category-data-for-periods".tr(),
                                    fontSize: 14,
                                    textColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                                  ),
                                ),
                              );
                            }

                            allCatKeys.sort((a, b) {
                              double maxA = max(curCategoryExpenses[a] ?? 0, prevCategoryExpenses[a] ?? 0);
                              double maxB = max(curCategoryExpenses[b] ?? 0, prevCategoryExpenses[b] ?? 0);
                              return maxB.compareTo(maxA);
                            });

                            return Column(
                              children: allCatKeys.map((catFk) {
                                final cat = catMap[catFk];
                                double curVal = curCategoryExpenses[catFk] ?? 0.0;
                                double prevVal = prevCategoryExpenses[catFk] ?? 0.0;
                                double diff = curVal - prevVal;
                                bool favorable = diff <= 0; // lower expense is favorable

                                String changeText;
                                if (prevVal == 0 && curVal == 0) {
                                  changeText = "0%";
                                } else if (prevVal == 0) {
                                  changeText = "New";
                                } else {
                                  double pct = ((curVal - prevVal) / prevVal.abs()) * 100;
                                  changeText = "${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%";
                                }

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          if (cat != null)
                                            CategoryIcon(
                                              category: cat,
                                              size: 22,
                                              borderRadius: 8,
                                              sizePadding: 6,
                                            ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextFont(
                                              text: cat?.name ?? "other".tr(),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Row(
                                                children: [
                                                  TextFont(
                                                    text: convertToMoney(allWallets, curVal),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  TextFont(
                                                    text: "vs ${convertToMoney(allWallets, prevVal)}",
                                                    fontSize: 11,
                                                    textColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                                                  ),
                                                ],
                                              ),
                                              TextFont(
                                                text: changeText,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                textColor: favorable ? getColor(context, "incomeAmount") : getColor(context, "expenseAmount"),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildChip(String label, ComparisonMode mode, ThemeData theme) {
    final isSelected = _selectedMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) _onModeSelected(mode);
      },
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildComparisonCard({
    required String title,
    required double currentValue,
    required double prevValue,
    required AllWallets allWallets,
    required bool lowerIsBetter,
    required ThemeData theme,
  }) {
    double diff = currentValue - prevValue;
    bool isFavorable = lowerIsBetter ? diff <= 0 : diff >= 0;
    Color trendColor = isFavorable ? getColor(context, "incomeAmount") : getColor(context, "expenseAmount");

    String percentText;
    if (prevValue == 0) {
      percentText = currentValue == 0 ? "0%" : "No baseline";
    } else {
      double pct = ((currentValue - prevValue) / prevValue.abs()) * 100;
      percentText = "${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%";
    }

    return Container(
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextFont(
                text: title.toUpperCase(),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                textColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: trendColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFavorable ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 14,
                      color: trendColor,
                    ),
                    const SizedBox(width: 4),
                    TextFont(
                      text: percentText,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      textColor: trendColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFont(
                      text: "current".tr(),
                      fontSize: 11,
                      textColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                    const SizedBox(height: 2),
                    TextFont(
                      text: convertToMoney(allWallets, currentValue),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFont(
                      text: "baseline".tr(),
                      fontSize: 11,
                      textColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                    const SizedBox(height: 2),
                    TextFont(
                      text: convertToMoney(allWallets, prevValue),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      textColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextFont(
                      text: "difference".tr(),
                      fontSize: 11,
                      textColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                    const SizedBox(height: 2),
                    TextFont(
                      text: "${diff >= 0 ? '+' : ''}${convertToMoney(allWallets, diff)}",
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      textColor: trendColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageMetricCard({
    required String title,
    required double currentPercent,
    required double prevPercent,
    required ThemeData theme,
  }) {
    double diff = currentPercent - prevPercent;
    bool isFavorable = diff >= 0;
    Color trendColor = isFavorable ? getColor(context, "incomeAmount") : getColor(context, "expenseAmount");

    return Container(
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFont(
                text: title.toUpperCase(),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                textColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
              const SizedBox(height: 4),
              TextFont(
                text: "${currentPercent.toStringAsFixed(1)}% vs ${prevPercent.toStringAsFixed(1)}%",
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          TextFont(
            text: "${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}%",
            fontSize: 14,
            fontWeight: FontWeight.bold,
            textColor: trendColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCountMetricCard({
    required String title,
    required int currentCount,
    required int prevCount,
    required ThemeData theme,
  }) {
    int diff = currentCount - prevCount;
    return Container(
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFont(
                text: title.toUpperCase(),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                textColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
              const SizedBox(height: 4),
              TextFont(
                text: "$currentCount vs $prevCount",
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          TextFont(
            text: "${diff >= 0 ? '+' : ''}$diff tx",
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }
}
