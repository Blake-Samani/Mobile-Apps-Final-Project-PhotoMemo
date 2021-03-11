import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photomemoapp/controller/firebasecontroller.dart';
import 'package:photomemoapp/model/constant.dart';
import 'package:photomemoapp/model/photomemo.dart';
import 'package:photomemoapp/screen/myview/mydialog.dart';

class AddPhotoMemoScreen extends StatefulWidget {
  static const routeName = '/addPhotoMemoScreen';
  @override
  State<StatefulWidget> createState() {
    return _AddPhotoMemoState();
  }
}

class _AddPhotoMemoState extends State<AddPhotoMemoScreen> {
  _Controller con;
  User user;
  List<PhotoMemo> photoMemoList;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  File photo; // our image //using our image picker we store into here
  String progressMessage;

  void initState() {
    super.initState();
    con = _Controller(this);
  }

  void render(fn) => setState(fn);

  static const routeName = '/addPhotoMemoScreen';
  @override
  Widget build(BuildContext context) {
    Map args = ModalRoute.of(context)
        .settings
        .arguments; //gets args info passed from previous screen
    user ??= args[Constant.ARG_USER]; // if the user is null,retreive from args our user
    photoMemoList ??= args[Constant.ARG_PHOTOMEMOLIST];
    return Scaffold(
      appBar: AppBar(
        title: Text('Add PhotoMemo'),
        actions: [
          IconButton(icon: Icon(Icons.check), onPressed: con.save),
        ],
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height *
                        0.4, //useing 40 percent of actual screen height
                    child: photo == null //if photo is null display icon
                        ? Icon(
                            Icons.photo_library,
                            size: 300,
                          )
                        : Image.file(
                            //else if its selected from camera or photo album use image class and specify from out photo
                            photo,
                            fit: BoxFit.fill,
                          ),
                  ),
                  Positioned(
                    //this allows us to put our popup menu on bottom of our image icon
                    right: 0.0,
                    bottom: 0.0,
                    child: Container(
                      //wrap popup menubutton with container to give colors, will give us bounding box error so we wrap with positioned widget
                      color: Colors.blue[200],
                      child: PopupMenuButton<String>(
                        onSelected: con.getPhoto, //get photo from camera or gallery
                        itemBuilder: (context) => <PopupMenuEntry<String>>[
                          //the type of each elemenent is ^^
                          PopupMenuItem(
                            value: Constant.SRC_CAMERA,
                            child: Row(
                              //wrap icon with row to give it text
                              children: [
                                Icon(Icons.photo_camera),
                                Text(Constant.SRC_CAMERA),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: Constant.SRC_GALLERY,
                            child: Row(
                              children: [
                                Icon(Icons.photo_album),
                                Text(Constant.SRC_GALLERY),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              progressMessage ==
                      null //if null widget is almost insivisble otherwise show progress
                  ? SizedBox(
                      height: 1.0,
                    )
                  : Text(
                      progressMessage,
                      style: Theme.of(context).textTheme.headline6,
                    ),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Title',
                ),
                autocorrect: true,
                validator: PhotoMemo.validateTitle,
                onSaved: con.saveTitle,
              ),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Memo',
                ),
                autocorrect: true,
                keyboardType: TextInputType.multiline,
                maxLines: 6,
                validator: PhotoMemo.validateMemo,
                onSaved: con.saveMemo,
              ),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'SharedWith (comma separated email list)',
                ),
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                maxLines: 2,
                validator: PhotoMemo.validateSharedWith,
                onSaved: con.saveSharedWith,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Controller {
  _AddPhotoMemoState state;
  _Controller(this.state);
  PhotoMemo tempMemo = PhotoMemo(); //temp info to store into firebase

  void save() async {
    if (!state.formKey.currentState.validate()) return;
    state.formKey.currentState.save();

    MyDialog.circularProgressStart(state.context);

    try {
      Map photoInfo = await FirebaseController.uploadPhotoFile(
        //picture upload
        photo: state.photo,
        uid: state.user.uid,
        listener: (double progress) {
          state.render(() {
            if (progress == null)
              state.progressMessage = null;
            else {
              progress *= 100; //converts to percentage
              state.progressMessage = 'Uploading: ' +
                  progress.toStringAsFixed(1) +
                  '%'; //to string as fixed 1 only 1 digit after decimal is shown
            }
          });
        },
      );

      //image labels by ML
      state.render(() => state.progressMessage = 'ML Image Labeler Started!');
      List<String> imageLabels =
          await FirebaseController.getImageLabels(photoFile: state.photo);
      state.render(() => state.progressMessage = null);

      tempMemo.photoFilename = photoInfo[Constant.ARG_FILENAME]; //photofile name
      tempMemo.photoURL = photoInfo[Constant.ARG_DOWNLOADURL];
      tempMemo.timestamp = DateTime.now();
      tempMemo.createdBy = state.user.email;
      tempMemo.imageLabels = imageLabels; //extracted from ML
      String docID = await FirebaseController.addPhotoMemo(tempMemo);
      tempMemo.docID = docID; //stored image info is now finished
      state.photoMemoList.insert(0,
          tempMemo); // Addes to beginning of list, enabling realtime shown on screen after upload

      MyDialog.circularProgrossStop(state.context);
      Navigator.pop(state.context); //return to home screen
    } catch (e) {
      MyDialog.circularProgrossStop(state.context);
      MyDialog.info(
        context: state.context,
        title: 'Save Photomemo Error',
        content: '$e',
      );
    }
  }

  void getPhoto(String src) async {
    try {
      PickedFile _imageFile; //from out image picker packege
      var _picker = ImagePicker();
      if (src == Constant.SRC_CAMERA) {
        _imageFile =
            await _picker.getImage(source: ImageSource.camera); //image picker code
      } else {
        _imageFile = await _picker.getImage(source: ImageSource.gallery);
      }
      if (_imageFile == null)
        return; //if we opened menu but never selected a picture, cancel
      state.render(() => state.photo = File(
          _imageFile.path)); //converts imagefile to a filetype adn renders at same time
    } catch (e) {
      MyDialog.info(
        context: state.context,
        title: 'Failed to get picture',
        content: '$e', //the actual error message
      );
    }
  }

  void saveTitle(String value) {
    tempMemo.title = value;
  }

  void saveMemo(String value) {
    tempMemo.memo = value;
  }

  void saveSharedWith(String value) {
    if (value.trim().length != 0) {
      tempMemo.shareWith = value.split(RegExp('(,| )+')).map((e) => e.trim()).toList();
    }
  }
}
