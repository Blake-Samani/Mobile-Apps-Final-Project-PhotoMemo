import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:photomemoapp/controller/firebasecontroller.dart';
import 'package:photomemoapp/model/comments.dart';
import 'package:photomemoapp/model/constant.dart';
import 'package:photomemoapp/model/photomemo.dart';

import 'package:photomemoapp/screen/myview/myimage.dart';

import 'comment_screen.dart';
import 'myview/mydialog.dart';

class SharedWithScreen extends StatefulWidget {
  static const routeName = '/sharedWithScreen';
  @override
  State<StatefulWidget> createState() {
    return _SharedWithState();
  }
}

class _SharedWithState extends State<SharedWithScreen> {
  _Controller con;
  User user;
  List<PhotoMemo> photoMemoList;
  List<CommentList> commentList;
  String userID;
  List<String> email;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    con = _Controller(this);
  }

  void render(fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    Map args = ModalRoute.of(context).settings.arguments;
    user ??= args[Constant.ARG_USER];
    photoMemoList ??= args[Constant.ARG_PHOTOMEMOLIST];
    userID ??= user.email;

    return Scaffold(
      appBar: AppBar(
        title: Text('Shared with me'),
      ),
      body: photoMemoList.length == 0
          ? Text(
              'No PhotoMemos shared with me',
              style: Theme.of(context).textTheme.headline5,
            )
          : ListView.builder(
              itemCount: photoMemoList.length,
              itemBuilder: (context, index) => Card(
                elevation: 7.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, //moves title to left
                  children: [
                    Center(
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: MyImage.network(
                          url: photoMemoList[index].photoURL,
                          context: context,
                        ),
                      ),
                    ),
                    ButtonBar(
                      // alignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.comment),
                          onPressed: () => con.comment(index),
                          iconSize: 35.0,
                        ),
                        IconButton(
                          color: photoMemoList[index].likes.contains(user.email)
                              ? Colors.blue
                              : Colors.grey,
                          icon: Icon(Icons.thumb_up),
                          onPressed: () {
                            if (!photoMemoList[index].likes.contains(user.email)) {
                              con.addLike(index);
                              setState(() {
                                photoMemoList[index].likes.add(user.email);
                              });
                            } else {
                              con.removeLike(index);
                              setState(() {
                                photoMemoList[index].likes.remove(user.email);
                              });
                            }
                          },
                          iconSize: 35.0,
                        ),
                      ],
                    ),
                    Text(
                      'Title: ${photoMemoList[index].title}',
                      style: Theme.of(context).textTheme.headline6,
                    ),
                    Text('Memo: ${photoMemoList[index].memo}'),
                    Text('Created by: ${photoMemoList[index].createdBy}'),
                    Text('Updated at: ${photoMemoList[index].timestamp}'),
                    Text('Shared with: ${photoMemoList[index].sharedWith}'),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Controller {
  _SharedWithState state;
  _Controller(this.state);

  void comment(int index) async {
    try {
      state.commentList = await FirebaseController.getCommentList(
          fileName: state.photoMemoList[index].photoFilename);
      // youzer.setUID(state.userID); //setting uid for likes
    } catch (e) {
      MyDialog.info(context: state.context, title: 'Get Comments Error', content: '$e');
    }
    await Navigator.pushNamed(state.context, CommentScreen.routeName, arguments: {
      Constant.ARG_USER: state.user,
      Constant.ARG_ONE_PHOTOMEMO:
          state.photoMemoList[index], //same as userhomecreen navigating to detailed view
      Constant.ARG_COMMENTLIST: state.commentList,
    });
  }

  void removeLike(int index) async {
    try {
      await FirebaseController.deleteUserLike(
          state.photoMemoList[index], state.user.email);
    } catch (e) {
      MyDialog.info(
          context: state.context, title: 'Like Button Delete Error', content: '$e');
    }
  }

  void addLike(int index) async {
    List<dynamic> likes = [];
    likes.add(state.user.email);
    try {
      await FirebaseController.addUserLikes(state.photoMemoList[index].docID, likes);
    } catch (e) {
      MyDialog.info(context: state.context, title: 'Like button Error', content: '$e');
    }
  }
}
