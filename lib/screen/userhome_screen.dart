import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:photomemoapp/controller/firebasecontroller.dart';
import 'package:photomemoapp/model/constant.dart';
import 'package:photomemoapp/model/photomemo.dart';
import 'package:photomemoapp/screen/myview/myimage.dart';

import 'addphotomemo_screen.dart';

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
          title: Text('User Home'),
        ),
        drawer: Drawer(
          child: ListView(
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(user.displayName ??
                    'N/A'), //if user display is null, its NA otherwise it will populate from the user being passed through args
                accountEmail: Text(user.email ?? 'N/A'),
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
                itemBuilder: (BuildContext context, int index) => ListTile(
                  leading: MyImage.network(
                    url: photoMemoList[index].photoURL,
                    context: context,
                  ),
                  title: Text(photoMemoList[index].title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, //aligns text to left
                    children: [
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
                        'Shared By: ${photoMemoList[index].shareWith}',
                      ),
                      Text(
                        'Updated At: ${photoMemoList[index].timestamp}',
                      ),
                    ],
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
        Constant.ARG_USER: state.user
      }, //this passes user from previous screen into our current user variable
    );
  }
}
