import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:Joint/pages/post.dart';
import 'package:Joint/pages/widgets/progress.dart';
import 'package:Joint/pages/widgets/time_screen.dart';
import './widgets/header.dart';
import './home.dart';
import 'models/fid.dart';
import 'models/user.dart';

class Timeline extends StatefulWidget {

  final String profileId;
 
  

  Timeline({this.profileId});

  @override
  _TimelineState createState() => _TimelineState(profileId: profileId);
}

class _TimelineState extends State<Timeline> {

List<Post> posts = [];
List<dynamic> fposts=[];
bool isLoading = false;
 final String profileId;
User user;
  
  _TimelineState({this.profileId});




 @override
  void initState() {
    super.initState();
 
  

    
  }
  
 
 


showTime(BuildContext context, List a,String b) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => TimeScreen(
     
     
      ),
    ),
  );
}

 fun(){
       showDialog(
        context: context,
        builder: (_) => new AlertDialog(
            title: new Text("SORRYYY BRUHHH",textAlign:TextAlign.center,style:TextStyle(fontFamily:"JustAnotherHand",fontSize: 30.0, fontWeight: FontWeight.bold,color: Colors.white)),
            content:  Text("You gotta follow atleast one user to see the timeline.Find some users to follow.Don't be a loner dude!!!!",style:TextStyle(fontSize: 17, fontWeight: FontWeight.bold,color: Colors.white)),
        )
    );
     }
 
 
  @override
  Widget build(context) {
      return Scaffold(
      backgroundColor:Colors.orange[200],
      appBar: header(context, titleText: "Home"),
      body:Container(
        padding: EdgeInsets.all(20),
        child:
          
         FutureBuilder(
      future: timeRef.document(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        else if(widget.profileId==null)
        {
          return Center(
            child: Center(child: Column(
                    children:[ circularProgress(),
                    Center(
                      child: Text(
                        "\n\nYour Homepage page is still loading.\nPlease visit another page and come back again.",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold),
                            textAlign:TextAlign.center
                      ),
                    ),]
                  ),)
          );
        }
        Fid fid = Fid.fromDocument(snapshot.data);
        if(fid.fid==null)
        {
          return Center(
            child: Center(child: Column(
                    children:[ circularProgress(),
                    Center(
                      child: Text(
                        "\n\nYour Homepage page is still loading.\nPlease visit another page and come back again.",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold),
                            textAlign:TextAlign.center
                      ),
                    ),]
                  ),)
          );
        }
  else
  {
    return  Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[ 
            
          //  Icon(Icons.people,size:250,color: Colors.black,),
            Image(image: AssetImage('images/5.png')),
            
            Padding(
              padding: EdgeInsets.only(top: 20.0),
              child:      Container(
  width: MediaQuery.of(context).size.width,
   height: 40.0,
 child: RaisedButton(
            elevation: 5.0,
            shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(30.0)),
            color: Colors.black,
            child: new Text('Show Timeline',
                style: new TextStyle(fontSize: 20.0, color: Colors.white)),
             onPressed: (){
               if(fid.fid.length>0)
          showTime(context, fid?.fid,profileId);
            else
            fun();
        },
          ),

),
            ),
          ],
        ) ;  }

      
    
      },
    ),
      

     


      ), 
    );
  }
}





