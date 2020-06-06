import 'dart:async';
import 'package:rxdart/rxdart.dart';

main(List<String> arguments) async {
  StreamController handelStramCtrl = StreamController();
  handelListe.forEach((h) => handelStramCtrl.add(h));

  Observable handelObsv$ =
      Observable(handelStramCtrl.stream.asBroadcastStream());

  // handelObsv$.listen(print);
  // handelObsv$.listen(print); //StateError (Bad state: Stream has already been listened to.) TOFIX add asBroadcastStream e.i. handelObsv$ = Observable(handelStramCtrl.stream.asBroadcastStream());
  // handelObsv$.listen(print);

  StreamController produktStramCtrl = StreamController();
  produkt.forEach((p) => produktStramCtrl.add(p));

  //Important to close if this will be used inside InnerObservable which'll be flattened with "Flattening Strategies e.i. mergeMap/flarMap/exhaustMap/concatMap". concatMap for ex. does not rcv a new item from the outer observable until the innerObservable is closed/completed
  produktStramCtrl.close();



  ReplaySubject produktSubj$ = ReplaySubject();
  produkt.forEach((p) => produktSubj$.add(p));
  produktSubj$.close();

  Observable getInnerObservable({int useCase: 1}) {
    switch (useCase) {
      case 1:
        StreamController produktStramCtrl2 = StreamController();
        produkt.forEach((p) => produktStramCtrl2.add(p));

        //Important to close if this will be used as InnerObservable which'll be flattened with concatMap. concatMap does not rcv a new item from the outer observable until the innerObservable is closed/completed
        produktStramCtrl2.close();
        return Observable(produktStramCtrl2.stream.asBroadcastStream());

      case 2:
        return Observable(produktStramCtrl.stream.asBroadcastStream()); // new Observable BUT the same streamCtrl, in case of using it inside innerObservable: the 2. event/item from the outerobservable will throw exception "Stream has already been listened to" 

      case 3:
        return produktSubj$;

      default:
        break;
    }
  }

  var handelNeedToUpdate$ = handelObsv$.flatMap((handelDocSnapshot) {
    //
    print(handelDocSnapshot);
    bool needToUpdate = false;
    List varer = handelDocSnapshot["varer"];
    //istedenfor iterare gjennom alle produkter med map bruk en firstwhere bool

    return getInnerObservable(useCase: 3)
        .fold(needToUpdate, (bool needToUpdateCurrnet, produktDocSnapshot) {
          varer.forEach((v) {
            var b = v["navn"] == produktDocSnapshot["data"]["navn"] &&
                v["produktID"] != produktDocSnapshot["documentID"];

            if (b) {
              needToUpdateCurrnet = true;
              v["produktID"] = produktDocSnapshot["documentID"];
            }
          });

          return needToUpdateCurrnet;
        })
        .asObservable()
        .map((b) => b
            ? ["need to update: ", handelDocSnapshot]
            : ["OK: "            , handelDocSnapshot]);
  });

  handelNeedToUpdate$.listen(
      // value is [string , map]
      print);
}

var produkt = [
  {
    "data": {"navn": "aaa"},
    "documentID": "111"
  },
  {
    "data": {"navn": "bbb"},
    "documentID": "222"
  },
  {
    "data": {"navn": "ccc"},
    "documentID": "333"
  },
];

var handelListe = [
  {
    "varer": [
      {"navn": "aaa", "produktID": "111"},
    ]
  },
  {
    "varer": [
      {"navn": "aaa", "produktID": "234"},
      {"navn": "bbb", "produktID": "345"},
      {"navn": "ccc", "produktID": "546"},
    ]
  },
  {
    "varer": [
      {"navn": "aaa", "produktID": "111"},
      {"navn": "ccc", "produktID": "333"},
    ]
  },
  {
    "varer": [
      {"navn": "ccc", "produktID": "333"},
      {"navn": "aaa", "produktID": "111"},
    ]
  },
  {
    "varer": [
      {"navn": "bbb", "produktID": "222"},
      {"navn": "ccc", "produktID": "333"},
      {"navn": "aaa", "produktID": "123"},
    ]
  },
  {
    "varer": [
      {"navn": "bbb", "produktID": "1123"},
      {"navn": "ccc", "produktID": "333"},
    ]
  },
];
