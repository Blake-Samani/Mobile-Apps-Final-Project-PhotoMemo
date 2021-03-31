import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:photomemoapp/model/constant.dart';
import 'package:photomemoapp/model/photomemo.dart';

class CommentsScreen extends StatefulWidget {
  static const routeName = '/commentsScreen';
  @override
  State<StatefulWidget> createState() {
    return _CommentsScreenState();
  }
}

class _CommentsScreenState extends State<CommentsScreen> {
  User user;
  _Controller con;
  List<PhotoMemo> photoMemoList;

  void initState() {
    super.initState();
    con = _Controller(this);
  }

  void render(fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    Map args = ModalRoute.of(context).settings.arguments;
    user ??= args[Constant.ARG_USER];
    photoMemoList ??= args[Constant.ARG_PHOTOMEMOLIST];
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments Screen'),
      ),
    );
  }
}

class _Controller {
  _CommentsScreenState state;
  _Controller(this.state);
}
