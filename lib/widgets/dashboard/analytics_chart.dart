import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsChart extends StatefulWidget {
  const AnalyticsChart({super.key});

  @override
  State<AnalyticsChart> createState() => _AnalyticsChartState();
}

class _AnalyticsChartState extends State<AnalyticsChart> {
  String selectedPeriod = '7 Days';

  // Mock data - will be replaced with real data from provider
  List<FlSpot> get _emailsSentData {
    switch (selectedPeriod) {
      case '7 Days':
        return [
          const FlSpot(0, 120),
          const FlSpot(1, 180),
          const FlSpot(2, 150),
          const FlSpot(3, 220),
          const FlSpot(4, 190),
          const FlSpot(5, 250),
          const FlSpot(6, 280),
        ];
      case '30 Days':
        return List.generate(
          30,
          (index) => FlSpot(index.toDouble(), 100 + (index * 10).toDouble()),
        );
      case '90 Days':
        return List.generate(
          90,
          (index) => FlSpot(index.toDouble(), 150 + (index * 5).toDouble()),
        );
      default:
        return [];
    }
  }

  List<FlSpot> get _opensData {
    switch (selectedPeriod) {
      case '7 Days':
        return [
          const FlSpot(0, 50),
          const FlSpot(1, 80),
          const FlSpot(2, 65),
          const FlSpot(3, 95),
          const FlSpot(4, 85),
          const FlSpot(5, 110),
          const FlSpot(6, 125),
        ];
      case '30 Days':
        return List.generate(
          30,
          (index) => FlSpot(index.toDouble(), 40 + (index * 4).toDouble()),
        );
      case '90 Days':
        return List.generate(
          90,
          (index) => FlSpot(index.toDouble(), 60 + (index * 2).toDouble()),
        );
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Email Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButton<String>(
                  value: selectedPeriod,
                  underline: Container(),
                  items: ['7 Days', '30 Days', '90 Days']
                      .map((period) => DropdownMenuItem(
                            value: period,
                            child: Text(period),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedPeriod = value;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildLegendItem('Emails Sent', Colors.blue),
                const SizedBox(width: 24),
                _buildLegendItem('Opens', Colors.green),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 50,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: selectedPeriod == '7 Days' ? 1 : null,
                        getTitlesWidget: (value, meta) {
                          if (selectedPeriod == '7 Days') {
                            const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                            if (value.toInt() >= 0 && value.toInt() < days.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  days[value.toInt()],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              );
                            }
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 100,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                      left: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  minX: 0,
                  maxX: selectedPeriod == '7 Days' ? 6 : (selectedPeriod == '30 Days' ? 29 : 89),
                  minY: 0,
                  maxY: 300,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _emailsSentData,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                    LineChartBarData(
                      spots: _opensData,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final label = spot.barIndex == 0 ? 'Sent' : 'Opens';
                          return LineTooltipItem(
                            '$label: ${spot.y.toInt()}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

