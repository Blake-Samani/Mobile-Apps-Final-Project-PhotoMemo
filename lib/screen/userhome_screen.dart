import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photomemoapp/controller/firebasecontroller.dart';
import 'package:photomemoapp/model/comments.dart';
import 'package:photomemoapp/model/constant.dart';
import 'package:photomemoapp/model/photomemo.dart';
import 'package:photomemoapp/screen/detailedview_screen.dart';
import 'package:photomemoapp/screen/myview/mydialog.dart';
import 'package:photomemoapp/screen/myview/myimage.dart';
import 'package:photomemoapp/screen/sharedwith_screen.dart';

import 'addphotomemo_screen.dart';
import 'comment_screen.dart';

class UserHomeScreen extends StatefulWidget {
  static const routeName = '/userHomeScreen';
  @override
  State<StatefulWidget> createState() {
    return _UserHomeState();
  }
}

class _UserHomeState extends State<UserHomeScreen> {
  _Controller con;
  User user;
  List<PhotoMemo> photoMemoList;
  List<PhotoMemo> photoMemoListTemp;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  List<CommentList> commentList;
  PhotoMemo tempMemo;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    con = _Controller(this);
  }

  void render(fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    Map args = ModalRoute.of(context)
        .settings
        .arguments; //this is reading the user from signinscreen. User is a map data structure in firebase, we are taking the arguments from bottom of signinscreen through context
    user ??= args[Constant //constant.arguser is from our constant class
        .ARG_USER]; //key of user data structure to get the user is user, defined in sign in screen..this is saying if user is not initialized, get it from args? with the key???? idk

    photoMemoList ??= args[Constant.ARG_PHOTOMEMOLIST];

    return WillPopScope(
      //will pop scope widget allows us to disable the back button on bottom of andoid system
      onWillPop: () =>
          Future.value(false), //this is the function we use to disable the back button
      child: Scaffold(
        appBar: AppBar(
          // title: Text('User Home'),
          actions: [
            con.delIndex != null
                ? IconButton(icon: Icon(Icons.cancel), onPressed: con.cancelDelete)
                : Form(
                    key: formKey,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: TextFormField(
                          decoration: InputDecoration(
                            hintText: 'Search',
                            fillColor: Theme.of(context).backgroundColor,
                            filled: true,
                          ),
                          autocorrect: true,
                          onSaved: con.saveSearchKeyString,
                        ),
                      ),
                    ),
                  ),
            con.delIndex != null
                ? IconButton(icon: Icon(Icons.delete), onPressed: con.delete)
                : IconButton(
                    icon: Icon(Icons.search),
                    onPressed: con.search,
                  ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            children: [
              UserAccountsDrawerHeader(
                currentAccountPicture: Icon(
                  Icons.person,
                  size: 100.0,
                ),
                accountName: Text(user.displayName ??
                    'N/A'), //if user display is null, its NA otherwise it will populate from the user being passed through args
                accountEmail: Text(user.email ?? 'N/A'),
              ),
              ListTile(
                leading: Icon(Icons.people),
                title: Text('Shared with me'),
                onTap: con.sharedWithMe,
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                onTap: null,
              ),
              ListTile(
                leading: Icon(Icons.exit_to_app),
                title: Text('Sign Out'),
                onTap: con.signOut,
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          //bottom addition sign button
          child: Icon(Icons.add),
          onPressed: con.addButton,
        ),
        body: photoMemoList.length == 0
            ? Text('No PhotoMemos Found!', style: Theme.of(context).textTheme.headline5)
            : ListView.builder(
                itemCount: photoMemoList.length,
                itemBuilder: (BuildContext context, int index) => Container(
                  color: con.delIndex != null && con.delIndex == index
                      ? Theme.of(context).highlightColor
                      : Theme.of(context).scaffoldBackgroundColor,
                  child: ListTile(
                    leading: MyImage.network(
                      url: photoMemoList[index].photoURL,
                      context: context,
                    ),

                    trailing: Icon(Icons.keyboard_arrow_right),
                    title: Text(photoMemoList[index].title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, //aligns text to left
                      children: [
                        ButtonBar(
                          children: [
                            IconButton(
                              icon: Icon(Icons.comment),
                              onPressed: () => con.comment(index),
                              iconSize: 35.0,
                            ),
                            IconButton(
                              icon: Icon(Icons.thumb_up),
                              color: photoMemoList[index].likes.contains(user.email)
                                  ? Colors.blue
                                  : Colors.grey,
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
                          photoMemoList[index].memo.length >= 20
                              ? photoMemoList[index].memo.substring(0, 20) +
                                  '...' //truncate
                              : photoMemoList[index].memo,
                        ), //else display everything
                        Text(
                          'Created By: ${photoMemoList[index].createdBy}',
                        ),
                        Text(
                          'Shared With: ${photoMemoList[index].sharedWith}',
                        ),
                        Text(
                          'Updated At: ${photoMemoList[index].timestamp}',
                        ),
                      ],
                    ),
                    onTap: () => con.onTap(
                        index), //index of the list that is clicked on, e.g. which picture, which is why we pass index
                    onLongPress: () => con.onLongPress(index),
                  ),
                ),
              ),
      ),
    );
  }
}

class _Controller {
  _UserHomeState state;
  _Controller(this.state);
  int delIndex;
  String keyString;

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

  void signOut() async {
    try {
      await FirebaseController.signOut();
    } catch (e) {
      //do nothing
    }
    Navigator.of(state.context).pop(); //this closes the drawer
    Navigator.of(state.context)
        .pop(); //this will pop user home screen, taking us back to sign in screen
  }

  void addButton() async {
    //navigate to add photomemo screen, bottom floating add button
    await Navigator.pushNamed(
      state.context,
      AddPhotoMemoScreen.routeName,
      arguments: {
        Constant.ARG_USER: state.user,
        Constant.ARG_PHOTOMEMOLIST: state.photoMemoList,
      }, //this passes user from previous screen into our current user variable
    );
    state.render(() {}); //re render the screen
  }

  void onTap(int index) async {
    if (delIndex != null) return;
    await Navigator.pushNamed(
      state.context,
      DetailedViewScreen.routeName,
      arguments: {
        Constant.ARG_USER: state.user,
        Constant.ARG_ONE_PHOTOMEMO: state.photoMemoList[index],
      },
    );
    state.render(() {});
  }

  void sharedWithMe() async {
    // List<bool> hasLiked = [];
    try {
      List<PhotoMemo> photoMemoList = await FirebaseController.getPhotoMemoSharedWithMe(
        email: state.user.email,
      );

      await Navigator.pushNamed(state.context, SharedWithScreen.routeName, arguments: {
        Constant.ARG_USER: state.user,
        Constant.ARG_PHOTOMEMOLIST: photoMemoList,
      });
      Navigator.pop(state.context); //closes the drawer
    } catch (e) {
      MyDialog.info(
          context: state.context, title: 'get Shared photomemo error', content: '$e');
    }
  }

  void onLongPress(int index) {
    if (delIndex != null) return;
    state.render(() => delIndex = index);
  }

  void cancelDelete() {
    state.render(() => delIndex = null);
  }

  void delete() async {
    try {
      PhotoMemo p = state.photoMemoList[delIndex];
      await FirebaseController.deletePhotoMemo(p);
      state.render(() {
        state.photoMemoList.removeAt(delIndex);
        delIndex = null;
      });
    } catch (e) {
      MyDialog.info(
          context: state.context, title: 'Delete PhotoMemo error', content: '$e');
    }
  }

  void saveSearchKeyString(String value) {
    keyString = value;
  }

  void search() async {
    state.formKey.currentState.save();
    var keys = keyString.split(',').toList();
    List<String> searchKeys = [];
    for (var k in keys) {
      if (k.trim().isNotEmpty) searchKeys.add(k.trim().toLowerCase());
    }
    try {
      List<PhotoMemo> results;
      if (searchKeys.isNotEmpty) {
        results = await FirebaseController.searchImage(
          createdBy: state.user.email,
          searchLabels: searchKeys,
        );
      } else {
        results = await FirebaseController.getPhotoMemoList(email: state.user.email);
      }
      state.render(() => state.photoMemoList = results);
    } catch (e) {
      MyDialog.info(context: state.context, title: 'Search Error', content: '$e');
    }
  }

  void comment(int index) async {
    try {
      state.commentList = await FirebaseController.getCommentList(
          fileName: state.photoMemoList[index].photoFilename);
    } catch (e) {
      MyDialog.info(context: state.context, title: 'Get Comments Error', content: '$e');
    }
    //might need work
    await Navigator.pushNamed(state.context, CommentScreen.routeName, arguments: {
      Constant.ARG_USER: state.user,
      Constant.ARG_ONE_PHOTOMEMO:
          state.photoMemoList[index], //same as userhomecreen navigating to detailed view
      Constant.ARG_COMMENTLIST: state.commentList,
    });
  }
}
