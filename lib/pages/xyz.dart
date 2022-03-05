import 'package:flutter/material.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:local_auth/local_auth.dart';

class YZX extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<YZX> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Next Screen Lock'),
      ),
      body: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => screenLock<void>(
            context: context,
            correctString: '1234',
            didUnlocked: () {
              Navigator.pop(context);
              NextPage.show(context);
            },
          ),
          child: const Text('Next page with unlock'),
        ),
      ),
    );
  }
}

class NextPage extends StatelessWidget {
  const NextPage({Key key}) : super(key: key);

  static show(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const NextPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Next Page'),
      ),
    );
  }
}
