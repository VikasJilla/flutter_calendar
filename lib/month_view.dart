import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'calendar_event.dart';
import 'calendar_utils.dart';

final double dateTxtHt = 30;
final double eventItemHt = 20;

class CalendarMonthWidget extends StatefulWidget {
  final DateTime currentMonthDate;
  final Size dayWidgetSize;

  CalendarMonthWidget({
    @required this.currentMonthDate,
    @required this.dayWidgetSize,
  });

  @override
  _CalendarMonthWidgetState createState() => _CalendarMonthWidgetState();
}

class _CalendarMonthWidgetState extends State<CalendarMonthWidget> {
  ///holds the list of events in currentweek
  List<CalendarEvent> eventsInCurrentWeek;

  /// holds the stack positions which are filled w.r.t current day events
  List<int> currentDayEventPositionsInStack = List();

  @override
  Widget build(BuildContext context) {
    int numberOfWeeksInMonth = getNumberOfWeeksInMonth(widget.currentMonthDate);
    return Container(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < numberOfWeeksInMonth; i++) getWeek(i),
        ],
      ),
    );
  }

  Widget getWeek(int weekNumber) {
    int daysBeforeStart = getPaddingBeforeStartDayOfMonth();
    int noOfDaysTillPastWeek = (weekNumber) * 7 - daysBeforeStart;
    setEventsInWeekWithStartDate(noOfDaysTillPastWeek + 1);
    return Container(
      child: createChildren(noOfDaysTillPastWeek + 1),
    );
  }

  ///creates a week view by creating each day's view in a week
  ///
  ///[dayViewWidgets] holds the day widgets which themselves hold the event widgets which happen only on paticular day
  ///
  ///[stackWidgets] holds the event widgets which range accross different dates
  ///
  ///[eventWidgetsInDay] events that happen on single day and also in some cases like the day is first day of week and an event that occurs on more days but end on this day will also be added to this

  Widget createChildren(int currentDayNumber) {
    List<Widget> dayViewWidgets = List();
    List<Widget> stackWidgets = List();
    int numberOfEventsToDisplay =
        (widget.dayWidgetSize.height - dateTxtHt) ~/ eventItemHt;
    //creating 7 days
    for (int i = 0; i < 7; i++, currentDayNumber++) {
      List<Widget> eventWidgetsInDay = List();
      if (currentDayNumber <= 0 || currentDayNumber > getNumberOfDays()) {
        //adding empty views for invalid positions in calendar
        dayViewWidgets.add(getEmptyDay());
      } else {
        //get list of events on this date sorted according to their start date and add them to stack or to a dayview
        DateTime currentDay = DateTime(widget.currentMonthDate.year,
            widget.currentMonthDate.month, currentDayNumber);
        List<CalendarEvent> sorted = sortedAccordingToTheDuration(currentDay);
        for (CalendarEvent event in sorted) {
          DateTime startDate = DateTime(
              event.startTime.year, event.startTime.month, event.startTime.day);
          DateTime endDate = DateTime(
              event.endTime.year, event.endTime.month, event.endTime.day);
          if (numberOfEventsToDisplay != 0 &&
              (currentDayEventPositionsInStack.length >=
                      numberOfEventsToDisplay ||
                  eventWidgetsInDay.length >= numberOfEventsToDisplay)) {
            break;
          }
          if (event.positionInStack >= 0) {
            eventWidgetsInDay.add(getEventPlaceHolder());
            continue;
          } else if ((startDate.difference(currentDay).inDays.abs() > 0 ||
                  endDate.difference(currentDay).inDays.abs() > 0) &&
              currentDay.compareTo(DateTime(
                      currentDay.year, currentDay.month, getNumberOfDays())) !=
                  0) {
            checkAndAddEventToStack(numberOfEventsToDisplay, event, currentDay,
                currentDayNumber, i, stackWidgets, eventWidgetsInDay);
          } else {
            if (eventWidgetsInDay.length >= numberOfEventsToDisplay)
              continue;
            else
              eventWidgetsInDay.add(getEventItem(
                  eventPosition: eventWidgetsInDay.length,
                  title: event.title,
                  eventDurationMoreThanOneDay:
                      endDate.difference(startDate).inDays > 1));
          }
        }
        //added a day with event widgets
        dayViewWidgets.add(getDayWidget(currentDay, eventWidgetsInDay));
      }
    }
    return Stack(
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: dayViewWidgets,
        ),
        ...stackWidgets
      ],
    );
  }

  /// adds an ranged event to stack by checking the positions that are empty
  void checkAndAddEventToStack(
      int numberOfEventsToDisplay,
      CalendarEvent event,
      DateTime currentDay,
      int currentDayNumber,
      int i,
      List<Widget> stackWidgets,
      List<Widget> eventWidgetsInDay) {
    for (int position = 0; position < numberOfEventsToDisplay; position++) {
      if (currentDayEventPositionsInStack.contains(position)) {
        continue;
      }
      currentDayEventPositionsInStack.add(position);
      event.positionInStack = position;
      int eventDuration = event.endTime.difference(currentDay).inDays + 1;
      int noOfDaysLeftInWeek =
          (getNumberOfDays() - currentDayNumber) + 1 >= (7 - i)
              ? 7 - i
              : (getNumberOfDays() - currentDayNumber) + 1;
      double width = (eventDuration <= noOfDaysLeftInWeek
              ? eventDuration
              : noOfDaysLeftInWeek) *
          widget.dayWidgetSize.width;
      stackWidgets.add(Positioned(
          left: i * widget.dayWidgetSize.width,
          top: (position * eventItemHt + dateTxtHt),
          width: width,
          child: IgnorePointer(
              child: getEventItem(
                  eventPosition: event.positionInStack,
                  title: event.title,
                  eventDurationMoreThanOneDay: true,
                  width: width))));
      eventWidgetsInDay.add(getEventPlaceHolder());
      break; //break after the event is added
      //
    }
  }

  /// returns an empty view - the invalid days at the start and end of the month view with no date in them
  Widget getEmptyDay() {
    return Container(
      decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          border: Border.all(color: Colors.grey[300], width: 0.35),
          color: Colors.white),
      width: widget.dayWidgetSize.width,
      height: widget.dayWidgetSize.height,
      padding: EdgeInsets.only(top: 5),
    );
  }

  /// creates place holders which acts as dummy events -- to avoid overlapping a day events with events that
  /// range between 2 to any no.of days
  Widget getEventPlaceHolder() {
    return SizedBox(
      width: widget.dayWidgetSize.width,
      height: eventItemHt,
    );
  }

  /// return a single event widget that might be added to a day view or else
  /// to stack to display as a continuous UI event through days
  Widget getEventItem(
      {@required int eventPosition,
      @required String title,
      @required bool eventDurationMoreThanOneDay,
      double width}) {
    return EventItem(
      eventItemHt,
      width ?? widget.dayWidgetSize.width,
      eventPosition,
      title,
      eventDurationMoreThanOneDay: eventDurationMoreThanOneDay,
    );
  }

  /// returns a [day] view(contains date and events on particular date) in a week by adding the [eventWidgets]
  Widget getDayWidget(DateTime day, List<Widget> eventWidgets) {
    return InkWell(
        onTap: () {
          // EventsListAlert.showEventsAlert(context,DateTime(day.year,day.month,day.day));
        },
        child: Container(
            decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                border: Border.all(color: Colors.grey[300], width: 0.35),
                color: Colors.white),
            width: widget.dayWidgetSize.width,
            height: widget.dayWidgetSize.height,
            padding: EdgeInsets.only(top: 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[getDateWidget(day.day), ...eventWidgets],
            )));
  }

  /// creates and returns a text view with [date] as the text in it.
  ///
  /// if date is today then it returns a circular widget with [date] as text and background color as #FF1E90FF
  Widget getDateWidget(int date) {
    DateTime now = DateTime.now();
    bool isToday = (now.day == date &&
        now.month == widget.currentMonthDate.month &&
        now.year == widget.currentMonthDate.year);
    return getCircularWidget(
        padding: EdgeInsets.all(0),
        child: Text('$date',
            style: Theme.of(context).textTheme.display1.copyWith(
                color: isToday ? Colors.white : Colors.black, fontSize: 13)),
        fillColor: isToday ? Color(0xFF1E90FF) : Colors.transparent);
  }

  List<CalendarEvent> sortedAccordingToTheDuration(DateTime date) {
    List<CalendarEvent> events = List();
    currentDayEventPositionsInStack =
        List(); //resetting current day positions in stack
    for (CalendarEvent event in eventsInCurrentWeek) {
      DateTime startDate = DateTime(
          event.startTime.year, event.startTime.month, event.startTime.day);
      DateTime endDate =
          DateTime(event.endTime.year, event.endTime.month, event.endTime.day);
      if (date.compareTo(startDate) >= 0 && date.compareTo(endDate) <= 0) {
        if (events.contains(event)) continue;
        events.add(event);
        if (event.positionInStack >= 0) {
          currentDayEventPositionsInStack.add(event.positionInStack);
        }
      }
    }
    events.sort(comparator);
    return events;
  }

  int comparator(CalendarEvent event1, CalendarEvent event2) {
    int compareOutput = event1.startTime.compareTo(event2.startTime);
    if (compareOutput < 0)
      return -1; //makes event1 come before event2 in the result list
    else if (compareOutput > 0)
      return 1; //makes event2 come before event1 in the result list
    else {
      return event1.startTime
          .difference(event1.endTime)
          .inMilliseconds
          .abs()
          .compareTo(
              event2.startTime.difference(event2.endTime).inMilliseconds.abs());
    }
  }

  void setEventsInWeekWithStartDate(int date) {
    int totDays = getNumberOfDays();
    eventsInCurrentWeek = List();
    for (int i = 0; i < 7; i++, date++) {
      if (date <= 0 || date > totDays) continue;
      eventsInCurrentWeek.addAll(getEventsOn(DateTime(
          widget.currentMonthDate.year, widget.currentMonthDate.month, date)));
    }
  }

  List<CalendarEvent> getEventsOn(DateTime date) {
    List<int> eventPositions = CalendarEvent.getList(date.month, date.year);
    List<CalendarEvent> eventsOnDate = List();
    for (int pos in eventPositions) {
      CalendarEvent event = CalendarEvent.eventsList[pos];
      DateTime startDate = DateTime(
          event.startTime.year, event.startTime.month, event.startTime.day);
      DateTime endDate =
          DateTime(event.endTime.year, event.endTime.month, event.endTime.day);
      if (date.compareTo(startDate) >= 0 && date.compareTo(endDate) <= 0) {
        event.positionInStack = -1;
        eventsOnDate.add(event);
      }
    }
    return eventsOnDate;
  }

  int getPaddingBeforeStartDayOfMonth() {
    DateTime dateTime = DateTime(
        widget.currentMonthDate.year, widget.currentMonthDate.month, 1);
    return dateTime.weekday == 7 ? 0 : dateTime.weekday;
  }

  int getNumberOfDays() {
    return getNumberOfDaysInMonth(widget.currentMonthDate);
  }
}

class EventItem extends StatelessWidget {
  final int verticalPadding = 4;
  final int horizontalPadding = 5;
  final double height;
  final double width;
  final int position;
  final String title;
  final bool eventDurationMoreThanOneDay;
  EventItem(
    this.height,
    this.width,
    this.position,
    this.title, {
    this.eventDurationMoreThanOneDay = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 2),
        padding: EdgeInsets.symmetric(vertical: verticalPadding / 2),
        child: Container(
          width: width.toDouble() - horizontalPadding,
          height: (height - verticalPadding).toDouble(),
          padding:
              EdgeInsets.symmetric(horizontal: horizontalPadding.toDouble()),
          decoration: BoxDecoration(
              borderRadius: eventDurationMoreThanOneDay
                  ? BorderRadius.all(Radius.circular(0))
                  : BorderRadius.horizontal(
                      left: Radius.circular((height - verticalPadding) / 2),
                      right: Radius.circular((height - verticalPadding) / 2)),
              color: getColorBasedOnPosition()),
          child: eventDurationMoreThanOneDay
              ? getTitleWidget()
              : Center(child: getTitleWidget()),
        ));
  }

  Widget getTitleWidget() {
    return AutoSizeText(
      title,
      maxFontSize: 12,
      minFontSize: 10,
      style: TextStyle(
        fontFamily: "AvenirLTStd",
        color: Colors.black87,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Color getColorBasedOnPosition() {
    //use extension in here
    return Color(0xFF1A609F).withAlpha(150);
  }
}
