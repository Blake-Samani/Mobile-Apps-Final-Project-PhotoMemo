import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:photomemoapp/controller/firebasecontroller.dart';
import 'package:photomemoapp/model/comments.dart';
import 'package:photomemoapp/model/constant.dart';
import 'package:photomemoapp/model/photomemo.dart';
import 'package:photomemoapp/screen/myview/mydialog.dart';

class CommentScreen extends StatefulWidget {
  static const routeName = '/commentScreen';

  @override
  State<StatefulWidget> createState() {
    return _CommentScreenState();
  }
}

class _CommentScreenState extends State<CommentScreen> {
  User user;
  _Controller con;
  List<CommentList> commentListOriginal;
  List<CommentList> commentListTemp;
  PhotoMemo onePhotoMemoOriginal;
  PhotoMemo onePhotoMemoTemp;

  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
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
    commentListOriginal ??= args[Constant.ARG_COMMENTLIST];
    final TextEditingController _textController =
        new TextEditingController(); //to clear text in form

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
                controller: _textController,
                enabled:
                    true, //if editmode is false, we wont be able to edit. editmode //fix this
                style: Theme.of(context).textTheme.headline6,
                decoration: InputDecoration(
                  hintText: 'Comment here',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: _textController.clear, //clears text upon press of X
                  ),
                ),
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                autocorrect: false,
                validator: PhotoMemo.validateComments,
                onSaved: con.saveComment,
              ),
              IconButton(
                icon: Icon(Icons.check),
                onPressed: con.save,
              ),
              Flexible(
                // keeps comments from overflow on screen
                flex: 2,
                child: Container(
                  child: ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.vertical,
                    itemCount: commentListOriginal.length,
                    itemBuilder: (context, index) => Card(
                      elevation: 7.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.1,
                                width: MediaQuery.of(context).size.width * 0.04,
                              ),
                              Text(
                                '${commentListOriginal[index].createdBy} : ',
                              ),
                              Text(
                                '${commentListOriginal[index].comment}',
                              ),
                              // Text(
                              //   '${commentListOriginal[index].timestamp}',
                              // ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
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
  _CommentScreenState state;
  _Controller(this.state);
  CommentList commentListTemp = CommentList();

  void save() async {
    if (!state.formKey.currentState.validate()) return;

    state.formKey.currentState.save();

    try {
      commentListTemp.createdBy = state.user.email;
      commentListTemp.timestamp = DateTime.now();
      commentListTemp.commentFilename = state.onePhotoMemoOriginal.photoFilename;
      String docID = await FirebaseController.addComment(commentListTemp);
      commentListTemp.docID = docID;
      // state.commentList.insert(0, commentListTemp);
      //
      state.render(() => state.commentListOriginal.add(commentListTemp));
    } on Exception catch (e) {
      MyDialog.info(context: state.context, title: 'Save Comments Error', content: '$e');
    }
  }

  void saveComment(String value) async {
    if (value.trim().length != 0) {
      // state.render(() => state.onePhotoMemoTemp.comments.add(value));
      commentListTemp.comment = value;
    }
  }
}
