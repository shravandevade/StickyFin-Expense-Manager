import 'dart:math';
import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/categoryIcon.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/util/showDatePicker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum StatPeriodType { thisMonth, lastMonth, last3Months, thisYear, allTime, custom }

class AdvancedStatisticsPage extends StatefulWidget {
  const AdvancedStatisticsPage({Key? key}) : super(key: key);

  @override
  State<AdvancedStatisticsPage> createState() => _AdvancedStatisticsPageState();
}

class _AdvancedStatisticsPageState extends State<AdvancedStatisticsPage> {
  StatPeriodType _selectedPeriod = StatPeriodType.thisMonth;
  late DateTimeRange _currentRange;
  String? _selectedWalletFk;

  @override
  void initState() {
    super.initState();
    _currentRange = _getRangeForPeriod(StatPeriodType.thisMonth);
  }

  DateTimeRange _getRangeForPeriod(StatPeriodType period) {
    final now = DateTime.now();
    switch (period) {
      case StatPeriodType.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case StatPeriodType.lastMonth:
        final start = DateTime(now.year, now.month - 1, 1);
        final end = DateTime(now.year, now.month, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case StatPeriodType.last3Months:
        final start = DateTime(now.year, now.month - 2, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case StatPeriodType.thisYear:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, 12, 31, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case StatPeriodType.allTime:
        final start = DateTime(2000, 1, 1);
        final end = DateTime(now.year + 1, 12, 31, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case StatPeriodType.custom:
        return _currentRange;
    }
  }

  void _onPeriodSelected(StatPeriodType period) async {
    if (period == StatPeriodType.custom) {
      DateTime? start = await showCustomDatePicker(context, _currentRange.start, helpText: "Start Date");
      if (start != null && mounted) {
        DateTime? end = await showCustomDatePicker(context, _currentRange.end, helpText: "End Date");
        if (end != null && mounted) {
          if (end.isBefore(start)) {
            final tmp = start;
            start = end;
            end = tmp;
          }
          setState(() {
            _selectedPeriod = StatPeriodType.custom;
            _currentRange = DateTimeRange(
              start: DateTime(start!.year, start.month, start.day),
              end: DateTime(end!.year, end.month, end.day, 23, 59, 59),
            );
          });
        }
      }
    } else {
      setState(() {
        _selectedPeriod = period;
        _currentRange = _getRangeForPeriod(period);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allWallets = Provider.of<AllWallets>(context, listen: true);

    return PageFramework(
      title: "advanced-statistics".tr(),
      backButton: true,
      dragDownToDismiss: true,
      horizontalPaddingConstrained: true,
      slivers: [
        // Filter Controls
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Selector Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip("this-month".tr(), StatPeriodType.thisMonth, theme),
                      const SizedBox(width: 8),
                      _buildChip("last-month".tr(), StatPeriodType.lastMonth, theme),
                      const SizedBox(width: 8),
                      _buildChip("3-months".tr(), StatPeriodType.last3Months, theme),
                      const SizedBox(width: 8),
                      _buildChip("this-year".tr(), StatPeriodType.thisYear, theme),
                      const SizedBox(width: 8),
                      _buildChip("all-time".tr(), StatPeriodType.allTime, theme),
                      const SizedBox(width: 8),
                      _buildChip("custom".tr(), StatPeriodType.custom, theme),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextFont(
                  text: "${getWordedDateShort(_currentRange.start)} – ${getWordedDateShort(_currentRange.end)}",
                  fontSize: 13,
                  textColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
        ),

        // Statistics Content from Stream
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

            final allTransactions = snapshot.data ?? [];
            final filteredTx = allTransactions.where((tx) {
              if (tx.paid != true) return false;
              if (_selectedWalletFk != null && tx.walletFk != _selectedWalletFk) return false;
              return tx.dateCreated.isAfter(_currentRange.start) &&
                  tx.dateCreated.isBefore(_currentRange.end);
            }).toList();

            double totalIncome = 0.0;
            double totalExpense = 0.0;
            double largestExpense = 0.0;
            double largestIncome = 0.0;
            Map<String, double> categorySpending = {};
            Map<String, double> walletActivity = {};

            for (var tx in filteredTx) {
              double amount = amountRatioToPrimaryCurrency(allWallets, tx.walletFk) * tx.amount;
              if (amount > 0) {
                totalIncome += amount;
                if (amount > largestIncome) largestIncome = amount;
              } else if (amount < 0) {
                double positiveExpense = amount.abs();
                totalExpense += positiveExpense;
                if (positiveExpense > largestExpense) largestExpense = positiveExpense;

                categorySpending[tx.categoryFk] = (categorySpending[tx.categoryFk] ?? 0.0) + positiveExpense;
              }
              walletActivity[tx.walletFk] = (walletActivity[tx.walletFk] ?? 0.0) + amount;
            }

            double netCashFlow = totalIncome - totalExpense;
            double savingsRate = totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome) * 100 : 0.0;
            int daysInRange = max(1, _currentRange.end.difference(_currentRange.start).inDays);
            double dailyAverageSpend = totalExpense / daysInRange;
            double avgTxValue = filteredTx.isNotEmpty ? (totalExpense + totalIncome) / filteredTx.length : 0.0;

            return SliverList(
              delegate: SliverChildListDelegate([
                // Primary KPI Summary Cards
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              title: "income".tr(),
                              value: convertToMoney(allWallets, totalIncome),
                              icon: Icons.arrow_downward_rounded,
                              color: getColor(context, "incomeAmount"),
                              theme: theme,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              title: "expenses".tr(),
                              value: convertToMoney(allWallets, totalExpense),
                              icon: Icons.arrow_upward_rounded,
                              color: getColor(context, "expenseAmount"),
                              theme: theme,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              title: "net-cash-flow".tr(),
                              value: convertToMoney(allWallets, netCashFlow),
                              icon: netCashFlow >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                              color: netCashFlow >= 0 ? getColor(context, "incomeAmount") : getColor(context, "expenseAmount"),
                              theme: theme,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              title: "savings-rate".tr(),
                              value: totalIncome > 0 ? "${savingsRate.toStringAsFixed(1)}%" : "N/A",
                              icon: Icons.savings_rounded,
                              color: savingsRate >= 20 ? getColor(context, "incomeAmount") : theme.colorScheme.primary,
                              theme: theme,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Transaction Insights
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 16),
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
                          text: "transaction-insights".tr(),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: 12),
                        _buildInsightRow("total-transactions".tr(), "${filteredTx.length}", theme),
                        const Divider(height: 16),
                        _buildInsightRow("average-daily-spend".tr(), convertToMoney(allWallets, dailyAverageSpend), theme),
                        const Divider(height: 16),
                        _buildInsightRow("average-transaction-value".tr(), convertToMoney(allWallets, avgTxValue), theme),
                        const Divider(height: 16),
                        _buildInsightRow("largest-expense".tr(), convertToMoney(allWallets, largestExpense), theme),
                        const Divider(height: 16),
                        _buildInsightRow("largest-income".tr(), convertToMoney(allWallets, largestIncome), theme),
                      ],
                    ),
                  ),
                ),

                // Category Breakdown Section
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 16),
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
                          text: "expenses-by-category".tr(),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: 12),
                        if (categorySpending.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: TextFont(
                                text: "no-expenses-recorded".tr(),
                                fontSize: 14,
                                textColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                              ),
                            ),
                          )
                        else
                          FutureBuilder<List<TransactionCategory>>(
                            future: database.getAllCategories(),
                            builder: (context, catSnapshot) {
                              final categories = catSnapshot.data ?? [];
                              final Map<String, TransactionCategory> catMap = {
                                for (var c in categories) c.categoryPk: c
                              };

                              final sortedCategories = categorySpending.entries.toList()
                                ..sort((a, b) => b.value.compareTo(a.value));

                              return Column(
                                children: sortedCategories.map((entry) {
                                  final cat = catMap[entry.key];
                                  final double percent = totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0.0;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            if (cat != null)
                                              CategoryIcon(
                                                category: cat,
                                                size: 24,
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
                                            TextFont(
                                              text: convertToMoney(allWallets, entry.value),
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            const SizedBox(width: 8),
                                            TextFont(
                                              text: "${percent.toStringAsFixed(1)}%",
                                              fontSize: 12,
                                              textColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: min(1.0, percent / 100),
                                            minHeight: 6,
                                            backgroundColor: theme.colorScheme.surfaceVariant,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              cat != null
                                                  ? HexColor(cat.colour, defaultColor: theme.colorScheme.primary)
                                                  : theme.colorScheme.primary,
                                            ),
                                          ),
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

                // Budget Adherence Card
                StreamBuilder<List<Budget>>(
                  stream: database.watchAllBudgets(hideArchived: true),
                  builder: (context, budgetSnapshot) {
                    final budgets = budgetSnapshot.data ?? [];
                    if (budgets.isEmpty) return const SizedBox.shrink();

                    return Padding(
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
                              text: "budget-adherence".tr(),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            const SizedBox(height: 12),
                            _buildInsightRow("active-budgets".tr(), "${budgets.length}", theme),
                            const SizedBox(height: 8),
                            TextFont(
                              text: "unlimited-budgets-active".tr(),
                              fontSize: 12,
                              textColor: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildChip(String label, StatPeriodType period, ThemeData theme) {
    final isSelected = _selectedPeriod == period;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) _onPeriodSelected(period);
      },
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsetsDirectional.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: TextFont(
                  text: title.toUpperCase(),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  textColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFont(
            text: value,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextFont(
          text: label,
          fontSize: 14,
          textColor: theme.colorScheme.onSurfaceVariant,
        ),
        TextFont(
          text: value,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ],
    );
  }
}
