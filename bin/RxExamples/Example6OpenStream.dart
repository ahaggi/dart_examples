import 'dart:async';
import 'package:rxdart/rxdart.dart';

// observable with an open stream
// TLDR; its like folding an infinite list
//  We need first to close the stream :
//  - If we want to make an inner observable of an observable with an open stream such that provided by
//    dartFireStore or Observable.periodic AND the InnerObservable'll be flattened with a Flattening Strategy i.e. concatMap
//    OR
//  - If we want to reduce the emitted event with "reducer" operator such as
//                  average, concat, count, max, min, reduce, sum, fold, scan

//Important to close if this will be used inside InnerObservable which'll be flattened with "Flattening Strategies i.e. mergeMap/flarMap/exhaustMap/concatMap". concatMap for ex. does not rcv a new item from the outer observable until the innerObservable is closed/completed

main(List<String> arguments) async {
flattenungWithConcatMap();
  // reduceAllEvents();


// Observable.range(4, 1)
//   .concatMap((i) =>
//     new Observable.timer(i, new Duration(seconds: i)))
//   .listen(print); // prints 4, 3, 2, 1

}




void reduceAllEvents() {
  // When flattening with concatMap, "outerObsEvent 1" will never emitts, becuase the innerObservable is NOT closed/completed
  var obsv1 = simulateFirebase(durationSec: 1)
        .take(10) //"take will act as stream.close" without closing the stream fold will not emit any value
        .fold(0, (acc, len) => acc + len)
        .asObservable();

  obsv1.listen( print );

}


void flattenungWithConcatMap() {
  // When flattening with concatMap, "outerObsEvent 1" will never emitts, becuase the innerObservable is NOT closed/completed
  var obsv1 = simulateFirebase(durationSec: 5);
  var obsv2 = obsv1.concatMap((outerObsEvent) { // change "concatMap" to "switchMap" to see the diff
    return simulateFirebase(durationSec: 1).map((innerObsEvent) =>
        'innerObsEvent $innerObsEvent outerObsEvent $outerObsEvent');
  });
  obsv2.listen( print );
}

Observable<int> simulateFirebase({int durationSec: 1}) {
  return Observable.periodic(Duration(seconds: durationSec), (x) => x);
}
