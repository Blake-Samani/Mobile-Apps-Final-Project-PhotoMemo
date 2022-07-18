class CommentList {
  String docID;
  String createdBy;
  DateTime timestamp;
  String commentFilename;
  String comment;

  static const CREATED_BY = 'createdBy';
  static const COMMENT_LIST = 'commentList';
  static const TIMESTAMP = 'timestamp';
  static const COMMENT_FILENAME = 'commentFilename';

  CommentList({
    this.docID,
    this.createdBy,
    this.timestamp,
    this.comment,
    this.commentFilename,
  });

  CommentList.clone(CommentList c) {
    this.docID = c.docID;
    this.createdBy = c.createdBy;
    this.timestamp = c.timestamp;
    this.commentFilename = c.commentFilename;
    this.comment = c.comment;
  }

  void assign(CommentList c) {
    this.docID = c.docID;
    this.createdBy = c.createdBy;
    this.timestamp = c.timestamp;
    this.commentFilename = c.commentFilename;
    this.comment = c.comment;
  }

  Map<String, dynamic> serialize() {
    //uploads as a map, or list
    return <String, dynamic>{
      CREATED_BY: this.createdBy,
      TIMESTAMP: this.timestamp,
      COMMENT_LIST: this.comment,
      COMMENT_FILENAME: this.commentFilename,
    };
  }

  static CommentList deserialize(Map<String, dynamic> doc, String docId) {
    return CommentList(
      docID: docId,
      createdBy: doc[CREATED_BY],
      commentFilename: doc[COMMENT_FILENAME],
      timestamp: doc[TIMESTAMP] == null
          ? null
          : DateTime.fromMicrosecondsSinceEpoch(doc[TIMESTAMP].millisecondsSinceEpoch),
      comment: doc[COMMENT_LIST],
    );
  }

  static String validateComment(String value) {
    if (value == null || value.length < 5 || value == '')
      return 'too short';
    else
      return null;
  }
}
