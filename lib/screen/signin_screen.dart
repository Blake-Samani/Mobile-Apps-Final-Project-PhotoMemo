import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:photomemoapp/controller/firebasecontroller.dart';
import 'package:photomemoapp/model/constant.dart';
import 'package:photomemoapp/model/photomemo.dart';
import 'package:photomemoapp/screen/myview/mydialog.dart';
import 'package:photomemoapp/screen/signup_screen.dart';
import 'package:photomemoapp/screen/userhome_screen.dart';

class SignInScreen extends StatefulWidget {
  static const routeName = '/signInScreen';
  @override
  State<StatefulWidget> createState() {
    return _SignInState();
  }
}

class _SignInState extends State<SignInScreen> {
  _Controller con;
  GlobalKey<FormState> formKey = GlobalKey<FormState>(); // all forms need form key
  @override
  void initState() {
    super.initState();
    con = _Controller(this);
  }

  void render(fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign in '),
      ),
      body: Padding(
        padding: const EdgeInsets.only(
            top: 10.0, left: 15.0), //moves email and password a little to the right
        child: Form(
          key: formKey, // giving our form the key from above line 13
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  'PhotoMemo',
                  style: TextStyle(fontFamily: 'Fascinate', fontSize: 35.0),
                ),
                Text(
                  'Sign in, please!',
                  style: TextStyle(fontFamily: 'Fascinate'),
                ),
                TextFormField(
                  decoration: InputDecoration(
                    //specify a hint for our form sign in (what kind of input goes here)
                    hintText: 'Email',
                  ),
                  keyboardType: TextInputType
                      .emailAddress, //specify a type of keyboard for our form sign in
                  autocorrect: false, //turn off  autocorrect
                  validator:
                      con.validateEmail, //function from controller to validate our email
                  onSaved: con.saveEmail, //function from controller to save our email
                ),
                TextFormField(
                  decoration: InputDecoration(
                    //specify a hint for our form sign in (what kind of input goes here)
                    hintText: 'Password',
                  ),
                  obscureText: true, //hide the pw text while typing
                  autocorrect: false, //turn off  autocorrect
                  validator:
                      con.validatePassword, //function from controller to validate our pw
                  onSaved: con.savePassword, //function from controller to save our pw
                ),
                RaisedButton(
                  onPressed: con.signIn,
                  child: Text(
                    'Sign in',
                    style: Theme.of(context).textTheme.button,
                  ),
                ),
                SizedBox(
                  height: 15.0,
                ),
                RaisedButton(
                  onPressed: con.signUp,
                  child: Text('Create a new account',
                      style: Theme.of(context).textTheme.button),
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
  _SignInState state;
  _Controller(this.state);
  String email;
  String password;

  String validateEmail(String value) {
    //usually done by regular expressions
    if (value.contains('@') && value.contains('.'))
      return null;
    else
      return 'invalid email address';
  }

  void saveEmail(String value) {
    email = value;
  }

  String validatePassword(String value) {
    if (value.length < 6)
      return 'too short';
    else
      return null;
  }

  void savePassword(String value) {
    password = value;
  }

  void signIn() async {
    // List<bool> hasLiked = [];
    if (!state.formKey.currentState.validate()) return;

    state.formKey.currentState
        .save(); // all save functions will be called when this is called..savepw..saveemail

    User user;
    MyDialog.circularProgressStart(state.context); //start the progess bar
    try {
      user = await FirebaseController.signIn(
          email: email,
          password:
              password); //await, from my understanding, makes this function happen before other things can happen

    } catch (e) {
      MyDialog.circularProgrossStop(state.context);
      MyDialog.info(
        context: state.context,
        title: 'Sign in Error',
        content: e.toString(),
      );
      // print(user.email);

      // print(youzer.uid);
      return;
    }

    try {
      //all photomemos are read and when we pass to homescreen we should pass the photo memos as well
      List<PhotoMemo> photoMemoList =
          await FirebaseController.getPhotoMemoList(email: user.email);
      // List<PhotoMemo> photoMemoListTemp =
      //     await FirebaseController.getPhotoMemoList(email: user.email);
      // hasLiked.clear();

      // for (int i = 0; i < photoMemoList.length; i++) {
      //   //list to check if weve liked our photos or not
      //   if (photoMemoList[i].likes.contains(user.email)) {
      //     hasLiked.add(true);
      //   } else {
      //     hasLiked.add(false);
      //   }
      // }
      // List<UserLikes> userLike = await FirebaseController.getUserLike(uid: user.email, photoFile: photoMemoList)
      MyDialog.circularProgrossStop(state.context); // spinning wheel disapears
      Navigator.pushNamed(state.context, UserHomeScreen.routeName, //mvoe screen
          arguments: {
            Constant.ARG_USER: user,
            Constant.ARG_PHOTOMEMOLIST: photoMemoList,
            // Constant.ARG_USER_LIKE: hasLiked,
          });
    } catch (e) {
      MyDialog.circularProgrossStop(state.context); // spinning wheel disapears
      MyDialog.info(
        context: state.context,
        title: 'FireStore getPhotoMemoList error',
        content: '$e',
      );
    }
  }

  void signUp() {
    Navigator.pushNamed(state.context, SignUpScreen.routeName);
  }
}
