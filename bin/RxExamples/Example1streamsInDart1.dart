import 'dart:async';
import 'package:rxdart/rxdart.dart';

main(List<String> arguments) async {
  example2();
}

void example1() {
  //onNext functionality
  void observerlikeFunction(String s) {
    print(s);
  }

  //Stream Observable-"like" object
  StreamController streamController = StreamController<String>();

  //listen/Subscribe to the stream
  streamController.stream.listen((s) =>
      observerlikeFunction(s)); // .listen retrun a StreamSubscription objuct

  //push items into the stream
  streamController.add("1");
  streamController.add("2");
  streamController.add("3");

  //Which is equivalent to
  // StreamSubscription subscription = controller.stream.listen((item) => print(item)); // using a lambda function
  //streamController.add..
}

void example2() async {
/****************************************************************************** */
/******************************API implementation***************************** */
/****************************************************************************** */
  //Let's assume this is an API
  StreamController streamController = StreamController<String>();

  //at some point the API will push data into the stream ,,,the event source can add data to the controller before the user starts listening to it. To avoid data loss, the controller buffers the data until a subscriber starts listening.
  streamController.add("1");
  streamController.add("2");
  streamController.add("3");
/****************************************************************************** */

/****************************************************************************** */
/******************************App level implementation************************ */
/****************************************************************************** */
  //onNext functionality
  void onNextFunction(s) {
    print(s);
  }
  // listen/Subscribe to the API's stream
  StreamSubscription subscription = streamController.stream.listen(
      onNextFunction ); //Using tear-off, becuase onNextFunction has a dynamic paramType

  // This is to prevent the testing framework from killing this process
  // NOT PART OF THE EXAMPLE
  await Future.delayed(Duration(milliseconds: 500));

  // We can call .cancel on the subscription
  subscription.cancel();
  /******************************************************************************/

  //Later the API push some data after we've cancelled the subscription
  streamController.add("4");
  streamController.add("5");
  streamController.add("6");
}
