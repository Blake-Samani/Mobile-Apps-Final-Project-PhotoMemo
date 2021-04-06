import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photomemoapp/controller/firebasecontroller.dart';
import 'package:photomemoapp/model/constant.dart';
import 'package:photomemoapp/model/photomemo.dart';
import 'package:photomemoapp/screen/myview/mydialog.dart';
import 'package:photomemoapp/screen/myview/myimage.dart';

class DetailedViewScreen extends StatefulWidget {
  static const routeName = '/detailedScreenView';
  @override
  State<StatefulWidget> createState() {
    return _DetailedViewState();
  }
}

class _DetailedViewState extends State<DetailedViewScreen> {
  _Controller con;
  User user;
  PhotoMemo onePhotoMemoOriginal;
  PhotoMemo onePhotoMemoTemp;
  String progressMessage;

  bool editMode = false; //for edit mode
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

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
    onePhotoMemoOriginal ??= args[Constant.ARG_ONE_PHOTOMEMO];
    onePhotoMemoTemp ??= PhotoMemo.clone(onePhotoMemoOriginal);
    return Scaffold(
      appBar: AppBar(
        title: Text('Detailed View'),
        actions: [
          editMode // if editmode is true, then the icon is a check and if we click it we update
              ? IconButton(icon: Icon(Icons.check), onPressed: con.update)
              : IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: con
                      .edit), //else we show the edit button and on click we edit the page
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
                    height:
                        MediaQuery.of(context).size.height * 0.4, //40% of screen height
                    child: con.photoFile == null
                        ? MyImage.network(
                            url: onePhotoMemoTemp.photoURL,
                            context: context,
                          )
                        : Image.file(
                            // otherwise its from camera or gallery that we choose
                            con.photoFile,
                            fit: BoxFit.fill,
                          ),
                  ),
                  editMode
                      ? Positioned(
                          right: 0.0,
                          bottom: 0.0,
                          child: Container(
                            color: Colors.blue[300],
                            child: PopupMenuButton<String>(
                              onSelected: con.getPhoto,
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: Constant.SRC_CAMERA,
                                  child: Row(
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
                                      Icon(Icons.photo_library),
                                      Text(Constant.SRC_GALLERY),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 1.0,
                        ),
                ],
              ),
              progressMessage == null
                  ? SizedBox(
                      height: 1.0,
                    )
                  : Text(
                      progressMessage,
                      style: Theme.of(context).textTheme.headline6,
                    ),
              Text('Title'),
              TextFormField(
                enabled:
                    editMode, //if editmode is false, we wont be able to edit. editmode
                style: Theme.of(context).textTheme.headline6,
                decoration: InputDecoration(
                  hintText: 'Enter title',
                ),
                initialValue: onePhotoMemoTemp.title,
                autocorrect: true,
                validator: PhotoMemo.validateTitle,
                onSaved: con.saveTitle,
              ),
              Text('Memo'),
              TextFormField(
                enabled:
                    editMode, //if editmode is false, we wont be able to edit. editmode
                decoration: InputDecoration(
                  hintText: 'Enter memo',
                ),
                initialValue: onePhotoMemoTemp.memo,
                autocorrect: true,
                keyboardType: TextInputType.multiline,
                maxLines: 6,
                validator: PhotoMemo.validateMemo,
                onSaved: con.saveMemo,
              ),
              Text('Users that you have shared your photos with'),
              TextFormField(
                enabled:
                    editMode, //if editmode is false, we wont be able to edit. editmode
                decoration: InputDecoration(
                  hintText: 'Enter shared with (email list)',
                ),
                initialValue: onePhotoMemoTemp.sharedWith
                    .join(','), //we use join by comma since shre with is a list(array)
                autocorrect: false,
                keyboardType: TextInputType.multiline,
                maxLines: 2,
                validator: PhotoMemo.validateSharedWith,
                onSaved: con.saveSharedWith,
              ),
              SizedBox(
                //spacing
                height: 5.0,
              ),
              Text('Users that like your photo'),
              TextFormField(
                enabled: false, //if editmode is false, we wont be able to edit. editmode
                decoration: InputDecoration(
                  hintText: 'Users',
                ),
                initialValue: onePhotoMemoTemp.likes
                    .join(',')
                    .replaceAll('[', '')
                    .replaceAll(']', ''),
                //we use join by comma since shre with is a list(array)
                autocorrect: false,
                keyboardType: TextInputType.multiline,
                maxLines: 6,
                validator: PhotoMemo.validateLikes,
                onSaved: con.saveLikes,
              ),
              Constant.DEV //show image labels only for dev mode, if dev mode not enable, just show invis box
                  ? Text(
                      'Image Labels Generated by ML',
                      style: Theme.of(context).textTheme.bodyText1,
                    )
                  : SizedBox(height: 1.0),
              Constant.DEV
                  ? Text(onePhotoMemoTemp.imageLabels.join(' | '))
                  : SizedBox(
                      height: 1.0,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Controller {
  _DetailedViewState state;
  _Controller(this.state);
  File photoFile; //camera or gallery

  void update() async {
    if (!state.formKey.currentState.validate()) return;

    state.formKey.currentState.save();
    // state.render(() => state.editMode = false); //edit mode button change
    try {
      MyDialog.circularProgressStart(state.context);
      Map<String, dynamic> updateInfo = {}; //store the cahnges to photomemo
      if (photoFile != null) {
        //if photo has been updated
        Map photoInfo = await FirebaseController.uploadPhotoFile(
          photo: photoFile,
          filename: state.onePhotoMemoTemp.photoFilename,
          uid: state.user.uid,
          listener: (double message) {
            //as photo file is uploaded this is called
            state.render(() {
              if (message == null)
                state.progressMessage = null;
              else {
                message *= 100;
                state.progressMessage = 'Uploading: ' + message.toStringAsFixed(1) + " %";
              }
            });
          },
        );
        state.onePhotoMemoTemp.photoURL = photoInfo[Constant.ARG_DOWNLOADURL];
        state.render(() => state.progressMessage = 'ML image labeler started');
        List<dynamic> labels =
            await FirebaseController.getImageLabels(photoFile: photoFile);
        state.onePhotoMemoTemp.imageLabels = labels;

        updateInfo[PhotoMemo.PHOTO_URL] = photoInfo[Constant.ARG_DOWNLOADURL];
        updateInfo[PhotoMemo.IMAGE_LABELS] = labels;
      }
      //determine updated fields other than photo related
      if (state.onePhotoMemoOriginal.title != state.onePhotoMemoTemp.title)
        updateInfo[PhotoMemo.TITLE] = state.onePhotoMemoTemp.title;
      if (state.onePhotoMemoOriginal.memo != state.onePhotoMemoTemp.memo)
        updateInfo[PhotoMemo.MEMO] = state.onePhotoMemoTemp.memo;
      if (!listEquals(
          state.onePhotoMemoOriginal.sharedWith, state.onePhotoMemoTemp.sharedWith))
        updateInfo[PhotoMemo.SHARED_WITH] = state.onePhotoMemoTemp.sharedWith;
      if (!listEquals(state.onePhotoMemoOriginal.likes, state.onePhotoMemoTemp.likes))
        updateInfo[PhotoMemo.LIKES] = state.onePhotoMemoTemp.likes;

      updateInfo[PhotoMemo.TIMESTAMP] = DateTime.now();
      await FirebaseController.updatePhotoMemo(state.onePhotoMemoTemp.docID, updateInfo);

      state.onePhotoMemoOriginal.assign(state.onePhotoMemoTemp);
      MyDialog.circularProgrossStop(state.context);
      Navigator.pop(state.context);
    } catch (e) {
      MyDialog.circularProgrossStop(state.context);
      MyDialog.info(
          context: state.context, title: 'Update photoMemo Error', content: '$e');
    }
  }

  void edit() {
    state.render(() => state.editMode = true); // edit mode button change
  }

  void getPhoto(String src) async {
    try {
      PickedFile _photoFile;
      if (src == Constant.SRC_CAMERA) {
        _photoFile = await ImagePicker().getImage(source: ImageSource.camera);
      } else {
        _photoFile = await ImagePicker().getImage(source: ImageSource.gallery);
      }
      if (_photoFile == null) return; // selection canceled
      state.render(() => photoFile = File(_photoFile.path));
    } catch (e) {
      MyDialog.info(context: state.context, title: 'Error', content: '$e');
    }
  }

  void saveTitle(String value) {
    state.onePhotoMemoTemp.title = value;
  }

  void saveMemo(String value) {
    state.onePhotoMemoTemp.memo = value;
  }

  void saveSharedWith(String value) {
    if (value.trim().length != 0) {
      state.onePhotoMemoTemp.sharedWith = value
          .split(RegExp('(,| )+'))
          .map((e) => e.trim())
          .toList(); //see other functio nliek this
    }
  }

  void saveLikes(String value) {
    if (value.trim().length != 0) {
      state.onePhotoMemoTemp.likes = value
          .split(RegExp('(,)+'))
          .map((e) => e.trim())
          .toList(); //see other functio nliek this
      value.replaceAll('[', '');
      value.replaceAll(']', '');
    }
  }
}
