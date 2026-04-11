import 'package:flutter/material.dart';
import 'package:rafiq/theme/app_colors.dart';
import 'package:rafiq/pages/my_trip_page.dart';
import 'package:rafiq/services/trip_service.dart';
import 'package:rafiq/services/auth_service.dart';
import 'package:intl/intl.dart';

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
  String? _preferenceId;

  final List<String> _destinations = ['Jeddah', 'Riyadh', 'AlUla'];

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    if (!AuthService.isLoggedIn) {
      Future.delayed(Duration.zero, () {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
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
            width: MediaQuery.of(context).size.width * 0.6,
            height: 8.5,
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
                        color: AppColors.black.withOpacity(0.05),
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
                      Column(
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
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _destination,
                                isExpanded: true,
                                icon: Icon(Icons.arrow_drop_down, color: AppColors.secondary),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _destination = newValue!;
                                  });
                                },
                                items: _destinations.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Row(
                                      children: [
                                        Icon(Icons.location_on, color: AppColors.accent, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          value,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                     
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'From - To',
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
                                child: GestureDetector(
                                  onTap: () => _selectDate(isFromDate: true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
                                            _selectedFromDate != null ? _formatDate(_selectedFromDate!) : 'From',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: _selectedFromDate != null ? AppColors.textPrimary : AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectDate(isFromDate: false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
                                            _selectedToDate != null ? _formatDate(_selectedToDate!) : 'To',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: _selectedToDate != null ? AppColors.textPrimary : AppColors.textSecondary,
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
                        ],
                      ),
                      const SizedBox(height: 18),
                      
                      Row(
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
                      ),
                      const SizedBox(height: 12),
                      
                      _buildCalendar(),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                
                Center(
                  child: SizedBox(
                    width: 180,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _selectedFromDate != null && _selectedToDate != null
                          ? () async {
                              _showLoadingDialog();
                              try {
                                final result = await TripService.saveTripRequest(
                                  destination: _destination,
                                  fromDate: _selectedFromDate!,
                                  toDate: _selectedToDate!,
                                );
                                if (mounted) {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MyTripPage(
                                        preferenceId: result['preference_id'],
                                        destination: _destination,
                                        fromDate: _selectedFromDate!,
                                        toDate: _selectedToDate!,
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  Navigator.pop(context);
                                  _showErrorDialog(e.toString());
                                }
                              }
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startingWeekday = firstDay.weekday;

    final today = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
                  .map((day) => Expanded(
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                            fontSize: 12,
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
              childAspectRatio: 1.2,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final dayOffset = index - (startingWeekday == 7 ? 0 : startingWeekday) + 1;
              final isCurrentMonth = dayOffset > 0 && dayOffset <= daysInMonth;
              final day = isCurrentMonth ? dayOffset : null;

              bool isSelectable = false;
              if (isCurrentMonth) {
                if (_currentMonth.year > today.year ||
                    (_currentMonth.year == today.year && _currentMonth.month > today.month) ||
                    (_currentMonth.year == today.year &&
                        _currentMonth.month == today.month &&
                        day! >= today.day)) {
                  isSelectable = true;
                }
              }

              final isSelected = isCurrentMonth &&
                  _selectedFromDate != null &&
                  day == _selectedFromDate!.day &&
                  _currentMonth.month == _selectedFromDate!.month &&
                  _currentMonth.year == _selectedFromDate!.year;

              final isInRange = isCurrentMonth &&
                  _selectedFromDate != null &&
                  _selectedToDate != null &&
                  day! >= _selectedFromDate!.day &&
                  day <= _selectedToDate!.day &&
                  _currentMonth.month == _selectedFromDate!.month &&
                  _currentMonth.year == _selectedFromDate!.year;

              return GestureDetector(
                onTap: isSelectable ? () => _onDaySelected(day!) : null,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent
                        : isInRange
                            ? AppColors.accent.withOpacity(0.1)
                            : AppColors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      day != null ? '$day' : '',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelectable
                            ? (isSelected
                                ? AppColors.white
                                : isInRange
                                    ? AppColors.accent
                                    : AppColors.textPrimary)
                            : AppColors.greyDark,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
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
    final selectedDate = DateTime(_currentMonth.year, _currentMonth.month, day);
    final today = DateTime.now();

    if (selectedDate.isBefore(DateTime(today.year, today.month, today.day))) return;

    setState(() {
      if (_selectedFromDate == null) {
        _selectedFromDate = selectedDate;
        _selectedToDate = null;
      } else if (_selectedToDate == null) {
        if (selectedDate.isBefore(_selectedFromDate!)) {
          _selectedToDate = _selectedFromDate;
          _selectedFromDate = selectedDate;
        } else {
          _selectedToDate = selectedDate;
        }
      } else {
        _selectedFromDate = selectedDate;
        _selectedToDate = null;
      }
    });
  }

  Future<void> _selectDate({required bool isFromDate}) async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? (_selectedFromDate ?? today)
          : (_selectedToDate ?? (_selectedFromDate ?? today)),
      firstDate: today,
      lastDate: DateTime(2026),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primary,
            colorScheme: const ColorScheme.light(
              primary: AppColors.textPrimary,
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
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

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}