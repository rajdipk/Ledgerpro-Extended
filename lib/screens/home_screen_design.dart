// ignore_for_file: use_build_context_synchronously

import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../dialogs/add_business_dialog.dart';
import '../models/business_model.dart';
import '../providers/business_provider.dart';
import '../providers/currency_provider.dart';

class HomeScreenDesign extends StatefulWidget {
  const HomeScreenDesign({super.key});

  @override
  State<HomeScreenDesign> createState() => _HomeScreenDesignState();
}

class _HomeScreenDesignState extends State<HomeScreenDesign> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _businessNameController = TextEditingController();
  final FocusNode _businessNameFocusNode = FocusNode();
  // Value notifiers to trigger rebuilds
  final _supplierOverviewNotifier = ValueNotifier<int>(0);
  final _customerOverviewNotifier = ValueNotifier<int>(0);
  // Store business provider reference
  BusinessProvider? _businessProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store the business provider reference
    _businessProvider = Provider.of<BusinessProvider>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Listen to transaction changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _businessProvider?.addListener(_onBusinessDataChanged);
    });
  }

  @override
  void dispose() {
    // Safely remove listener using stored reference
    _businessProvider?.removeListener(_onBusinessDataChanged);
    _tabController.dispose();
    _businessNameController.dispose();
    _businessNameFocusNode.dispose();
    _supplierOverviewNotifier.dispose();
    _customerOverviewNotifier.dispose();
    super.dispose();
  }

  void _onBusinessDataChanged() {
    // Increment notifiers to force rebuild
    if (mounted) {
      _supplierOverviewNotifier.value++;
      _customerOverviewNotifier.value++;
    }
  }

  Future<void> _showAddBusinessDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return const AddBusinessDialog();
      },
    );
  }

  Widget _buildNoBusinessSelectedMessage() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to LedgerPro!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'To get started, please select an existing one or add a new business.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showAddBusinessDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Add New Business',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessProvider = Provider.of<BusinessProvider>(context);
    final selectedBusinessId = businessProvider.selectedBusinessId;

    return Scaffold(
      body: selectedBusinessId == null
          ? _buildNoBusinessSelectedMessage()
          : Material(
              child: Column(
                children: [
                  Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Overview for ${businessProvider.businesses.firstWhere((b) => b.id == businessProvider.selectedBusinessId, orElse: () => Business(id: "", name: "")).name}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TabBar(
                          controller: _tabController,
                          labelColor: Colors.teal[700],
                          unselectedLabelColor: Colors.grey[600],
                          indicatorColor: Colors.teal[700],
                          tabs: const [
                            Tab(
                              icon: Icon(Icons.people_alt_rounded),
                              text: 'Customers',
                            ),
                            Tab(
                              icon: Icon(Icons.local_shipping_outlined),
                              text: 'Suppliers',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Customers Tab
                        _buildScrollableContent(
                          context,
                          businessProvider,
                          isCustomer: true,
                        ),
                        // Suppliers Tab
                        _buildScrollableContent(
                          context,
                          businessProvider,
                          isCustomer: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildScrollableContent(
    BuildContext context,
    BusinessProvider businessProvider, {
    required bool isCustomer,
  }) {
    return Container(
      color: const Color(0xFFF5F6FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: isCustomer
            ? _buildCustomerOverviewSection(context, businessProvider)
            : _buildSupplierOverviewSection(context, businessProvider),
      ),
    );
  }

  String _formatNumber(double value) {
    final formatter = NumberFormat("#,##0.00", "en_US");
    return formatter.format(value);
  }

  Widget _buildBalanceCard(String title, double amount, Color color, IconData icon, BuildContext context) {
    final currencySymbol = Provider.of<CurrencyProvider>(context, listen: false).currencySymbol;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$currencySymbol${_formatNumber(amount.abs())}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      title == 'Receivable' ? 'You will receive' : 'You have to pay',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceOverviewChart(List<Map<String, dynamic>> balances, BuildContext context) {
    // Parse String dates to DateTime, sort, and take the last 30 days
    final sortedBalances = balances.take(30).toList();
    final currencySymbol = Provider.of<CurrencyProvider>(context, listen: false).currencySymbol;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Balance Overview (Last 30 Days):',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          SizedBox(
            height: 300,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 1000,
                    verticalInterval: 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[200]!,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey[200]!,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: Text(
                        'Balance ($currencySymbol)',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              '$currencySymbol${_formatNumber(value)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text(
                        'Date',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final int index = value.toInt();
                          if (index < 0 || index >= sortedBalances.length || index % 5 != 0) {
                            return const Text('');
                          }
                          final date = DateTime.parse(sortedBalances[index]['date'] as String);
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              '${date.day}/${date.month}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                      left: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                  ),
                  minX: 0,
                  maxX: (sortedBalances.length - 1).toDouble(),
                  minY: sortedBalances.map((b) => min(
                    (b['receivable_balance'] as num?)?.toDouble() ?? 0.0,
                    (b['payable_balance'] as num?)?.toDouble() ?? 0.0,
                  )).reduce(min) - 1000,
                  maxY: sortedBalances.map((b) => max(
                    (b['receivable_balance'] as num?)?.toDouble() ?? 0.0,
                    (b['payable_balance'] as num?)?.toDouble() ?? 0.0,
                  )).reduce(max) + 1000,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.white.withOpacity(0.8),
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.all(8),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          final date = DateTime.parse(
                            sortedBalances[touchedSpot.x.toInt()]['date'] as String,
                          );
                          return LineTooltipItem(
                            '${date.day}/${date.month}\n$currencySymbol${_formatNumber(touchedSpot.y)}',
                            TextStyle(
                              color: touchedSpot.bar.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: sortedBalances.asMap().entries.map((entry) {
                        int index = entry.key;
                        var balance = entry.value;
                        return FlSpot(
                          index.toDouble(),
                          (balance['receivable_balance'] as num?)?.toDouble() ?? 0.0,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.teal[400],
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: Colors.teal[400]!,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.teal[400]!.withOpacity(0.15),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.teal[400]!.withOpacity(0.15),
                            Colors.teal[400]!.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                    LineChartBarData(
                      spots: sortedBalances.asMap().entries.map((entry) {
                        int index = entry.key;
                        var balance = entry.value;
                        return FlSpot(
                          index.toDouble(),
                          (balance['payable_balance'] as num?)?.toDouble() ?? 0.0,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.orange[400],
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: Colors.orange[400]!,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.orange[400]!.withOpacity(0.15),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.orange[400]!.withOpacity(0.15),
                            Colors.orange[400]!.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorCodedBalances(
      BuildContext context, List<Map<String, dynamic>> balances, int businessId) {
    if (balances.isEmpty) return const SizedBox();
    
    final latestBalance = balances.first;
    final receivableBalance = (latestBalance['receivable_balance'] as num?)?.toDouble() ?? 0.0;
    final payableBalance = (latestBalance['payable_balance'] as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balance Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBalanceCard(
                  'Receivable',
                  -receivableBalance,  // Negate because receivables are stored as negative
                  const Color(0xFFFF7675),  // Red for money to receive
                  Icons.arrow_downward,
                  context,
                ),
              ),
              Expanded(
                child: _buildBalanceCard(
                  'Payable',
                  payableBalance,  // Keep positive as payables are stored as positive
                  const Color(0xFF00B894),  // Teal for money to pay
                  Icons.arrow_upward,
                  context,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalTransactionsSummary(BuildContext context, int selectedBusinessId) {
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd').format(now);
    final currentMonth = now.month;
    final currentYear = now.year;
    final currencySymbol = Provider.of<CurrencyProvider>(context).currencySymbol;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FutureBuilder<Map<String, double>>(
                future: DatabaseHelper.instance.getTotalTransactionsForDay(
                    selectedBusinessId, formattedDate),
                builder: (context, daySnapshot) {
                  return FutureBuilder<Map<String, double>>(
                    future: DatabaseHelper.instance
                        .getTotalTransactionsForWeek(selectedBusinessId),
                    builder: (context, weekSnapshot) {
                      return FutureBuilder<Map<String, double>>(
                        future: DatabaseHelper.instance
                            .getTotalTransactionsForMonth(
                                selectedBusinessId, currentMonth, currentYear),
                        builder: (context, monthSnapshot) {
                          if (daySnapshot.connectionState ==
                                  ConnectionState.waiting ||
                              weekSnapshot.connectionState ==
                                  ConnectionState.waiting ||
                              monthSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                            return const Center(
                                child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ));
                          } else if (daySnapshot.hasError ||
                              weekSnapshot.hasError ||
                              monthSnapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'Error loading transactions',
                                  style: TextStyle(color: Colors.grey[800]),
                                ),
                              ),
                            );
                          }

                          final dayData = daySnapshot.data ??
                              {'totalGiven': 0.0, 'totalReceived': 0.0};
                          final weekData = weekSnapshot.data ??
                              {'totalGiven': 0.0, 'totalReceived': 0.0};
                          final monthData = monthSnapshot.data ??
                              {'totalGiven': 0.0, 'totalReceived': 0.0};

                          return Column(
                            children: [
                              _buildSummaryRow('Type', 'Today', 'This Week', 'This Month',
                                  isHeader: true),
                              const Divider(height: 1),
                              _buildSummaryRow(
                                'Total Given',
                                '$currencySymbol${_formatNumber(dayData['totalGiven'] ?? 0.0)}',
                                '$currencySymbol${_formatNumber(weekData['totalGiven'] ?? 0.0)}',
                                '$currencySymbol${_formatNumber(monthData['totalGiven'] ?? 0.0)}',
                                textColor: const Color(0xFFFF7675),
                              ),
                              const Divider(height: 1),
                              _buildSummaryRow(
                                'Total Received',
                                '$currencySymbol${_formatNumber(dayData['totalReceived'] ?? 0.0)}',
                                '$currencySymbol${_formatNumber(weekData['totalReceived'] ?? 0.0)}',
                                '$currencySymbol${_formatNumber(monthData['totalReceived'] ?? 0.0)}',
                                textColor: const Color(0xFF00B894),
                              ),
                              const Divider(height: 1),
                              _buildSummaryRow(
                                'Balance',
                                '$currencySymbol${_formatNumber((dayData['totalReceived'] ?? 0.0).abs() - (dayData['totalGiven'] ?? 0.0).abs())}',
                                '$currencySymbol${_formatNumber((weekData['totalReceived'] ?? 0.0).abs() - (weekData['totalGiven'] ?? 0.0).abs())}',
                                '$currencySymbol${_formatNumber((monthData['totalReceived'] ?? 0.0).abs() - (monthData['totalGiven'] ?? 0.0).abs())}',
                                textColor: const Color(0xFF000000),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12)
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String type,
    String day,
    String week,
    String month, {
    bool isHeader = false,
    Color textColor = Colors.black87,
  }) {
    final style = TextStyle(
      fontSize: isHeader ? 14 : 15,
      fontWeight: isHeader ? FontWeight.w600 : FontWeight.w500,
      color: isHeader ? Colors.grey[600] : textColor,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      color: isHeader ? Colors.grey[50] : Colors.white,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(type, style: style),
          ),
          Expanded(
            flex: 3,
            child: Text(
              day,
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              week,
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              month,
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerOverviewSection(BuildContext context, BusinessProvider businessProvider) {
    return ValueListenableBuilder(
      valueListenable: _customerOverviewNotifier,
      builder: (context, value, child) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: DatabaseHelper.instance.getCustomerBalances(
            int.parse(businessProvider.selectedBusinessId!),
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading balances',
                  style: TextStyle(color: Colors.grey[800]),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'No balance data available',
                  style: TextStyle(color: Colors.grey[800]),
                ),
              );
            }
            
            return Column(
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Balance Overview',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildBalanceOverviewChart(snapshot.data!, context),
                        const SizedBox(height: 16),
                        _buildColorCodedBalances(
                          context,
                          snapshot.data!,
                          int.parse(businessProvider.selectedBusinessId!),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildTotalTransactionsSummary(
                      context,
                      int.parse(businessProvider.selectedBusinessId!),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSupplierOverviewSection(BuildContext context, BusinessProvider businessProvider) {
    return ValueListenableBuilder(
      valueListenable: _supplierOverviewNotifier,
      builder: (context, value, child) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: DatabaseHelper.instance.getSupplierBalances(
            int.parse(businessProvider.selectedBusinessId!),
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading supplier balances',
                  style: TextStyle(color: Colors.grey[800]),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'No supplier balance data available',
                  style: TextStyle(color: Colors.grey[800]),
                ),
              );
            }
            
            return Column(
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Balance Overview',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSupplierBalanceOverviewChart(snapshot.data!, context),
                        const SizedBox(height: 16),
                        _buildSupplierColorCodedBalances(
                          context,
                          snapshot.data!,
                          int.parse(businessProvider.selectedBusinessId!),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildSupplierTransactionsSummary(
                      context,
                      int.parse(businessProvider.selectedBusinessId!),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSupplierBalanceOverviewChart(List<Map<String, dynamic>> balances, BuildContext context) {
    // Parse String dates to DateTime, sort, and take the last 30 days
    final sortedBalances = balances.take(30).toList();
    final currencySymbol = Provider.of<CurrencyProvider>(context, listen: false).currencySymbol;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Balance Overview (Last 30 Days):',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          SizedBox(
            height: 300,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 1000,
                    verticalInterval: 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[200]!,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey[200]!,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: Text(
                        'Balance ($currencySymbol)',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatNumber(value),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text(
                        'Days',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedBalances.length) {
                            final date = DateTime.parse(sortedBalances[index]['date']);
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '${date.day}/${date.month}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                      left: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                  ),
                  minX: 0,
                  maxX: (sortedBalances.length - 1).toDouble(),
                  minY: sortedBalances
                      .map((b) => [
                            (b['receivable_balance'] as num?)?.toDouble() ?? 0.0,
                            (b['payable_balance'] as num?)?.toDouble() ?? 0.0,
                          ])
                      .expand((e) => e)
                      .reduce(min),
                  maxY: sortedBalances
                      .map((b) => [
                            (b['receivable_balance'] as num?)?.toDouble() ?? 0.0,
                            (b['payable_balance'] as num?)?.toDouble() ?? 0.0,
                          ])
                      .expand((e) => e)
                      .reduce(max),
                  lineBarsData: [
                    LineChartBarData(
                      spots: sortedBalances.asMap().entries.map((entry) {
                        int index = entry.key;
                        var balance = entry.value;
                        return FlSpot(
                          index.toDouble(),
                          (balance['receivable_balance'] as num?)?.toDouble() ?? 0.0,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.teal[400],
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: Colors.teal[400]!,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.teal[400]!.withOpacity(0.15),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.teal[400]!.withOpacity(0.15),
                            Colors.teal[400]!.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                    LineChartBarData(
                      spots: sortedBalances.asMap().entries.map((entry) {
                        int index = entry.key;
                        var balance = entry.value;
                        return FlSpot(
                          index.toDouble(),
                          (balance['payable_balance'] as num?)?.toDouble() ?? 0.0,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.orange[400],
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: Colors.orange[400]!,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.orange[400]!.withOpacity(0.15),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.orange[400]!.withOpacity(0.15),
                            Colors.orange[400]!.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierColorCodedBalances(
      BuildContext context, List<Map<String, dynamic>> balances, int businessId) {
    if (balances.isEmpty) return const SizedBox();
    
    final latestBalance = balances.first;
    final receivableBalance = (latestBalance['receivable_balance'] as num?)?.toDouble() ?? 0.0;
    final payableBalance = (latestBalance['payable_balance'] as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Supplier Balance Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBalanceCard(
                  'Receivable',
                  -receivableBalance,  // Negate because receivables are stored as negative
                  const Color(0xFFFF7675),  // Red for money to receive
                  Icons.arrow_downward,
                  context,
                ),
              ),
              Expanded(
                child: _buildBalanceCard(
                  'Payable',
                  payableBalance,  // Keep positive as payables are stored as positive
                  const Color(0xFF00B894),  // Teal for money to pay
                  Icons.arrow_upward,
                  context,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierTransactionsSummary(BuildContext context, int selectedBusinessId) {
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd').format(now);
    final currentMonth = now.month;
    final currentYear = now.year;
    final currencySymbol = Provider.of<CurrencyProvider>(context).currencySymbol;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Supplier Transaction Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FutureBuilder<Map<String, double>>(
                future: DatabaseHelper.instance.getSupplierTotalTransactionsForDay(
                    selectedBusinessId, formattedDate),
                builder: (context, daySnapshot) {
                  return FutureBuilder<Map<String, double>>(
                    future: DatabaseHelper.instance
                        .getSupplierTotalTransactionsForWeek(selectedBusinessId),
                    builder: (context, weekSnapshot) {
                      return FutureBuilder<Map<String, double>>(
                        future: DatabaseHelper.instance
                            .getSupplierTotalTransactionsForMonth(
                                selectedBusinessId, currentMonth, currentYear),
                        builder: (context, monthSnapshot) {
                          if (daySnapshot.connectionState ==
                                  ConnectionState.waiting ||
                              weekSnapshot.connectionState ==
                                  ConnectionState.waiting ||
                              monthSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                            return const Center(
                                child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ));
                          } else if (daySnapshot.hasError ||
                              weekSnapshot.hasError ||
                              monthSnapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'Error loading supplier transactions',
                                  style: TextStyle(color: Colors.grey[800]),
                                ),
                              ),
                            );
                          }

                          final dayData = daySnapshot.data ??
                              {'totalGiven': 0.0, 'totalReceived': 0.0};
                          final weekData = weekSnapshot.data ??
                              {'totalGiven': 0.0, 'totalReceived': 0.0};
                          final monthData = monthSnapshot.data ??
                              {'totalGiven': 0.0, 'totalReceived': 0.0};

                          return Column(
                            children: [
                              _buildSummaryRow('Type', 'Today', 'This Week', 'This Month',
                                  isHeader: true),
                              const Divider(height: 1),
                              _buildSummaryRow(
                                'Total Given',
                                '$currencySymbol${_formatNumber(dayData['totalGiven'] ?? 0.0)}',
                                '$currencySymbol${_formatNumber(weekData['totalGiven'] ?? 0.0)}',
                                '$currencySymbol${_formatNumber(monthData['totalGiven'] ?? 0.0)}',
                                textColor: const Color(0xFFFF7675),
                              ),
                              const Divider(height: 1),
                              _buildSummaryRow(
                                'Total Received',
                                '$currencySymbol${_formatNumber(dayData['totalReceived'] ?? 0.0)}',
                                '$currencySymbol${_formatNumber(weekData['totalReceived'] ?? 0.0)}',
                                '$currencySymbol${_formatNumber(monthData['totalReceived'] ?? 0.0)}',
                                textColor: const Color(0xFF00B894),
                              ),
                              const Divider(height: 1),
                              _buildSummaryRow(
                                'Balance',
                                '$currencySymbol${_formatNumber((dayData['totalGiven'] ?? 0.0).abs() - (dayData['totalReceived'] ?? 0.0).abs())}',
                                '$currencySymbol${_formatNumber((weekData['totalGiven'] ?? 0.0).abs() - (weekData['totalReceived'] ?? 0.0).abs())}',
                                '$currencySymbol${_formatNumber((monthData['totalGiven'] ?? 0.0).abs() - (monthData['totalReceived'] ?? 0.0).abs())}',
                                textColor: Colors.grey[800]!,
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12)
        ],
      ),
    );
  }
}

// ignore: unused_element
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
