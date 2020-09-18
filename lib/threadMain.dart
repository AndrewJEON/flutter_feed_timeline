import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutterthreadexample/commons/const.dart';
import 'package:flutterthreadexample/contentDetail.dart';
import 'package:flutterthreadexample/controllers/FBCloudStore.dart';
import 'package:flutterthreadexample/controllers/localTempDB.dart';
import 'package:flutterthreadexample/writePost.dart';

import 'commons/utils.dart';

class ThreadMain extends StatefulWidget{
  final MyProfileData myData;
  final ValueChanged<MyProfileData> updateMyData;
  ThreadMain({this.myData,this.updateMyData});
  @override State<StatefulWidget> createState() => _ThreadMain();
}

class _ThreadMain extends State<ThreadMain>{
  bool _isLoading = false;

  void _writePost() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => WritePost(myData: widget.myData,)));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('thread').orderBy('postTimeStamp',descending: true).snapshots(),
        builder: (context,snapshot) {
          if (!snapshot.hasData) return LinearProgressIndicator();
          return Stack(
            children: <Widget>[
              snapshot.data.documents.length > 0 ?
              ListView(
                shrinkWrap: true,
                children: snapshot.data.documents.map(_listTile).toList(),
              ) : Container(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.error,color: Colors.grey[700],
                        size: 64,),
                        Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Text('There is no post',
                          style: TextStyle(fontSize: 16,color: Colors.grey[700]),
                          textAlign: TextAlign.center,),
                      ),
                    ],
                  )
                ),
              ),
              _isLoading ? Positioned(
                child: Container(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                  color: Colors.white.withOpacity(0.7),
                ),
              ) : Container()
            ],
          );
        }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _writePost,
        tooltip: 'Increment',
        child: Icon(Icons.create),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _updateLikeCount(DocumentSnapshot data, bool isLikePost) async {
    List<String> newLikeList = await LocalTempDB.saveLikeList(data['postID'],widget.myData.myLikeList,isLikePost,'likeList');
    MyProfileData myProfileData = MyProfileData(
        myName: widget.myData.myName,
        myThumbnail: widget.myData.myThumbnail,
        myLikeList: newLikeList
    );
    widget.updateMyData(myProfileData);
    await FBCloudStore.updatePostLikeCount(data,isLikePost);
    await FBCloudStore.likeToPost(data['postID'], widget.myData,isLikePost);
  }


  void _moveToContentDetail(DocumentSnapshot data) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ContentDetail(postData: data,myData: widget.myData,updateMyData: widget.updateMyData,)));
  }

  Widget _listTile(DocumentSnapshot data){
    return Padding(
      padding: const EdgeInsets.fromLTRB(2.0,2.0,2.0,6),
      child: Card(
        elevation:2.0,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              GestureDetector(
                onTap: () => _moveToContentDetail(data),
                child: Row(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6.0,2.0,10.0,2.0),
                      child: Container(
                          width: 48,
                          height: 48,
                          child: Image.asset('images/${data['userThumbnail']}')
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(data['userName'],style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                        Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Text(readTimestamp(data['postTimeStamp']),style: TextStyle(fontSize: 16,color: Colors.black87),),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _moveToContentDetail(data),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8,10,4,10),
                  child: Text((data['postContent'] as String).length > 200 ? '${data['postContent'].substring(0, 132)} ...' : data['postContent'],
                    style: TextStyle(fontSize: 16,),
                    maxLines: 3,),
                ),
              ),
              data['postImage'] != 'NONE' ? GestureDetector(onTap: () => _moveToContentDetail(data),child: Utils.cacheNetworkImageWithEvent(context,data['postImage'],0,0)) :
              Container(),
              Divider(height: 2,color: Colors.black,),
              Padding(
                padding: const EdgeInsets.only(top:6.0,bottom: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () => _updateLikeCount(data,widget.myData.myLikeList != null && widget.myData.myLikeList.contains(data['postID']) ? true : false),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.thumb_up,size: 18,color: widget.myData.myLikeList != null && widget.myData.myLikeList.contains(data['postID']) ? Colors.blue[900] : Colors.black),
                          Padding(
                            padding: const EdgeInsets.only(left:8.0),
                            child: Text('Like ( ${data['postLikeCount']} )',
                              style: TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.bold,
                              color: widget.myData.myLikeList != null && widget.myData.myLikeList.contains(data['postID']) ? Colors.blue[900] : Colors.black),),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _moveToContentDetail(data),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.mode_comment,size: 18),
                          Padding(
                            padding: const EdgeInsets.only(left:8.0),
                            child: Text('Comment ( ${data['postCommentCount']} )',style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EnterExitRoute extends PageRouteBuilder {
  final Widget enterPage;
  final Widget exitPage;
  EnterExitRoute({this.exitPage, this.enterPage})
      : super(
    pageBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        ) =>
    enterPage,
    transitionsBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
        ) =>
        Stack(
          children: <Widget>[
            SlideTransition(
              position: new Tween<Offset>(
                begin: const Offset(0.0, 0.0),
                end: const Offset(-1.0, 0.0),
              ).animate(animation),
              child: exitPage,
            ),
            SlideTransition(
              position: new Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: enterPage,
            )
          ],
        ),
  );
}
