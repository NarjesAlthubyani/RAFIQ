import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'create_trip_page.dart';

class DestinationDatePage extends StatefulWidget {
  const DestinationDatePage({Key? key}) : super(key: key);

  @override
  _DestinationDatePageState createState() => _DestinationDatePageState();
}

class _DestinationDatePageState extends State<DestinationDatePage> {
  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;
  DateTime _currentMonth = DateTime.now();
  String _destination = 'Jeddah';

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.secondary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepIndicator(),
                const SizedBox(height: 8),
                _buildHeader(),
                const SizedBox(height: 24),
                
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: AppColors.greyLight),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDestinationField(),
                      const SizedBox(height: 18),
                      _buildDateRangeSelector(),
                      const SizedBox(height: 18),
                      _buildMonthHeader(),
                      const SizedBox(height: 12),
                      _buildCalendar(),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _buildNavigationButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Column(
      children: [
        Row(
          children: [
            const Spacer(),
            Text(
              'Step 1/2',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'When do you plan to go?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Destination',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.greyLight),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.location_on, color: AppColors.textSecondary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _destination,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'From    To',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDateButton(
                label: 'From',
                date: _selectedFromDate,
                onPressed: () => _selectDate(isFromDate: true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateButton(
                label: 'To',
                date: _selectedToDate,
                onPressed: () => _selectDate(isFromDate: false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accent),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null ? _formatDate(date) : label, 
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: date != null ? AppColors.textPrimary : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formatMonthYear(_currentMonth), 
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: () => _changeMonth(-1),
              icon: Icon(Icons.chevron_left, size: 32, color: AppColors.primary),
            ),
            IconButton(
              onPressed: () => _changeMonth(1),
              icon: Icon(Icons.chevron_right, size: 32, color: AppColors.primary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startingWeekday = firstDay.weekday;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.accent,
              border: Border(bottom: BorderSide(color: AppColors.greyLight)),
            ),
            child: Row(
              children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
                  .map((day) => Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            day,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final dayOffset = index - startingWeekday + 1;
              final isCurrentMonth = dayOffset > 0 && dayOffset <= daysInMonth;
              final day = isCurrentMonth ? dayOffset : null;
              final isToday = isCurrentMonth &&
                  day == DateTime.now().day &&
                  _currentMonth.month == DateTime.now().month &&
                  _currentMonth.year == DateTime.now().year;
              final isSelected = isCurrentMonth &&
                  _selectedFromDate != null &&
                  day == _selectedFromDate!.day &&
                  _currentMonth.month == _selectedFromDate!.month &&
                  _currentMonth.year == _selectedFromDate!.year;

              return GestureDetector(
                onTap: isCurrentMonth ? () => _onDaySelected(day!) : null,
                child: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent.withOpacity(0.15) : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: day != null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                  color: isToday
                                      ? AppColors.primary
                                      : isSelected
                                          ? AppColors.secondary
                                          : AppColors.textPrimary,
                                ),
                              ),
                              if (isToday)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          )
                        : const SizedBox(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Center(
      child: SizedBox(
        width: 180,
        height: 52,
        child: ElevatedButton(
          onPressed: _selectedFromDate != null && _selectedToDate != null
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyTripPage(),
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedFromDate != null && _selectedToDate != null
                ? AppColors.secondary
                : AppColors.greyLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            'Next',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _selectedFromDate != null && _selectedToDate != null
                  ? AppColors.white
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + offset,
        1,
      );
    });
  }

  void _onDaySelected(int day) {
    setState(() {
      final selectedDate = DateTime(
        _currentMonth.year,
        _currentMonth.month,
        day,
      );

      if (_selectedFromDate == null || _selectedToDate != null) {
        _selectedFromDate = selectedDate;
        _selectedToDate = null;
      } else if (selectedDate.isBefore(_selectedFromDate!)) {
        _selectedToDate = _selectedFromDate;
        _selectedFromDate = selectedDate;
      } else {
        _selectedToDate = selectedDate;
      }
    });
  }

  Future<void> _selectDate({required bool isFromDate}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2027),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primary,
            colorScheme: ColorScheme.light(primary: AppColors.primary),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (selected != null) {
      setState(() {
        if (isFromDate) {
          _selectedFromDate = selected;
          if (_selectedToDate != null && _selectedToDate!.isBefore(selected)) {
            _selectedToDate = null;
          }
        } else {
          _selectedToDate = selected;
        }
      });
    }
  }
}