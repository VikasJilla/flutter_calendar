library flutter_calendar;

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

import 'calendar_utils.dart';
import 'month_view.dart';

class CustomCalendar extends StatefulWidget {
  final List<String> weekDays;
  final Size calendarSize;
  CustomCalendar({this.weekDays, this.calendarSize});
  @override
  _CustomCalendarState createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar>
    with SingleTickerProviderStateMixin {
  final int numWeekDays = 7;
  Size size;
  double itemHeight;
  double itemWidth;
  DateTime _currentDate = DateTime.now();
  PageController _controller;
  int prevIndex = 3;
  StreamController<int> _dateStreamController = StreamController();

  @override
  void initState() {
    _controller = PageController(
      initialPage: prevIndex,
      keepPage: false,
      viewportFraction: 1.0,
    );
    super.initState();
  }

  @override
  void dispose() {
    _dateStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    initDimensions();
    return Container(
        color: Colors.white, child: buildCalendarWithEvents(context));
  }

  Column buildCalendarWithEvents(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        getWeekDaysView(),
        Expanded(child: monthBuilder()),
      ],
    );
  }

/////////////////////////////////////////
  ///--------UI methods----------//////
/////////////////////////////////////////

  /// creates widget with list of days from Sunday to Saturday in a row.
  Widget getWeekDaysView() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      color: Color(0xFF1A609F),
      child: Row(
        children: <Widget>[
          for (String day in getWeekDays())
            SizedBox(
                width: itemWidth,
                child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      day,
                      style: Theme.of(context)
                          .textTheme
                          .display1
                          .copyWith(color: Colors.black),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    )))
        ],
      ),
    );
  }

  Widget monthBuilder() {
    return PageView.builder(
        controller: _controller,
        onPageChanged: (index) {
          setCurrentDate(index);
        },
        itemBuilder: (context, index) {
          setCurrentDate(index);
          initDimensions();
          return CalendarMonthWidget(
            dayWidgetSize: Size(itemWidth, itemHeight),
            currentMonthDate: _currentDate,
          );
        });
  }

  void setCurrentDate(int index) {
    int month = _currentDate.month;
    if (index > prevIndex) {
      month += index - prevIndex;
    } else if (index < prevIndex) {
      month -= prevIndex - index;
    }
    prevIndex = index;
    _currentDate = DateTime(_currentDate.year, month, 1);
    _dateStreamController.add(0); //just to notify builder
  }

/////////////////////////////////////////
  ///--------helper methods----------//////
/////////////////////////////////////////

  List<String> getWeekDays() {
    return widget.weekDays ??
        ['Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat'];
  }

  void initDimensions() {
    if (widget.calendarSize == null) {
      size = MediaQuery.of(context).size;
      itemHeight =
          (size.height - kBottomNavigationBarHeight - kToolbarHeight - 80) /
              getNumberOfWeeksInMonth(_currentDate);
      itemWidth = size.width / numWeekDays;
    } else {
      size = widget.calendarSize;
      itemHeight =
          widget.calendarSize.width / getNumberOfWeeksInMonth(_currentDate);
      itemWidth = size.width / numWeekDays;
    }
  }
}
