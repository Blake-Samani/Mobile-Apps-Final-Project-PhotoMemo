import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:photomemoapp/model/constant.dart';
import 'package:photomemoapp/model/photomemo.dart';

class FirebaseController {
  static Future<User> signIn({@required String email, @required String password}) async {
    //note, adding async after our function allows us to use the await feature
    //@required makes these a requirement
    //User type is from firebase
    UserCredential
        userCredential = //usercredtial object is returned, this is a firebase object
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential
        .user; //our return type is a user, managed by firebase_auth module
  }

  static Future<void> createAccount(
      {@required String email, @required String password}) async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await FirebaseAuth.instance
        .signOut(); //firebase signout function is called via our signout function in user home screen
  }

  static Future<Map<String, String>> uploadPhotoFile({
    //map of string type with a string key
    @required File photo,
    String
        filename, //must be unique because folder paths are different and based on userID
    @required String uid,
    @required Function listener, //function to show progress of upload
  }) async {
    filename ??=
        '${Constant.PHOTOIMAGE_FOLDER}/$uid/${DateTime.now()}'; //the datetime now gives us milliseconds so it guarantees a unique filename for each image uploaded
    UploadTask task = FirebaseStorage.instance
        .ref(filename)
        .putFile(photo); //upload task, uploads are file to firebase
    task.snapshotEvents.listen((TaskSnapshot event) {
      double progress =
          event.bytesTransferred / event.totalBytes; //portion of image file uploaded
      if (event.bytesTransferred == event.totalBytes) progress = null;
      listener(
          progress); //pass progess into our listener function to show progress on screen
    });
    await task;
    String downloadURL = await FirebaseStorage.instance
        .ref(filename)
        .getDownloadURL(); // get the imagefile uploaded URL
    return <String, String>{
      Constant.ARG_DOWNLOADURL: downloadURL,
      Constant.ARG_FILENAME: filename
    };
  }

  static Future<String> addPhotoMemo(PhotoMemo photoMemo) async {
    var ref = await FirebaseFirestore.instance
        .collection(Constant.PHOTOMEMO_COLLECTION) //name of collection
        .add(photoMemo.serialize()); //dart object serialized into a collection
    return ref.id; //unique id generated from saved document
  }

  static Future<List<PhotoMemo>> getPhotoMemoList({@required String email}) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection(Constant.PHOTOMEMO_COLLECTION) //our collection
        .where(PhotoMemo.CREATED_BY,
            isEqualTo:
                email) //where the emails are equal, usuer should only see their own photomemos
        .orderBy(PhotoMemo.TIMESTAMP, descending: true) //sort by descending timestamps
        .get(); // gets all of them

    var result = <PhotoMemo>[];
    querySnapshot.docs.forEach((doc) {
      //for each document
      result.add(PhotoMemo.deserialize(
          doc.data(), doc.id)); // deserialize and add the data and the id to our result
    });
    return result; //result is a list type
  }

  //method to extract image label with googles ML

  static Future<List<dynamic>> getImageLabels({@required File photoFile}) async {
    final FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(photoFile);
    final ImageLabeler cloudLabeler = FirebaseVision.instance.cloudImageLabeler();
    final List<ImageLabel> cloudLabel = await cloudLabeler.processImage(visionImage);
    List<dynamic> labels = <dynamic>[];
    for (ImageLabel label in cloudLabel) {
      if (label.confidence >= Constant.MIN_ML_CONFIDENCE)
        labels.add(label.text.toLowerCase());
    }
    return labels;
  }

  static Future<void> updatePhotoMemo(
      String docId, Map<String, dynamic> updateInfo) async {
    await FirebaseFirestore.instance
        .collection(Constant.PHOTOMEMO_COLLECTION)
        .doc(docId)
        .update(updateInfo);
  }

  static Future<List<PhotoMemo>> getPhotoMemoSharedWithMe(
      {@required String email}) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection(Constant.PHOTOMEMO_COLLECTION)
        .where(PhotoMemo.SHARED_WITH, arrayContains: email)
        .orderBy(PhotoMemo.TIMESTAMP, descending: true)
        .get();

    var result = <PhotoMemo>[];
    querySnapshot.docs.forEach((doc) {
      result.add(PhotoMemo.deserialize(doc.data(), doc.id));
    });
    return result;
  }

  static Future<void> deletePhotoMemo(PhotoMemo p) async {
    await FirebaseFirestore.instance
        .collection(Constant.PHOTOMEMO_COLLECTION)
        .doc(p.docID)
        .delete();
    await FirebaseStorage.instance.ref().child(p.photoFilename).delete();
  }

  static Future<List<PhotoMemo>> searchImage({
    @required String createdBy,
    @required List<String> searchLabels,
  }) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection(Constant.PHOTOMEMO_COLLECTION)
        .where(PhotoMemo.CREATED_BY, isEqualTo: createdBy)
        .where(PhotoMemo.IMAGE_LABELS, arrayContainsAny: searchLabels)
        .orderBy(PhotoMemo.TIMESTAMP, descending: true)
        .get();
    var results = <PhotoMemo>[];
    querySnapshot.docs.forEach(
      (doc) => results.add(
        PhotoMemo.deserialize(
          doc.data(),
          doc.id,
        ),
      ),
    );
    return results;
  }
}
