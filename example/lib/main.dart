import 'package:flutter/material.dart';
import 'package:swipeable/swipeable.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new SwipeableDemo(),
    );
  }
}

class SwipeableDemo extends StatefulWidget {
  @override
  SwipeableDemoState createState() {
    return new SwipeableDemoState();
  }
}

class SwipeableDemoState extends State<SwipeableDemo> {
  bool leftSelected;
  bool rightSelected;

  void initState() {
    leftSelected = false;
    rightSelected = false;
  }

  Widget build(BuildContext context) {
    var text = "nothing selected";
    if (leftSelected) {
      text = "left selected";
    }
    if (rightSelected) {
      text = "right selected";
    }
    return Scaffold(
      body: ListView(
        children: <Widget>[
          Container(
            margin: EdgeInsets.all(8.0),
            child: Swipeable(
              threshold: 60.0,
              onSwipeLeft: () {
                setState(() {
                  leftSelected = true;
                  rightSelected = false;
                });
              },
              onSwipeRight: () {
                setState(() {
                  leftSelected = false;
                  rightSelected = true;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(8.0),
                    ),
                    color: Colors.white),
                child: ListTile(
                  title: Text(text),
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(8.0),
                    ),
                    color: Colors.grey[300]),
                child: ListTile(
                  leading: new Container(
                    width: 12.0,
                    height: 12.0,
                    decoration: new BoxDecoration(
                      shape: BoxShape.circle,
                      color: leftSelected ? Colors.blue[500] : Colors.grey[600],
                    ),
                  ),
                  trailing: new Container(
                    width: 12.0,
                    height: 12.0,
                    decoration: new BoxDecoration(
                      shape: BoxShape.circle,
                      color: rightSelected ? Colors.lightGreen[500] : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
