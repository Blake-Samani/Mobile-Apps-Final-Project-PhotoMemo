import 'package:flutter/material.dart';

class MyDialog {
  static void circularProgressStart(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible:
          false, //allows dialog box to stay open upon clicking outside of the box
      builder: (context) => Center(
        child: CircularProgressIndicator(
          //spinning wheel
          strokeWidth: 10.0,
        ),
      ),
    );
  }

  static void circularProgrossStop(BuildContext context) {
    //stops the circular wheel
    Navigator.pop(context);
  }

  static void info({
    @required BuildContext context,
    @required String title,
    @required String content,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          FlatButton(
            onPressed: () => Navigator.of(context)
                .pop(), //pop dismisses the dialog box after pressing ok
            child: Text(
              'OK',
              style: Theme.of(context).textTheme.button,
            ),
          ),
        ],
      ),
    );
  }
}
