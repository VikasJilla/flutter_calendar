import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'calendar_event.dart';
import 'calendar_utils.dart';

final double dateTxtHt = 30;
final double eventItemHt = 20;

class CalendarMonthWidget extends StatefulWidget {
  final DateTime currentMonthDate;
  final Size dayWidgetSize;

  CalendarMonthWidget(
    {
      @required this.currentMonthDate,
      @required this.dayWidgetSize,
    }
  );

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
            for(int i = 0;i < numberOfWeeksInMonth; i++)getWeek(i),          
          ],
      ),
    );
  }

  Widget getWeek(int weekNumber){
    int daysBeforeStart = getPaddingBeforeStartDayOfMonth();
    int noOfDaysTillPastWeek = (weekNumber)*7 - daysBeforeStart;
    setEventsInWeekWithStartDate(noOfDaysTillPastWeek+1);
    return Container(
      child:createChildren(noOfDaysTillPastWeek+1),
    );
  }

  ///creates a week view by creating each day's view in a week
  ///
  ///[dayViewWidgets] holds the day widgets which themselves hold the event widgets which happen only on paticular day
  ///
  ///[stackWidgets] holds the event widgets which range accross different dates
  ///
  ///[eventWidgetsInDay] events that happen on single day and also in some cases like the day is first day of week and an event that occurs on more days but end on this day will also be added to this
  
  
  Widget createChildren(int currentDayNumber){
    final List<Widget> dayViewWidgets = [];
    final List<Widget> stackWidgets = [];    
    //creating 7 days
    for(int i = 0;i < 7;i++,currentDayNumber++){      
      final List<Widget> eventWidgetsInDay = [];
      if(currentDayNumber <= 0 || currentDayNumber > getNumberOfDays()){//adding empty views for invalid positions in calendar
        dayViewWidgets.add(getEmptyDay());
      }
      else{
        //get list of events on this date sorted according to their start date and add them to stack or to a dayview          
        final int numberOfEventsToDisplay = (widget.dayWidgetSize.height-dateTxtHt)~/eventItemHt;
        final DateTime currentDay = DateTime(widget.currentMonthDate.year,widget.currentMonthDate.month,currentDayNumber);
        final List<CalendarEvent> sorted = sortedAccordingToTheDuration(currentDay);
        if(numberOfEventsToDisplay != 0){
          for(CalendarEvent event in sorted){      
            final DateTime startDate = DateTime(event.startTime.year,event.startTime.month,event.startTime.day);
            final DateTime endDate = DateTime(event.endTime.year,event.endTime.month,event.endTime.day);
            if(eventWidgetsInDay.length == numberOfEventsToDisplay && eventWidgetsInDay.length >= currentDayEventPositionsInStack.length){
              break;
            }
            if(event.positionInStack >= 0){
              eventWidgetsInDay.add(getEventPlaceHolder());
              continue;
            }
            else if((startDate.difference(currentDay).inDays.abs() > 0 || endDate.difference(currentDay).inDays.abs() > 0) && currentDay.compareTo(DateTime(currentDay.year,currentDay.month,getNumberOfDays())) != 0){
              checkAndAddEventToStack(numberOfEventsToDisplay, event, currentDay, currentDayNumber, i, stackWidgets, eventWidgetsInDay);
            }
            else{
              if(eventWidgetsInDay.length >= numberOfEventsToDisplay)continue;
              else {
                for(int position = 0;position < numberOfEventsToDisplay;position++){
                  if(currentDayEventPositionsInStack.contains(position) || (position < eventWidgetsInDay.length && eventWidgetsInDay.elementAt(position) is EventItem)){
                    //ignoring position if the position is already occupied in stack or if the position already has valid event item widget
                    continue;
                  }
                  eventWidgetsInDay.insert(position,getEventItem(event: event,));
                  break;
                } 
              }
            }
          }
        }
        //added a day with event widgets
        dayViewWidgets.add(getDayWidget(currentDay,eventWidgetsInDay));
        if(sorted.length-numberOfEventsToDisplay > 0){
          const size = 25.0;
          stackWidgets.add(
            Positioned(
              left: i*widget.dayWidgetSize.width,
              top:0,
              width: size,
              child: XmoreWidget(sorted.length-numberOfEventsToDisplay,size: size,),
            )
          );
        }
      }
    }
    return Stack(
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children:dayViewWidgets,
        ),
        ...stackWidgets          
      ],      
    );
  }


/// adds an ranged event to stack by checking the positions that are empty
 void checkAndAddEventToStack(int numberOfEventsToDisplay, CalendarEvent event, DateTime currentDay, int currentDayNumber, int i, List<Widget> stackWidgets, List<Widget> eventWidgetsInDay) {
    for(int position = 0;position < numberOfEventsToDisplay;position++){
      if(currentDayEventPositionsInStack.contains(position)  || (position < eventWidgetsInDay.length && eventWidgetsInDay.elementAt(position) is EventItem)){
        continue;
      }
      currentDayEventPositionsInStack.add(position);
      event.positionInStack = position;
      final int eventDuration = event.endTime.difference(currentDay).inDays+1;
      final int noOfDaysLeftInWeek = (getNumberOfDays() - currentDayNumber)+1 >= (7-i) ? 7 - i:(getNumberOfDays()-currentDayNumber)+1;
      final double width = (eventDuration <= noOfDaysLeftInWeek?eventDuration:noOfDaysLeftInWeek) * widget.dayWidgetSize.width;
      stackWidgets.add(Positioned(
        left: i*widget.dayWidgetSize.width,
        top: position*eventItemHt+dateTxtHt,
        width: width,
        child: IgnorePointer(child: 
        getEventItem(event: event,width: width))
      ));
      eventWidgetsInDay.add(getEventPlaceHolder());                  
      break;//break after the event is added
      // 
    }
  }


  /// returns an empty view - the invalid days at the start and end of the month view with no date in them
  Widget getEmptyDay(){
    return Container(
      decoration: BoxDecoration(shape: BoxShape.rectangle,border: Border.all(color: Colors.grey[300],width: 0.35),color: Colors.white),
      width: widget.dayWidgetSize.width,
      height: widget.dayWidgetSize.height,
      padding: EdgeInsets.only(top: 5),
    );
  }
  
  /// creates place holders which acts as dummy events -- to avoid overlapping a day events with events that 
  /// range between 2 to any no.of days
  Widget getEventPlaceHolder(){
    return SizedBox(width: widget.dayWidgetSize.width,height:eventItemHt,);
  }

  /// return a single event widget that might be added to a day view or else 
/// to stack to display as a continuous UI event through days
  Widget getEventItem({@required CalendarEvent event,double width}){
     return EventItem(
      eventItemHt, 
      width??widget.dayWidgetSize.width,
      event,
    );
  }


/// returns a [day] view(contains date and events on particular date) in a week by adding the [eventWidgets]
  Widget getDayWidget(DateTime day,List<Widget> eventWidgets){
   return InkWell(
      onTap: (){
        // EventsListAlert.showEventsAlert(context,DateTime(day.year,day.month,day.day));
      },
      child: Container(
        decoration: BoxDecoration(shape: BoxShape.rectangle,border: Border.all(color: Colors.grey[300],width: 0.35),color: Colors.white),
        width: widget.dayWidgetSize.width,
        height: widget.dayWidgetSize.height,
        padding: EdgeInsets.only(top: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            getDateWidget(day.day),
            ...eventWidgets
          ],
        )
      )
    );
  }
  
/// creates and returns a text view with [date] as the text in it.
/// 
/// if date is today then it returns a circular widget with [date] as text and background color as #FF1E90FF
  Widget getDateWidget(int date){
    DateTime now = DateTime.now();
    bool isToday = (now.day == date && now.month == widget.currentMonthDate.month && now.year == widget.currentMonthDate.year);
    return getCircularWidget(       
      padding: EdgeInsets.all(0),
      child: Text(
        '$date',
        style: Theme.of(context).textTheme.display1.copyWith(color: isToday?Colors.white:Colors.black,fontSize: 13)
      ),
      fillColor: isToday?Color(0xFF1E90FF):Colors.transparent
    );
  }

  List<CalendarEvent> sortedAccordingToTheDuration(DateTime date){
    List<CalendarEvent> events = List();
    currentDayEventPositionsInStack = List();//resetting current day positions in stack
    for(CalendarEvent event in eventsInCurrentWeek){
      DateTime startDate = DateTime(event.startTime.year,event.startTime.month,event.startTime.day);
      DateTime endDate = DateTime(event.endTime.year,event.endTime.month,event.endTime.day);
      if(date.compareTo(startDate) >= 0 && date.compareTo(endDate) <= 0){
        if(events.contains(event))continue;
        events.add(event);
        if(event.positionInStack >= 0){
          currentDayEventPositionsInStack.add(event.positionInStack);
        }
      }
    }
    events.sort(comparator);
    return events;
  }

  int comparator(CalendarEvent event1,CalendarEvent event2){        
    int compareOutput = event1.startTime.compareTo(event2.startTime);
    if(compareOutput < 0)return -1;//makes event1 come before event2 in the result list
    else if(compareOutput > 0)return 1;//makes event2 come before event1 in the result list
    else{
      return event1.startTime.difference(event1.endTime).inMilliseconds.abs().compareTo(event2.startTime.difference(event2.endTime).inMilliseconds.abs());
    }
  }

  void setEventsInWeekWithStartDate(int date){
    int totDays = getNumberOfDays();
    eventsInCurrentWeek = List();
    for(int i=0;i<7;i++,date++){
      if(date <= 0 || date > totDays)continue;
      eventsInCurrentWeek.addAll(getEventsOn(DateTime(widget.currentMonthDate.year,widget.currentMonthDate.month,date)));
    }
  }

  List<CalendarEvent> getEventsOn(DateTime date){    
    List<int> eventPositions = CalendarEvent.getList(date.month,date.year);
    List<CalendarEvent> eventsOnDate = List();
    for(int pos in eventPositions){
      CalendarEvent event = CalendarEvent.eventsList[pos];
      DateTime startDate = DateTime(event.startTime.year,event.startTime.month,event.startTime.day);
      DateTime endDate = DateTime(event.endTime.year,event.endTime.month,event.endTime.day);
      if(date.compareTo(startDate) >= 0 && date.compareTo(endDate) <= 0){
        event.positionInStack = -1;
        eventsOnDate.add(event);
      }      
    }
    return eventsOnDate;
  }

  int getPaddingBeforeStartDayOfMonth(){
    DateTime dateTime = DateTime(widget.currentMonthDate.year,widget.currentMonthDate.month,1);
    return dateTime.weekday == 7 ? 0 : dateTime.weekday;
  }

  int getNumberOfDays() {
    return getNumberOfDaysInMonth(widget.currentMonthDate);
  }
}
class EventItem extends StatelessWidget {
  const EventItem(this.height,this.width,this.event,{this.horizontalPadding = 4,this.verticalPadding = 4});
  
  final int verticalPadding;
  final int horizontalPadding;

  final double height;
  final double width;
  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: EdgeInsets.symmetric(vertical: verticalPadding/2),
      child: Container(
        width: width.toDouble()-horizontalPadding,
        height: (height-verticalPadding).toDouble(),
        color: event.getEventColor(),
        child:Center(child: getTitleWidget(context)),
      )
    );
  }

  Widget getTitleWidget(BuildContext context){
    return Text
    (
      event.title,
      style: Theme.of(context).textTheme.body1.copyWith(fontSize: 14),
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      maxLines: 1,
    );
  }
}



class XmoreWidget extends StatelessWidget {

  const XmoreWidget(this.xmoreVal,{this.size = 25});

  final int xmoreVal;

  final double size;
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: xmoreVal>9?0:0.5),
              child: Align(
                alignment: Alignment.topLeft,
                child: AutoSizeText(
                  '+$xmoreVal',
                  style: Theme.of(context).textTheme.display1.copyWith(color: Colors.white,fontSize: 11),
                  maxFontSize: 12,
                  minFontSize: 8,
                  maxLines: 2,
                )
              ),
            )
          ],
        ),
      ),
      painter:TrianglePainter() ,
    );
  }

}


class TrianglePainter extends CustomPainter {

  @override
  void paint(Canvas canvas, Size size) {
    
    final Paint paintBrush = Paint();
    paintBrush.color = Color(0xFFffc422).withAlpha(150);

    //reversed triangle
    final reversePath = Path();
    reversePath.lineTo(0, 0);
    reversePath.lineTo(size.width, 0);
    reversePath.lineTo(0, size.width);
    reversePath.lineTo(0, 0);
    reversePath.close();

    canvas.drawPath(reversePath,paintBrush);

  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
    
}
