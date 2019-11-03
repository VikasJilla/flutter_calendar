import 'package:calendar_flutter/calendar_event.dart';
import 'package:calendar_flutter/flutter_calendar.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  

  @override
  Widget build(BuildContext context) {
    //setCalendarEvents();// uncomment this to see the events on the calendar
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar'),
      ),
      body:CustomCalendar()
    );
  }

  void setCalendarEvents(){
    List<CalendarEvent> eventsList = List<CalendarEvent>();

    CalendarEvent event = CalendarEvent();
    event.title = "Meeting";
    event.startTime = DateTime(2019,07,01);
    event.endTime = DateTime(2019,07,10);
    eventsList.add(event);

    event = CalendarEvent();
    event.title = "Meeting2";
    event.startTime = DateTime(2019,07,06);
    event.endTime = DateTime(2019,07,15);
    eventsList.add(event);
    CalendarEvent.setListAndUpdateMap(eventsList);
  }
}
