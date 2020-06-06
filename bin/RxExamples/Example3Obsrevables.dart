import 'dart:async';
import 'package:rxdart/rxdart.dart';

// https://www.burkharts.net/apps/blog/rxdart-magical-transformations-of-streams/

// Observables are the Rx flavour of Streams that offer more features than normal Streams.

// 1-From a Stream:  HOT OBSERVABLE
void fromStream() {
  StreamController<String> controller = new StreamController<String>();
  controller.add("a");
  controller.add("b");
  Observable<String> streamObservable = new Observable(controller.stream);
  var streamSubscription = streamObservable.listen(print);
//    output: a, b
}

// 2-Periodic events:  COLD OBSERVABLE
void periodic() {
  var timerObservable =
      Observable.periodic(Duration(seconds: 1), (x) => x.toString());
  timerObservable.listen(print);
//    output: 1, 2, 3 ....
}

// 3-From a single Value:  Observable has a factory method just
void fromSingleValue() {
  var justObservable = Observable<int>.just(42);
  justObservable.listen(print);
//    output: 42
}

// 4-From a Future
void fromFuture() {
  Future future = Future.value(42);
  var fromFutureObservable = Observable.fromFuture(future);
  fromFutureObservable.listen(print);
//    Another way to create a Stream from a Future is calling toStream() on any Future,
//    and after that create Observable from that stream
}
/****************************************************************************************** */
//        https://medium.com/@benlesh/hot-vs-cold-observables-f8094ed53339

// cold observable: COLD when your observable create the producer/produceFunction
// obs = Obervable.of(data)
// obs.listen(...)

// hot observable: HOT when your observable does not create the producer/produceFunction
// stream = controller.stream;
// obs = Observable(steam);
// obs.listen(...)
/****************************************************************************************** */

main(List<String> arguments) async {
  var obsv1 = Observable.periodic(Duration(seconds: 5), (x) => x);
  var obsv2 = obsv1.  concatMap((outerObsEvent) {
    return Observable.periodic(
        Duration(seconds: 1), (innerObsEvent) => 'innerObsEvent $innerObsEvent outerObsEvent $outerObsEvent');
  });
  obsv2.listen((f) => print(f));



}
