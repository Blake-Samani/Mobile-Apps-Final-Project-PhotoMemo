import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photomemoapp/controller/firebasecontroller.dart';
import 'package:photomemoapp/model/constant.dart';
import 'package:photomemoapp/model/photomemo.dart';
import 'dart:convert';

import 'myview/mydialog.dart';

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
  PhotoMemo onePhotoMemoOriginal;
  PhotoMemo onePhotoMemoTemp;

  bool editMode = false;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  void initState() {
    super.initState();
    con = _Controller(this);
  }

  void render(fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    Map args = ModalRoute.of(context).settings.arguments;
    user ??= args[Constant.ARG_USER];
    onePhotoMemoOriginal ??= args[Constant.ARG_ONE_PHOTOMEMO];
    onePhotoMemoTemp ??= PhotoMemo.clone(onePhotoMemoOriginal);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Comments Screen'),
      ),
      body: new GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).requestFocus(new FocusNode());
        },
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                enabled:
                    true, //if editmode is false, we wont be able to edit. editmode //fix this
                style: Theme.of(context).textTheme.headline6,
                decoration: InputDecoration(
                  hintText: 'Comment here',
                ),
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                autocorrect: false,
                validator: PhotoMemo.validateComments,
                onSaved: con.saveComments, //fix this
              ),
              IconButton(
                icon: Icon(Icons.check),
                onPressed: con.update,
              ),
              Flexible(
                // keeps comments from overflow on screen
                flex: 2,
                child: Container(
                  child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      itemCount: onePhotoMemoTemp.comments.length,
                      itemBuilder: (con.getComments)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Controller {
  _CommentsScreenState state;
  _Controller(this.state);
  List<String> comments;

  void update() async {
    if (!state.formKey.currentState.validate()) return;

    state.formKey.currentState.save();

    try {
      //checks
      await FirebaseController.updatePhotoComments(
          state.onePhotoMemoOriginal.docID, state.onePhotoMemoTemp.comments);
      // comments = List.from(await FirebaseController.getPhotoComments(
      //     docID: state.onePhotoMemoOriginal.docID));
      // print(comments);
      // await FirebaseController.getPhotoComments(
      //     docID: state.onePhotoMemoOriginal.docID);
    } catch (e) {
      MyDialog.circularProgrossStop(state.context);
      MyDialog.info(
          context: state.context, title: 'Update photoMemo Error', content: '$e');
    }

    state.onePhotoMemoOriginal.assign(state.onePhotoMemoTemp);
  }

  void saveComments(String value) async {
    // comments = List.from(await FirebaseController.getPhotoComments(
    //     docID: state.onePhotoMemoOriginal.docID));

    if (value.trim().length != 0) {
      state.render(() => state.onePhotoMemoTemp.comments.add(value));
      // state.onePhotoMemoTemp.comments.add(value); //original
      // state.onePhotoMemoOriginal.assign(state.onePhotoMemoTemp);
    }
  }

  Widget getComments(BuildContext context, int index) {
    String comment = state.onePhotoMemoTemp.comments[index].toString();
    // state.onePhotoMemoOriginal.assign(state.onePhotoMemoTemp);
    return Container(
      padding: EdgeInsets.all(10.0),
      margin: EdgeInsets.all(10.0),
      color: Colors.transparent,
      child: Container(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(comment),
            ],
          ),
        ),
      ),
    );
  }

  Widget getTheComments(BuildContext context, int index) {
    String comment = comments[index].toString();
    return Container(
      padding: EdgeInsets.all(10.0),
      margin: EdgeInsets.all(10.0),
      color: Colors.transparent,
      child: Container(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(comment),
            ],
          ),
        ),
      ),
    );
  }
}
