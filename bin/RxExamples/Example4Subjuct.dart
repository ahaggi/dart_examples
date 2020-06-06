import 'dart:async';
import 'package:rxdart/rxdart.dart';

// https://www.burkharts.net/apps/blog/rxdart-magical-transformations-of-streams/

// Subjects are the StreamController of Rx, but it behaves a bit different than StreamControllers
// ... More than just one subscription (on a Subject) is possible and all listening parties will get the same data at the same time ...

// flavours of Subjects
//  1- PublishSubjects
//  2- BehavioutSubjects
//  3- ReplaySubjects

// 1-PublishSubjects
//   They behave like StreamControllers besides that multiple listeners are allowed
void publishSubject() {
  var subject = PublishSubject<String>();
  // Add the 1st listner
  subject.listen((str) => print(" 1st subscriber got: $str"));

  subject.add("item1");
  subject.add("item2");

  // add the 2nd listner
  subject
      .listen((str) => print(" 2nd subscriber got:***** ${str.toUpperCase()}"));

  subject.add("item3");
  subject.add("item4");
}

// 2-BehaviourSubjects
//   Every new subcriber/lateSubscribers receives the last received data item
void behaviorSubject() {
  var subject = new BehaviorSubject<String>();

  subject.listen((str) => print(" 1st subscriber got: $str"));

  subject.add("Item1");
  subject.add("Item2");

  // add the 2nd listner
  subject
      .listen((str) => print(" 2nd subscriber got:***** ${str.toUpperCase()}"));

  subject.add("Item3");
}

// 3- ReplaySubjects
// captures all of the items that have been added to the controller, and emits those as the first items to any new listener
void replaySubject() {
  final subject = new ReplaySubject<int>();

  subject.add(1);
  subject.add(2);
  subject.add(3);

  subject
      .listen((n) => print(" 1st subscriber got: 1 X $n =  ${1*n}"));

    subject
      .listen((n) => print(" 2nd subscriber got: 2 X $n =  ${2*n}"));
// prints 1, 2, 3

    subject
      .listen((n) => print(" 3rd subscriber got: 3 X $n =  ${3*n}"));
 // prints 1, 2, 3

subject.map((intValue) => intValue.toString() + "string")
    .map((strValue) => strValue.toUpperCase())
    .listen((strvalueUppercase) => print(strvalueUppercase));
 // prints 1STRING, 2STRING, 3STRING
}

main(List<String> arguments) async {
  replaySubject();
}
