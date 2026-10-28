import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addBudgetPage.dart';
import 'package:budget/pages/editBudgetPage.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/budgetContainer.dart';
import 'package:budget/widgets/navigationSidebar.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart'
    hide SliverReorderableList, ReorderableDelayedDragStartListener;
import 'package:provider/provider.dart';
import 'addButton.dart';

enum BudgetFilterStatus { all, active, archived }
enum BudgetSortOption { order, nameAsc, nameDesc, amountHigh, amountLow, newest, oldest }

class BudgetsListPage extends StatefulWidget {
  const BudgetsListPage({required this.enableBackButton, Key? key})
      : super(key: key);
  final bool enableBackButton;

  @override
  State<BudgetsListPage> createState() => BudgetsListPageState();
}

class BudgetsListPageState extends State<BudgetsListPage> {
  GlobalKey<PageFrameworkState> pageState = GlobalKey();
  String _searchQuery = "";
  BudgetFilterStatus _selectedFilter = BudgetFilterStatus.all;
  BudgetSortOption _selectedSort = BudgetSortOption.order;
  final TextEditingController _searchController = TextEditingController();

  void refreshState() {
    setState(() {});
  }

  void scrollToTop() {
    pageState.currentState?.scrollToTop();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Budget> _filterAndSortBudgets(List<Budget> budgets, AllWallets allWallets) {
    List<Budget> filtered = budgets.where((b) {
      if (_selectedFilter == BudgetFilterStatus.archived) {
        if (!b.archived) return false;
      } else if (_selectedFilter == BudgetFilterStatus.active) {
        if (b.archived) return false;
        DateTimeRange range = getBudgetDate(b, DateTime.now());
        DateTime now = DateTime.now();
        if (now.isBefore(range.start) || now.isAfter(range.end)) return false;
      } else {
        // all (hide archived unless explicitly searching for archived)
        if (b.archived && _searchQuery.isEmpty) return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = b.name.toLowerCase().contains(query);
        final notesMatch = (b.notes ?? "").toLowerCase().contains(query);
        if (!nameMatch && !notesMatch) return false;
      }

      return true;
    }).toList();

    filtered.sort((a, b) {
      switch (_selectedSort) {
        case BudgetSortOption.nameAsc:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case BudgetSortOption.nameDesc:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case BudgetSortOption.amountHigh:
          double amountA = budgetAmountToPrimaryCurrency(allWallets, a);
          double amountB = budgetAmountToPrimaryCurrency(allWallets, b);
          return amountB.compareTo(amountA);
        case BudgetSortOption.amountLow:
          double amountA = budgetAmountToPrimaryCurrency(allWallets, a);
          double amountB = budgetAmountToPrimaryCurrency(allWallets, b);
          return amountA.compareTo(amountB);
        case BudgetSortOption.newest:
          return b.startDate.compareTo(a.startDate);
        case BudgetSortOption.oldest:
          return a.startDate.compareTo(b.startDate);
        case BudgetSortOption.order:
        default:
          return a.order.compareTo(b.order);
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final allWallets = Provider.of<AllWallets>(context, listen: true);
    final theme = Theme.of(context);

    return PageFramework(
      key: pageState,
      title: "budgets".tr(),
      backButton: widget.enableBackButton,
      dragDownToDismiss: widget.enableBackButton,
      horizontalPaddingConstrained: enableDoubleColumn(context) == false,
      actions: [
        IconButton(
          padding: const EdgeInsetsDirectional.all(15),
          tooltip: "edit-budgets".tr(),
          onPressed: () {
            pushRoute(
              context,
              EditBudgetPage(),
            );
          },
          icon: Icon(
            appStateSettings["outlinedIcons"]
                ? Icons.edit_outlined
                : Icons.edit_rounded,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
        if (getIsFullScreen(context))
          IconButton(
            padding: const EdgeInsetsDirectional.all(15),
            tooltip: "add-budget".tr(),
            onPressed: () {
              pushRoute(
                context,
                AddBudgetPage(
                    routesToPopAfterDelete: RoutesToPopAfterDelete.None),
              );
            },
            icon: Icon(
              appStateSettings["outlinedIcons"]
                  ? Icons.add_outlined
                  : Icons.add_rounded,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
      ],
      slivers: [
        StreamBuilder<List<Budget>>(
          stream: database.watchAllBudgets(hideArchived: false),
          builder: (context, snapshot) {
            final allBudgets = snapshot.data ?? [];
            final displayedBudgets = _filterAndSortBudgets(allBudgets, allWallets);

            double totalAllocated = 0.0;
            int activeCount = 0;
            final now = DateTime.now();
            for (var b in allBudgets) {
              if (!b.archived) {
                totalAllocated += budgetAmountToPrimaryCurrency(allWallets, b);
                DateTimeRange range = getBudgetDate(b, now);
                if (now.isAfter(range.start) && now.isBefore(range.end)) {
                  activeCount++;
                }
              }
            }

            return SliverList(
              delegate: SliverChildListDelegate([
                // Summary KPI Bar
                if (allBudgets.isNotEmpty)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 14, 12),
                    child: Container(
                      padding: const EdgeInsetsDirectional.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFont(
                                  text: "total-budgeted".tr().toUpperCase(),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  textColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                                ),
                                const SizedBox(height: 4),
                                TextFont(
                                  text: convertToMoney(allWallets, totalAllocated),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 36,
                            width: 1,
                            color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFont(
                                text: "budgets".tr().toUpperCase(),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                textColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                              ),
                              const SizedBox(height: 4),
                              TextFont(
                                text: "${allBudgets.where((b) => !b.archived).length} (" +
                                    "active".tr() +
                                    ": $activeCount)",
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // Search & Filter Bar
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.trim();
                              });
                            },
                            decoration: InputDecoration(
                              hintText: "search-budgets".tr(),
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                              ),
                              prefixIcon: Icon(
                                appStateSettings["outlinedIcons"]
                                    ? Icons.search_outlined
                                    : Icons.search_rounded,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = "";
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsetsDirectional.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Sort Menu
                      PopupMenuButton<BudgetSortOption>(
                        tooltip: "sort".tr(),
                        icon: Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            appStateSettings["outlinedIcons"]
                                ? Icons.sort_outlined
                                : Icons.sort_rounded,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        onSelected: (option) {
                          setState(() {
                            _selectedSort = option;
                          });
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: BudgetSortOption.order,
                            child: TextFont(text: "default".tr()),
                          ),
                          PopupMenuItem(
                            value: BudgetSortOption.nameAsc,
                            child: TextFont(text: "A - Z"),
                          ),
                          PopupMenuItem(
                            value: BudgetSortOption.nameDesc,
                            child: TextFont(text: "Z - A"),
                          ),
                          PopupMenuItem(
                            value: BudgetSortOption.amountHigh,
                            child: TextFont(text: "highest-amount".tr()),
                          ),
                          PopupMenuItem(
                            value: BudgetSortOption.amountLow,
                            child: TextFont(text: "lowest-amount".tr()),
                          ),
                          PopupMenuItem(
                            value: BudgetSortOption.newest,
                            child: TextFont(text: "newest".tr()),
                          ),
                          PopupMenuItem(
                            value: BudgetSortOption.oldest,
                            child: TextFont(text: "oldest".tr()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Filter Chips
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip("all".tr(), BudgetFilterStatus.all, theme),
                        const SizedBox(width: 8),
                        _buildFilterChip("active".tr(), BudgetFilterStatus.active, theme),
                        const SizedBox(width: 8),
                        _buildFilterChip("archived".tr(), BudgetFilterStatus.archived, theme),
                      ],
                    ),
                  ),
                ),
              ]),
            );
          },
        ),

        // Budgets Grid / List
        StreamBuilder<List<Budget>>(
          stream: database.watchAllBudgets(hideArchived: false),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SliverToBoxAdapter();
            }

            final allBudgets = snapshot.data ?? [];
            final displayedBudgets = _filterAndSortBudgets(allBudgets, allWallets);

            if (displayedBudgets.isEmpty && allBudgets.isEmpty) {
              return SliverPadding(
                padding: const EdgeInsetsDirectional.symmetric(vertical: 7, horizontal: 13),
                sliver: SliverToBoxAdapter(
                  child: AddButton(
                    onTap: () {},
                    openPage: AddBudgetPage(
                      routesToPopAfterDelete: RoutesToPopAfterDelete.PreventDelete,
                    ),
                    height: 180,
                  ),
                ),
              );
            }

            if (displayedBudgets.isEmpty && allBudgets.isNotEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(32),
                  child: Center(
                    child: TextFont(
                      text: "no-results-found".tr(),
                      fontSize: 15,
                      textColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsetsDirectional.symmetric(vertical: 7, horizontal: 13),
              sliver: enableDoubleColumn(context)
                  ? SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 600.0,
                        mainAxisExtent: 190,
                        mainAxisSpacing: 15.0,
                        crossAxisSpacing: 15.0,
                        childAspectRatio: 5,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          if (index == displayedBudgets.length) {
                            return AddButton(
                              onTap: () {},
                              openPage: AddBudgetPage(
                                routesToPopAfterDelete: RoutesToPopAfterDelete.PreventDelete,
                              ),
                            );
                          } else {
                            return BudgetContainer(
                              budget: displayedBudgets[index],
                            );
                          }
                        },
                        childCount: displayedBudgets.length + 1,
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          if (index == displayedBudgets.length) {
                            return AddButton(
                              onTap: () {},
                              openPage: AddBudgetPage(
                                routesToPopAfterDelete: RoutesToPopAfterDelete.PreventDelete,
                              ),
                              height: 180,
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsetsDirectional.only(bottom: 16.0),
                              child: BudgetContainer(
                                budget: displayedBudgets[index],
                                squishInactiveBudgetContainerHeight: true,
                              ),
                            );
                          }
                        },
                        childCount: displayedBudgets.length + 1,
                      ),
                    ),
            );
          },
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 50),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, BudgetFilterStatus status, ThemeData theme) {
    final isSelected = _selectedFilter == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = status;
          });
        }
      },
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
