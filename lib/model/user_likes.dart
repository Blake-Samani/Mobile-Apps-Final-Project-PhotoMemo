import 'package:firebase_auth/firebase_auth.dart';
import 'package:photomemoapp/model/photomemo.dart';

class UserLikes {
  String uid;
  String docID;
  String photoFile;
  bool hasLiked;

  static const USER_ID = 'uid';
  static const HAS_LIKED = 'hasLiked';
  static const PHOTO_FILE_NAME = 'photoFile';

  UserLikes({
    this.uid,
    this.docID,
    this.hasLiked,
    this.photoFile,
  });

  void assign(UserLikes u) {
    this.docID = u.docID;
    this.uid = u.uid;
    this.hasLiked = u.hasLiked;
    this.photoFile = u.photoFile;
  }

  Map<String, dynamic> serialize() {
    return <String, dynamic>{
      USER_ID: this.uid,
      HAS_LIKED: this.hasLiked,
      PHOTO_FILE_NAME: this.photoFile,
    };
  }

  static UserLikes deserialize(Map<String, dynamic> doc, String docID) {
    return UserLikes(
      docID: docID,
      uid: doc[USER_ID],
      hasLiked: doc[HAS_LIKED],
      photoFile: doc[PHOTO_FILE_NAME],
    );
  }

  // void setLikedTrue() {
  //   this.hasLiked = true;
  // }

  // void setLikedFalse() {
  //   this.hasLiked = false;
  // }

  // bool getLiked() {
  //   return this.hasLiked;
  // }

  // void setUID(String email) {
  //   uid = email;
  // }
}
