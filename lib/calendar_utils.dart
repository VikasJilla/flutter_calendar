import 'package:flutter/material.dart';

int getNumberOfWeeksInMonth(DateTime date){
    DateTime dateTime = DateTime(date.year,date.month,1);
    int noOfDays = getNumberOfDaysInMonth(date);    
    int noOfDaysInStartWeek = 7 - dateTime.weekday;
    int numberOfWeeks = (noOfDays-noOfDaysInStartWeek)~/7; // ~/ --> truncateing integer divison opertor
    numberOfWeeks += (noOfDays-noOfDaysInStartWeek) % 7 != 0?1:0;
    if(noOfDaysInStartWeek > 0)numberOfWeeks++;//add a week for the noOfDaysInStartWeek
    // Logger.log("$numberOfWeeks -- number of weeks");
    return numberOfWeeks;
  }

  int getNumberOfDaysInMonth(DateTime date) {
    DateTime dateTime = DateTime(date.year,date.month,1);
    DateTime nextMonth = DateTime(date.year,date.month+1,1);
    Duration duration = nextMonth.difference(dateTime);
    // Logger.log("${duration.inDays} -- number of days \n ${dateTime.weekday} -- weekday");
    return duration.inDays;
  }

Widget getCircularWidget({Widget child,Color fillColor:Colors.white,double size:24,EdgeInsetsGeometry margin:const EdgeInsets.only(left: 0,right: 0),
  EdgeInsetsGeometry padding:const EdgeInsets.all(4.0)}){
    
  return Container(
    margin: margin,
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: fillColor
    ),
    child: Center(
      child: child != null?Padding(
        padding: padding,
        child:child
      ):Padding(padding: EdgeInsets.all(0),),
    ),
  );
}

