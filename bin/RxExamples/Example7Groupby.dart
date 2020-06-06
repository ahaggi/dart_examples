import 'dart:async';
import 'package:rxdart/rxdart.dart';
// observable with an open stream
// TLDR; its like folding an infinite list
//  We need first to close the stream :
//  - If we want to use an observable as an inner observable, but :
//      * that observable is an open stream such that provided by dartFireStore or Observable.periodic AND,
//      * the InnerObservable'll be flattened with a Flattening Strategy i.e. concatMap
//    OR
//  - If we want to reduce the emitted event with "reducer" operator such as
//                  average, concat, count, max, min, reduce, sum, fold, scan

main(List<String> arguments) async {

  // groupByExmp1().listen(print);
  groupByExmp2().doOnDone(()=>print("done")).listen(print).onDone(()=>print("##############"));
  // groupByExmp3().listen((map) => print(map.values.toList()[0]));
  // groupByExmp4().listen((v) => print(v));
}

Observable groupByExmp1() {
  var streamCtrl = StreamController()
    ..add(someData)
    ..close();

  var obs$ = //
      Observable(streamCtrl.stream)
          .expand((list) => list)
          .map((elem) => elem)
          .groupBy((elem) => elem["category"])
          .flatMap((group) => //
              group.map((elm) => "Category: ${group.key}  $elm"));
  return obs$;
}

Observable groupByExmp2() {
  var streamCtrl = StreamController()
    ..add(someData)
    ..close();

  var obs$ = //
      Observable(streamCtrl.stream)
          .expand((list) => list)
          .map((elem) => elem)
          .groupBy((elem) => elem["category"])
          .flatMap((group) => //
              group.fold(Map<String, dynamic>(), (acc, elm) {
                acc.update(
                    group.key, //
                    (n) => ++n,
                    ifAbsent: () => 0);
                return acc;
              }).asObservable());
  return obs$;
}

Observable groupByExmp3() {
  // grouping events without using "groupBy" operator
  var streamCtrl = StreamController()
    ..add(handelCollection)
    ..close();

  var obs$ = //
      Observable(streamCtrl.stream)
          .expand((handelList) => handelList)
          .map((handel) => {"key": handel["butikk"], "elm": handel})
          .fold(Map<String, dynamic>(), (acc, data) {
    acc.update(
        data["key"], //
        (list) => list..add(data["elm"]),
        ifAbsent: () => [data["elm"]]);
    return acc;
  }).asObservable();

  return obs$;
}

Observable groupByExmp4() {
  // grouping events without using "groupBy" operator,, But it shows how "groupBy" operator works!
  // Get total cost of goods grouped by "butikk"

  // prints {"butikk": num}
  var obs$ = //
      groupByExmp3() // Map<String,  [handelMap]>     i.e. {Kiwi: [handelMap]} :

          // List<dynamic>    i.e. [[handelMap]]
          .map((dataMap) => dataMap.values)

          // returns many events where each event is a list for en individual butikk i.e. [handelMap]
          .expand((listGroupedByButikk) => (listGroupedByButikk))

          //wrap each list in an Observable, which will be used as innerObservable
          .map((listForIndividualButikk) =>
              Observable.just(listForIndividualButikk))

          //
          .flatMap(
              (obsListForIndividualButikk) => // Observable< List<handelMap>>    i.e.Observable< [handelMap]>
                  obsListForIndividualButikk //

                      // returns many events where each event is handelMap
                      .expand((list) => list)

                      // fold all the emitted events from the prev "expand", i.e. all the handel
                      .fold(Map<String, dynamic>(), (acc, handel) {
                    num current = handel["summen"];

                    acc.update(
                        handel["butikk"], //
                        (v) => v + current,
                        ifAbsent: () => current);

                    // handel["varer"].reduce((acc, vare) => acc + vare["totalPris"]);
                    return acc;
                  }) //
                      .asObservable());
  return obs$;
}

Observable groupByExmp5() {
  // grouping events using "groupBy" operator
  // Get total cost of goods grouped by "butikk"

  // prints {"butikk": num}

  var streamCtrl = StreamController()
    ..add(handelCollection)
    ..close();

  var obs$ = //
      Observable(streamCtrl.stream)
          .expand((handelList) => handelList)
          .groupBy((handel) => handel["butikk"])
          .flatMap(//
              (group) => //
                  group
                      .fold(0, (acc, handel) {
                        return acc + handel["summen"];
                      }) //
                      .asObservable() //
                      //notice how "group.key" is available here,, Compare this with groupExmp4()
                      .map((res) => {group.key: res})); 
  return obs$;
}

var someData = [
  {"id": 1, "elem": "elm1", "category": "A"},
  {"id": 2, "elem": "elm2", "category": "B"},
  {"id": 3, "elem": "elm3", "category": "A"},
  {"id": 4, "elem": "elm4", "category": "A"},
  {"id": 5, "elem": "elm5", "category": "B"},
  {"id": 6, "elem": "elm6", "category": "A"},
];

var handelCollection = [
  {
    "kontant": 0,
    "dato": "2019-05-13",
    "bankkort": 26,
    "varer": [
      {
        "strekkode": 8690103115538,
        "mengde": 1,
        "produktID": "8690103115538",
        "totalPris": 26.0,
        "navn": "Oliven-0,5K-Tyrkisk",
        "pris": 26.0
      }
    ],
    "butikk": "Rema",
    "summen": 26.0,
    "UkeNr": 20,
    "timestamp": "Timestamp(seconds=1557860815, nanoseconds=397000000)",
    "documentID": "-LerjOO5HTSSgyE8-5XU"
  },
  {
    "kontant": 0,
    "dato": "2019-05-12",
    "bankkort": 156,
    "varer": [
      {
        "strekkode": 5710557161110,
        "mengde": 1,
        "produktID": "5710557161110",
        "totalPris": 189.0,
        "navn": "Kjøtt-MB",
        "pris": 189.0
      },
      {
        "strekkode": 101010103696,
        "mengde": 1,
        "produktID": "101010103696",
        "totalPris": 27.0,
        "navn": "Salat",
        "pris": 27.0
      },
      {
        "strekkode": 7071867100014,
        "mengde": 1,
        "produktID": "7071867100014",
        "totalPris": 15.0,
        "navn": "Brød- Midtøsten ",
        "pris": 15.0
      },
      {
        "strekkode": 101010103276,
        "mengde": 1,
        "produktID": "101010103276",
        "totalPris": 13.0,
        "navn": "Valnøtter - løsvekt",
        "pris": 13.0
      },
      {
        "strekkode": 101010109889,
        "mengde": 1,
        "produktID": "101010109889",
        "totalPris": 12.0,
        "navn": "Mandler-løsvekt",
        "pris": 12.0
      }
    ],
    "butikk": "SlettenButikk",
    "summen": 256.0,
    "UkeNr": 19,
    "timestamp": "Timestamp(seconds=1557860764, nanoseconds=608000000)",
    "documentID": "-LerjBusl1YeJz9f4uvw"
  },
  {
    "kontant": 0,
    "dato": "2019-05-11",
    "bankkort": 14.32,
    "varer": [
      {
        "strekkode": 101010102712,
        "mengde": 0.124,
        "produktID": "4KeSDukfltn25JH80ERO",
        "totalPris": 7.43,
        "navn": "Lime-løsvekt",
        "pris": 7.43
      },
      {
        "strekkode": 101010106949,
        "mengde": 0.346,
        "produktID": "X0CWKFVB2YvVGWxTIvAL",
        "totalPris": 6.89,
        "navn": "Tomater-løsvekt",
        "pris": 6.89
      }
    ],
    "butikk": "Rema",
    "summen": 14.32,
    "UkeNr": 19,
    "timestamp": "Timestamp(seconds=1557630008, nanoseconds=394000000)",
    "documentID": "-LedyvydoF_NA0Cwvsy9"
  },
  {
    "kontant": 299,
    "dato": "2019-05-10",
    "bankkort": 0,
    "varer": [
      {
        "strekkode": 7393173278752,
        "mengde": 1,
        "produktID": "7393173278752",
        "totalPris": 229.0,
        "navn": "Nettverk tester",
        "pris": 229.0
      },
      {
        "strekkode": 606449098761,
        "mengde": 1,
        "produktID": "606449098761",
        "totalPris": 299.0,
        "navn": "Wi-Fi USB adapter",
        "pris": 299.0
      },
      {
        "strekkode": 101010102675,
        "mengde": 1,
        "produktID": "101010102675",
        "totalPris": -229.0,
        "navn": "Retur",
        "pris": -229.0
      }
    ],
    "butikk": "Clas Ohlson",
    "summen": 299.0,
    "UkeNr": 19,
    "timestamp": "Timestamp(seconds=1557629976, nanoseconds=0)",
    "documentID": "-Lee-YMwnl7j4uZyZMgC"
  },
  {
    "kontant": 343,
    "dato": "2019-05-10",
    "bankkort": 0,
    "varer": [
      {
        "strekkode": 7072175104930,
        "mengde": 1,
        "produktID": "7072175104930",
        "totalPris": 227.3,
        "navn": "Kylling-ytterøy-Lårbiff",
        "pris": 227.3
      },
      {
        "strekkode": 101010101906,
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": 0.2,
        "navn": "avrunding",
        "pris": 0.2
      },
      {
        "strekkode": 7050122131611,
        "mengde": 2,
        "produktID": "7050122131611",
        "totalPris": 30.8,
        "navn": "Dipmix Garlic",
        "pris": 15.4
      },
      {
        "strekkode": 7050122131574,
        "mengde": 2,
        "produktID": "7050122131574",
        "totalPris": 13.5,
        "navn": "Dipmix holiday",
        "pris": 6.75
      },
      {
        "strekkode": 7025110160478,
        "mengde": 1,
        "produktID": "7025110160478",
        "totalPris": 71.2,
        "navn": "Røkt laks - Xtra",
        "pris": 71.2
      }
    ],
    "butikk": "Obs",
    "summen": 343.0,
    "UkeNr": 19,
    "timestamp": "Timestamp(seconds=1557629916, nanoseconds=845000000)",
    "documentID": "-Ledy__quYDCqPqiD2eK"
  },
  {
    "kontant": 97,
    "dato": "2019-05-09",
    "bankkort": 0,
    "varer": [
      {
        "strekkode": 7038010052422,
        "mengde": 1,
        "produktID": "7038010052422",
        "totalPris": 32.9,
        "navn": "Melk-stor-Hel-Tine",
        "pris": 32.9
      },
      {
        "strekkode": 7038010062735,
        "mengde": 1,
        "produktID": "7038010062735",
        "totalPris": 32.9,
        "navn": "Yoghurt-0.85K-Mango",
        "pris": 32.9
      },
      {
        "strekkode": 7046110002094,
        "mengde": 1,
        "produktID": "7046110002094",
        "totalPris": 28.8,
        "navn": "Zalo oppvaskmiddel ",
        "pris": 28.8
      },
      {
        "strekkode": 101010106949,
        "mengde": 1,
        "produktID": "X0CWKFVB2YvVGWxTIvAL",
        "totalPris": 2.87,
        "navn": "Tomater-løsvekt",
        "pris": 2.87
      },
      {
        "strekkode": 101010101906,
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": -0.47,
        "navn": "avrunding",
        "pris": -0.47
      }
    ],
    "butikk": "Rema",
    "summen": 97.0,
    "UkeNr": 19,
    "timestamp": "Timestamp(seconds=1557629431, nanoseconds=287000000)",
    "documentID": "-Ledwj4224pOMgyaSdgy"
  },
  {
    "kontant": 11,
    "dato": "2019-05-08",
    "bankkort": 217,
    "varer": [
      {
        "strekkode": 7032069722152,
        "mengde": 3,
        "produktID": "7032069722152",
        "totalPris": 18,
        "navn": "Sjampinjong-prima",
        "pris": 6
      },
      {
        "strekkode": 7038010004858,
        "mengde": 1,
        "produktID": "7038010004858",
        "totalPris": 20.9,
        "navn": "Rømme-sete0,35",
        "pris": 20.9
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 101010102019,
        "mengde": 0.5,
        "produktID": "SJeGJDQlCAX7XmUe4q1M",
        "totalPris": 19.9,
        "navn": "Løk-løsvekt",
        "pris": 19.9
      },
      {
        "strekkode": 101010104525,
        "mengde": 5,
        "produktID": "101010104525",
        "totalPris": 24.9,
        "navn": "hvitløk-1stk",
        "pris": 4.98
      },
      {
        "strekkode": 101010107205,
        "mengde": 3,
        "produktID": "C5skXrcuIoBbh1czly9n",
        "totalPris": 34.9,
        "navn": "Paprika-1stk",
        "pris": 11.63
      },
      {
        "strekkode": 7311250083976,
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 92,
        "navn": "Snus G4",
        "pris": 92
      }
    ],
    "butikk": "Rema",
    "summen": 228.5,
    "UkeNr": 19,
    "timestamp": "Timestamp(seconds=1557629042, nanoseconds=49000000)",
    "documentID": "-LedvEyu0Xwqb21XpYL1"
  },
  {
    "kontant": 2,
    "dato": "2019-05-07",
    "bankkort": 203.08,
    "varer": [
      {
        "strekkode": 2302148200006,
        "mengde": 1,
        "produktID": "2302148200006",
        "totalPris": 112.46,
        "navn": "Norvegia-1K",
        "pris": 112.46
      },
      {
        "strekkode": 2302436905026,
        "mengde": 1,
        "produktID": "2302436905026",
        "totalPris": 92.62,
        "navn": "Ost Jarlsberg-0,5K",
        "pris": 92.62
      }
    ],
    "butikk": "Bunnpris",
    "summen": 205.08,
    "UkeNr": 19,
    "timestamp": "Timestamp(seconds=1557628077, nanoseconds=177000000)",
    "documentID": "-LedrZSNu8Pyt0HLbXPD"
  },
  {
    "kontant": 0,
    "dato": "2019-05-06",
    "bankkort": 15,
    "varer": [
      {
        "strekkode": 7071867100014,
        "mengde": 1,
        "produktID": "7071867100014",
        "totalPris": 15.0,
        "navn": "Brød- Midtøsten ",
        "pris": 15.0
      }
    ],
    "butikk": "SlettenButikk",
    "summen": 15.0,
    "UkeNr": 19,
    "timestamp": "Timestamp(seconds=1557627826, nanoseconds=905000000)",
    "documentID": "-LedqbLHOC_JLSR6HhwI"
  },
  {
    "kontant": 93,
    "dato": "2019-05-06",
    "bankkort": 0,
    "varer": [
      {
        "strekkode": 5031020038761,
        "mengde": 1,
        "produktID": "5031020038761",
        "totalPris": 41.6,
        "navn": "Røkt laks - FirstPrice",
        "pris": 41.6
      },
      {
        "strekkode": 7045010003156,
        "mengde": 1,
        "produktID": "7045010003156",
        "totalPris": 21.9,
        "navn": "Krydder - kyllingkrydder",
        "pris": 21.9
      },
      {
        "strekkode": 7045010003699,
        "mengde": 1,
        "produktID": "7045010003699",
        "totalPris": 29.9,
        "navn": "Krydder PepperMix",
        "pris": 29.9
      },
      {
        "strekkode": 101010101906,
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": -0.4,
        "navn": "avrunding",
        "pris": -0.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 93.0,
    "UkeNr": 19,
    "timestamp": "Timestamp(seconds=1557618363, nanoseconds=729000000)",
    "documentID": "-LedHVvPEn42TTQB2FnD"
  },
  {
    "kontant": 75,
    "dato": "2019-05-05",
    "bankkort": 0,
    "varer": [
      {
        "strekkode": 101010101265,
        "mengde": 0.05,
        "produktID": "101010101265",
        "totalPris": 0,
        "navn": "Paprika-chili-løsvekt",
        "pris": 0
      },
      {
        "strekkode": 101010106949,
        "mengde": 0.2,
        "produktID": "X0CWKFVB2YvVGWxTIvAL",
        "totalPris": 0,
        "navn": "Tomater-løsvekt",
        "pris": 0
      },
      {
        "strekkode": 101010109889,
        "mengde": 0.2,
        "produktID": "101010109889",
        "totalPris": 0,
        "navn": "Mandler-løsvekt",
        "pris": 0
      },
      {
        "strekkode": 101010103696,
        "mengde": 0.4,
        "produktID": "101010103696",
        "totalPris": 0,
        "navn": "Salat",
        "pris": 0
      },
      {
        "strekkode": 101010106895,
        "mengde": 1,
        "produktID": "3PJMLKsAi7fp6oUIvwcU",
        "totalPris": 75,
        "navn": "ukjent",
        "pris": 75
      }
    ],
    "butikk": "SlettenButikk",
    "summen": 75.0,
    "UkeNr": 18,
    "timestamp": "Timestamp(seconds=1557616977, nanoseconds=686000000)",
    "documentID": "-LedCDYJqYp3l2VHEnjF"
  },
  {
    "kontant": 279,
    "dato": "2019-05-03",
    "bankkort": 0,
    "varer": [
      {
        "strekkode": 101010108189,
        "mengde": 2,
        "produktID": "101010108189",
        "totalPris": 558.0,
        "navn": "Vifte- Gulv-ogBordvifte",
        "pris": 279.0
      },
      {
        "strekkode": 101010102675,
        "mengde": 1,
        "produktID": "101010102675",
        "totalPris": -279.0,
        "navn": "Retur",
        "pris": -279.0
      }
    ],
    "butikk": "Clas Ohlson",
    "summen": 279.0,
    "UkeNr": 18,
    "timestamp": "Timestamp(seconds=1557615900, nanoseconds=673000000)",
    "documentID": "-Led86a8ypsqjyp1GXRQ"
  },
  {
    "kontant": 0,
    "dato": "2019-05-03",
    "bankkort": 279,
    "varer": [
      {
        "strekkode": 101010108189,
        "mengde": 1,
        "produktID": "101010108189",
        "totalPris": 279.0,
        "navn": "Vifte- Gulv-ogBordvifte",
        "pris": 279.0
      }
    ],
    "butikk": "Clas Ohlson",
    "summen": 279.0,
    "UkeNr": 18,
    "timestamp": "Timestamp(seconds=1557615834, nanoseconds=281000000)",
    "documentID": "-Led7rQALUFFHpZZiujs"
  },
  {
    "kontant": 154,
    "dato": "2019-05-03",
    "bankkort": 0,
    "varer": [
      {
        "strekkode": 7050122131611,
        "mengde": 1,
        "produktID": "7050122131611",
        "totalPris": 12.9,
        "navn": "Dipmix",
        "pris": 12.9
      },
      {
        "strekkode": 7038010004858,
        "mengde": 1,
        "produktID": "7038010004858",
        "totalPris": 20.9,
        "navn": "Rømme-sete0,35",
        "pris": 20.9
      },
      {
        "strekkode": 7311041029299,
        "mengde": 1,
        "produktID": "7311041029299",
        "totalPris": 12.2,
        "navn": "Pesto grønn- Eldorado",
        "pris": 12.2
      },
      {
        "strekkode": 7032069722152,
        "mengde": 3,
        "produktID": "7032069722152",
        "totalPris": 18,
        "navn": "Sjampinjong-prima",
        "pris": 6
      },
      {
        "strekkode": 101010104525,
        "mengde": 3,
        "produktID": "101010104525",
        "totalPris": 9.9,
        "navn": "hvitløk-1stk",
        "pris": 3.3
      },
      {
        "strekkode": 101010102019,
        "mengde": 0.5,
        "produktID": "SJeGJDQlCAX7XmUe4q1M",
        "totalPris": 19.9,
        "navn": "Løk-løsvekt",
        "pris": 19.9
      },
      {
        "strekkode": 7090026220592,
        "mengde": 1,
        "produktID": "7090026220592",
        "totalPris": 59.9,
        "navn": "Egg-24",
        "pris": 59.9
      },
      {
        "strekkode": 101010101906,
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": 0.3,
        "navn": "avrunding",
        "pris": 0.3
      }
    ],
    "butikk": "Rema",
    "summen": 154.0,
    "UkeNr": 18
  },
  {
    "kontant": -75.5,
    "dato": "2019-05-06",
    "bankkort": 0,
    "varer": [
      {
        "strekkode": 101010102675,
        "mengde": 1,
        "produktID": "101010102675",
        "totalPris": -75.5,
        "navn": "Retur",
        "pris": -75.5
      }
    ],
    "butikk": "Bunnpris",
    "summen": -75.5,
    "UkeNr": 19,
    "timestamp": "Timestamp(seconds=1557615202, nanoseconds=677000000)",
    "documentID": "-Led5SFT7svXJ_JJl5hZ"
  },
  {
    "kontant": 200,
    "dato": "2019-05-02",
    "bankkort": 10.6,
    "varer": [
      {
        "strekkode": 7311041013441,
        "mengde": 1,
        "produktID": "7311041013441",
        "totalPris": 19.9,
        "navn": "MusliCrunchy-FirstPrice",
        "pris": 19.9
      },
      {
        "strekkode": 7048840000012,
        "mengde": 1,
        "produktID": "7048840000012",
        "totalPris": 18.9,
        "navn": "Melk-1L-Hel-Q",
        "pris": 18.9
      },
      {
        "strekkode": 7038010055669,
        "mengde": 1,
        "produktID": "7038010055669",
        "totalPris": 16.9,
        "navn": "Yoghurt-0,5K-Melon",
        "pris": 16.9
      },
      {
        "strekkode": 101010108356,
        "mengde": 1,
        "produktID": "101010108356",
        "totalPris": 59.5,
        "navn": "Batteri-U9VL",
        "pris": 59.5
      },
      {
        "strekkode": 111111,
        "mengde": 1,
        "produktID": "8fvqwGgaKFo8nzLPybC5",
        "totalPris": 75.5,
        "navn": "Barber blade",
        "pris": 75.5
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 19.9,
        "navn": "KulturMelk",
        "pris": 19.9
      }
    ],
    "butikk": "Bunnpris",
    "summen": 210.6,
    "UkeNr": 18,
    "timestamp": "Timestamp(seconds=1557615098, nanoseconds=842000000)",
    "documentID": "-Led52rZfabRZQjKd4SF"
  },
  {
    "kontant": 17,
    "dato": "2019-05-02",
    "bankkort": 0,
    "varer": [
      {
        "strekkode": 7029161117139,
        "mengde": 1,
        "produktID": "7029161117139",
        "totalPris": 16.9,
        "navn": "Brød- GRØVT&GODT",
        "pris": 16.9
      },
      {
        "strekkode": 101010101906,
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": 0.1,
        "navn": "avrunding",
        "pris": 0.1
      }
    ],
    "butikk": "Rema",
    "summen": 17.0,
    "UkeNr": 18,
    "timestamp": "Timestamp(seconds=1557614728, nanoseconds=76000000)",
    "documentID": "-Led3dLMSYKyX7_B7qpU"
  },
  {
    "kontant": 279,
    "dato": "2019-05-01",
    "bankkort": 0,
    "varer": [
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 101010103467,
        "mengde": 1,
        "produktID": "101010103467",
        "totalPris": 31.2,
        "navn": "Brød-bondebrød",
        "pris": 31.2
      },
      {
        "strekkode": 7038010055690,
        "mengde": 2,
        "produktID": "7038010055690",
        "totalPris": 35.8,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 17.9
      },
      {
        "strekkode": 7048840000012,
        "mengde": 1,
        "produktID": "7048840000012",
        "totalPris": 18.9,
        "navn": "Melk-1L-Hel-Q",
        "pris": 18.9
      },
      {
        "strekkode": 7311250083976,
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 92.0,
        "navn": "Snus G4",
        "pris": 92.0
      },
      {
        "strekkode": 7311250013355,
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 101.0,
        "navn": "Snus General",
        "pris": 101.0
      },
      {
        "strekkode": 101010101333,
        "mengde": 1,
        "produktID": "101010101333",
        "totalPris": -17.9,
        "navn": "tilbud",
        "pris": -17.9
      },
      {
        "strekkode": 101010101906,
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": 0.1,
        "navn": "avrunding",
        "pris": 0.1
      }
    ],
    "butikk": "Rema",
    "summen": 279.0,
    "UkeNr": 18,
  },
  {
    "kontant": 0,
    "dato": "2019-04-29",
    "bankkort": 301.1,
    "varer": [
      {
        "strekkode": 101010104761,
        "mengde": 1,
        "produktID": "101010104761",
        "totalPris": 74.9,
        "navn": "Sokker-5stykker",
        "pris": 74.9
      },
      {
        "strekkode": 7314571151003,
        "mengde": 2,
        "produktID": "7314571151003",
        "totalPris": 47.2,
        "navn": "Shampoo-Sport",
        "pris": 23.6
      },
      {
        "strekkode": 101010108738,
        "mengde": 1,
        "produktID": "101010108738",
        "totalPris": 179.0,
        "navn": "Kylling-Ytterøy-Kyllingfilet",
        "pris": 179.0
      }
    ],
    "butikk": "Obs",
    "summen": 301.1,
    "UkeNr": 18,
    "timestamp": "Timestamp(seconds=1557611818, nanoseconds=19000000)",
    "documentID": "-LectXuIZmZWeIYZm-cT"
  },
  {
    "kontant": 0,
    "dato": "2019-04-29",
    "bankkort": 229,
    "varer": [
      {
        "strekkode": 7393173278752,
        "mengde": 1,
        "produktID": "7393173278752",
        "totalPris": 229.0,
        "navn": "Nettverk tester",
        "pris": 229.0
      }
    ],
    "butikk": "Clas Ohlson",
    "summen": 229.0,
    "UkeNr": 18,
    "timestamp": "Timestamp(seconds=1557611458, nanoseconds=0)",
    "documentID": "-Lee0_gipr926URN7Wd8"
  },
  {
    "kontant": 0,
    "dato": "2019-04-29",
    "bankkort": 219,
    "varer": [
      {
        "strekkode": 7070646283320,
        "mengde": 1,
        "produktID": "gYPJMZvTE1ZMDq2uC3wc",
        "totalPris": 219.0,
        "navn": "Whey Protein-1K-PF",
        "pris": 219.0
      }
    ],
    "butikk": "XXL",
    "summen": 219.0,
    "UkeNr": 18,
    "timestamp": "Timestamp(seconds=1557609780, nanoseconds=405000000)",
    "documentID": "-LecllO3iaYQZzc0TkCx"
  },
  {
    "kontant": 0,
    "dato": "2019-04-27",
    "bankkort": 32,
    "varer": [
      {
        "strekkode": 7032069722152,
        "mengde": 2,
        "produktID": "7032069722152",
        "totalPris": 12.0,
        "navn": "Sjampinjong-prima",
        "pris": 6.0
      },
      {
        "strekkode": 7020655860043,
        "mengde": 1,
        "produktID": "7020655860043",
        "totalPris": 20.0,
        "navn": "Brød-SPLEISE",
        "pris": 20.0
      }
    ],
    "butikk": "Rema",
    "summen": 32.0,
    "UkeNr": 17,
    "timestamp": "Timestamp(seconds=1557609760, nanoseconds=0)",
    "documentID": "-LecsmbS2N6c4DCHLzlH"
  },
  {
    "kontant": 0,
    "dato": "2019-04-27",
    "bankkort": 53,
    "varer": [
      {
        "strekkode": 8690103115538,
        "mengde": 1,
        "produktID": "8690103115538",
        "totalPris": 35.0,
        "navn": "Oliven-0,5K-Tyrkisk",
        "pris": 35.0
      },
      {
        "strekkode": 101010106895,
        "mengde": 1,
        "produktID": "3PJMLKsAi7fp6oUIvwcU",
        "totalPris": 18.0,
        "navn": "ukjent",
        "pris": 18.0
      }
    ],
    "butikk": "SlettenButikk",
    "summen": 53.0,
    "UkeNr": 17,
    "timestamp": "Timestamp(seconds=1557609694, nanoseconds=591000000)",
    "documentID": "-LeclRS5gMnMD7zBz0TV"
  },
  {
    "kontant": 0,
    "dato": "2019-04-26",
    "bankkort": 175.2,
    "varer": [
      {
        "strekkode": 7038010055683,
        "mengde": 1,
        "produktID": "7038010055683",
        "totalPris": 17.9,
        "navn": "Yoghurt-0,5K-jordbær",
        "pris": 17.9
      },
      {
        "strekkode": 7038010055669,
        "mengde": 1,
        "produktID": "7038010055669",
        "totalPris": 17.4,
        "navn": "Yoghurt-0,5K-Melon",
        "pris": 17.4
      },
      {
        "strekkode": 101010108318,
        "mengde": 1,
        "produktID": "101010108318",
        "totalPris": 10.0,
        "navn": "spaghetti-0.5k",
        "pris": 10.0
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 7020655860043,
        "mengde": 2,
        "produktID": "7020655860043",
        "totalPris": 40.0,
        "navn": "Brød-SPLEISE",
        "pris": 20.0
      },
      {
        "strekkode": 101010101333,
        "mengde": 1,
        "produktID": "101010101333",
        "totalPris": -20.0,
        "navn": "tilbud",
        "pris": -20.0
      },
      {
        "strekkode": 7311250083976,
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 92.0,
        "navn": "Snus G4",
        "pris": 92.0
      }
    ],
    "butikk": "Rema",
    "summen": 175.2,
    "UkeNr": 17,
    "timestamp": "Timestamp(seconds=1557609124, nanoseconds=65000000)",
    "documentID": "-LecjG9vVhL7Yk0DDpo0"
  },
  {
    "kontant": 0,
    "dato": "2019-04-23",
    "bankkort": 250,
    "varer": [
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 7038010000911,
        "mengde": 1,
        "produktID": "7038010000911",
        "totalPris": 26.7,
        "navn": "Melk-stor-0,5-Tine",
        "pris": 26.7
      },
      {
        "strekkode": 7032069715253,
        "mengde": 1,
        "produktID": "7032069715253",
        "totalPris": 19.9,
        "navn": "MusliCrunchy-Rema1000",
        "pris": 19.9
      },
      {
        "strekkode": 7038010053368,
        "mengde": 1,
        "produktID": "7038010053368",
        "totalPris": 91.3,
        "navn": "Ost Jarlsbergost 0,7 kg",
        "pris": 91.3
      },
      {
        "strekkode": 7038010055669,
        "mengde": 1,
        "produktID": "7038010055669",
        "totalPris": 17.4,
        "navn": "Yoghurt-0,5K-Melon",
        "pris": 17.4
      },
      {
        "strekkode": 7029161117139,
        "mengde": 1,
        "produktID": "7029161117139",
        "totalPris": 16.9,
        "navn": "Brød- GRØVT&GODT",
        "pris": 16.9
      },
      {
        "strekkode": 7090026220592,
        "mengde": 1,
        "produktID": "7090026220592",
        "totalPris": 59.9,
        "navn": "Egg-24",
        "pris": 59.9
      }
    ],
    "butikk": "Rema",
    "summen": 250.0,
    "UkeNr": 17,
    "timestamp": "Timestamp(seconds=1557602248, nanoseconds=879000000)",
    "documentID": "-LecK1cDTBt-Y0SU2eBz"
  },
  {
    "kontant": 0,
    "dato": "2019-04-23",
    "bankkort": 119.7,
    "varer": [
      {
        "strekkode": 7311041019757,
        "mengde": 7,
        "produktID": "7311041019757",
        "totalPris": 93.8,
        "navn": "Formaggio",
        "pris": 13.4
      },
      {
        "strekkode": 1111,
        "mengde": 1,
        "produktID": "4EHpBRhZKxqMdg1jHwvB",
        "totalPris": 25.9,
        "navn": "Tøyvask",
        "pris": 25.9
      }
    ],
    "butikk": "Bunnpris",
    "summen": 119.7,
    "UkeNr": 17,
    "timestamp": "Timestamp(seconds=1557601386, nanoseconds=847000000)",
    "documentID": "-LecGk9ro5DbyqgG5Q9O"
  },
  {
    "kontant": 0,
    "dato": "2019-04-22",
    "bankkort": 118,
    "varer": [
      {
        "strekkode": 7311250013355,
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 118.0,
        "navn": "Snus General",
        "pris": 118.0
      }
    ],
    "butikk": "CircleK",
    "summen": 118.0,
    "UkeNr": 17,
    "timestamp": "Timestamp(seconds=1557601154, nanoseconds=805000000)",
    "documentID": "-LecFrWG46aKVn2pOFLd"
  },
  {
    "kontant": 0,
    "dato": "2019-04-20",
    "bankkort": 104,
    "varer": [
      {
        "strekkode": 7311250083976,
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 104.0,
        "navn": "Snus G4",
        "pris": 104.0
      }
    ],
    "butikk": "Esso",
    "summen": 104.0,
    "UkeNr": 16,
    "timestamp": "Timestamp(seconds=1557600957, nanoseconds=720000000)",
    "documentID": "-LecF6PJC-6DgBIp3H8r"
  },
  {
    "kontant": 0,
    "dato": "2019-04-19",
    "bankkort": 87.5,
    "varer": [
      {
        "strekkode": 7032069715253,
        "mengde": 1,
        "produktID": "7032069715253",
        "totalPris": 19.9,
        "navn": "MusliCrunchy-Rema1000",
        "pris": 19.9
      },
      {
        "strekkode": 7311040640228,
        "mengde": 1,
        "produktID": "7311040640228",
        "totalPris": 14.9,
        "navn": "Oliven-0,34K-sorte",
        "pris": 14.9
      },
      {
        "strekkode": 7311041029299,
        "mengde": 1,
        "produktID": "7311041029299",
        "totalPris": 12.5,
        "navn": "Pesto grønn- Eldorado",
        "pris": 12.5
      },
      {
        "strekkode": 7311041019757,
        "mengde": 3,
        "produktID": "7311041019757",
        "totalPris": 40.2,
        "navn": "Formaggio",
        "pris": 13.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 87.5,
    "UkeNr": 16,
    "timestamp": "Timestamp(seconds=1557600791, nanoseconds=823000000)",
    "documentID": "-LecETtXebQKUvtenYqn"
  },
  {
    "kontant": 0,
    "dato": "2019-04-19",
    "bankkort": 51.4,
    "varer": [
      {
        "strekkode": 7029161117139,
        "mengde": 1,
        "produktID": "7029161117139",
        "totalPris": 33.5,
        "navn": "Brød- GRØVT&GODT",
        "pris": 33.5
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      }
    ],
    "butikk": "Rema",
    "summen": 51.4,
    "UkeNr": 16,
    "timestamp": "Timestamp(seconds=1557600636, nanoseconds=624000000)",
    "documentID": "-LecDt1p1bCB0YVT_oMF"
  },
  {
    "kontant": 0,
    "dato": "2019-04-15",
    "bankkort": 93.9,
    "varer": [
      {
        "strekkode": 7311250083976,
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 93.9,
        "navn": "Snus G4",
        "pris": 93.9
      }
    ],
    "butikk": "Bunnpris",
    "summen": 93.9,
    "UkeNr": 16,
    "timestamp": "Timestamp(seconds=1557600568, nanoseconds=299000000)",
    "documentID": "-LecDcNMkqXQfcp-IEWw"
  },
  {
    "kontant": 0,
    "dato": "2019-04-15",
    "bankkort": 75.3,
    "varer": [
      {
        "strekkode": 7311041019757,
        "mengde": 3,
        "produktID": "7311041019757",
        "totalPris": 40.2,
        "navn": "Formaggio",
        "pris": 13.4
      },
      {
        "strekkode": 7311041029299,
        "mengde": 1,
        "produktID": "7311041029299",
        "totalPris": 12.5,
        "navn": "Pesto grønn- Eldorado",
        "pris": 12.5
      },
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 22.6,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 22.6
      }
    ],
    "butikk": "Bunnpris",
    "summen": 75.3,
    "UkeNr": 16,
    "timestamp": "Timestamp(seconds=1557600512, nanoseconds=998000000)",
    "documentID": "-LecDPp80aN9ZIdNKpaz"
  },
  {
    "kontant": 0,
    "dato": "2019-04-13",
    "bankkort": 75.3,
    "varer": [
      {
        "strekkode": 101010103238,
        "mengde": 1,
        "produktID": "101010103238",
        "totalPris": 29.9,
        "navn": "Jif- WC",
        "pris": 29.9
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 7029161121488,
        "mengde": 1,
        "produktID": "7029161121488",
        "totalPris": 27.5,
        "navn": "Brød-Jubileums",
        "pris": 27.5
      }
    ],
    "butikk": "Rema",
    "summen": 75.3,
    "UkeNr": 15,
    "timestamp": "Timestamp(seconds=1557600334, nanoseconds=355000000)",
    "documentID": "-LecCjCLtnYNwCWKiZgP"
  },
  {
    "kontant": 0,
    "dato": "2019-04-12",
    "bankkort": 39.9,
    "varer": [
      {
        "strekkode": 1111,
        "mengde": 1,
        "produktID": "42eQ7LRuiS2M4qiPNyYt",
        "totalPris": 39.9,
        "navn": "Tørkeruller",
        "pris": 39.9
      }
    ],
    "butikk": "CoopExtra",
    "summen": 39.9,
    "UkeNr": 15,
    "timestamp": "Timestamp(seconds=1557600257, nanoseconds=364000000)",
    "documentID": "-LecCRNgJdZDzs2xYoZ-"
  },
  {
    "kontant": 0,
    "dato": "2019-04-11",
    "bankkort": 20.3,
    "varer": [
      {
        "strekkode": 101010106895,
        "mengde": 1,
        "produktID": "3PJMLKsAi7fp6oUIvwcU",
        "totalPris": -92.0,
        "navn": "ukjent",
        "pris": -92.0
      },
      {
        "strekkode": 7311250013355,
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 112.3,
        "navn": "Snus General",
        "pris": 112.3
      }
    ],
    "butikk": "Rema",
    "summen": 20.3,
    "UkeNr": 15,
    "timestamp": "Timestamp(seconds=1557599615, nanoseconds=418000000)",
    "documentID": "-Lec9zg8YdbnIeotZ1pb"
  },
  {
    "kontant": 0,
    "dato": "2019-04-11",
    "bankkort": 157.3,
    "varer": [
      {
        "strekkode": 101010106895,
        "mengde": 1,
        "produktID": "3PJMLKsAi7fp6oUIvwcU",
        "totalPris": 157.3,
        "navn": "ukjent",
        "pris": 157.3
      }
    ],
    "butikk": "Rema",
    "summen": 157.3,
    "UkeNr": 15,
    "timestamp": "Timestamp(seconds=1557599451, nanoseconds=80000000)",
    "documentID": "-Lec9MTMYDHxo8RtDGw7"
  },
  {
    "kontant": 0,
    "dato": "2019-04-09",
    "bankkort": 126.8,
    "varer": [
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 7029161117139,
        "mengde": 1,
        "produktID": "7029161117139",
        "totalPris": 16.9,
        "navn": "Brød- GRØVT&GODT",
        "pris": 16.9
      },
      {
        "strekkode": 7311250083976,
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 92.0,
        "navn": "Snus G4",
        "pris": 92.0
      }
    ],
    "butikk": "Rema",
    "summen": 126.8,
    "UkeNr": 15,
    "timestamp": "Timestamp(seconds=1557598706, nanoseconds=623000000)",
    "documentID": "-Lec6Wpnk3K2T2ed6ewH"
  },
  {
    "kontant": 0,
    "dato": "2019-04-09",
    "bankkort": 19.9,
    "varer": [
      {
        "strekkode": 101010102019,
        "mengde": 0.5,
        "produktID": "SJeGJDQlCAX7XmUe4q1M",
        "totalPris": 19.9,
        "navn": "Løk-løsvekt",
        "pris": 19.9
      }
    ],
    "butikk": "Rema",
    "summen": 19.9,
    "UkeNr": 15,
    "timestamp": "Timestamp(seconds=1557598593, nanoseconds=640000000)",
    "documentID": "-Lec65BEHXfrg1Aho6Pf"
  },
  {
    "kontant": 0,
    "dato": "2019-04-08",
    "bankkort": 223.2,
    "varer": [
      {
        "strekkode": 8712561851084,
        "mengde": 1,
        "produktID": "8712561851084",
        "totalPris": 142.9,
        "navn": "Sun - oppvaskmiddel ",
        "pris": 142.9
      },
      {
        "strekkode": 1111,
        "mengde": 5,
        "produktID": "47qUtl1CUHq6p73TfVQP",
        "totalPris": 42.5,
        "navn": "Handsåpe",
        "pris": 8.5
      },
      {
        "strekkode": 7032069715253,
        "mengde": 1,
        "produktID": "7032069715253",
        "totalPris": 19.9,
        "navn": "MusliCrunchy-Rema1000",
        "pris": 19.9
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      }
    ],
    "butikk": "Rema",
    "summen": 223.2,
    "UkeNr": 15,
    "timestamp": "Timestamp(seconds=1557548470, nanoseconds=286000000)",
    "documentID": "-Le_6t-chBTYYKp8zCpl"
  },
  {
    "kontant": 0,
    "dato": "2019-04-06",
    "bankkort": 93.8,
    "varer": [
      {
        "strekkode": 7311041019757,
        "mengde": 7,
        "produktID": "7311041019757",
        "totalPris": 93.8,
        "navn": "Formaggio",
        "pris": 13.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 93.8,
    "UkeNr": 14,
    "timestamp": "Timestamp(seconds=1557548205, nanoseconds=278000000)",
    "documentID": "-Le_5sJoJ7WLgSNoVUkr"
  },
  {
    "kontant": 0,
    "dato": "2019-04-06",
    "bankkort": 174.62,
    "varer": [
      {
        "strekkode": 7035620004346,
        "mengde": 1,
        "produktID": "7035620004346",
        "totalPris": 12.2,
        "navn": "Pesto rød- Eldorado",
        "pris": 12.2
      },
      {
        "strekkode": 7038010024375,
        "mengde": 1,
        "produktID": "7038010024375",
        "totalPris": 101.12,
        "navn": "Norvegia-1K-flydig",
        "pris": 101.12
      },
      {
        "strekkode": 7029161124687,
        "mengde": 1,
        "produktID": "7029161124687",
        "totalPris": 17.5,
        "navn": "Brød-KNEIPP-PRIMA",
        "pris": 17.5
      },
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 17.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 17.9
      },
      {
        "strekkode": 7048840081950,
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 25.9,
        "navn": "Melk-stor-0,5-Q",
        "pris": 25.9
      }
    ],
    "butikk": "Rema",
    "summen": 174.62,
    "UkeNr": 14,
    "timestamp": "Timestamp(seconds=1557548154, nanoseconds=701000000)",
    "documentID": "-Le_5fvXKw_dCJH8XTOa"
  },
  {
    "kontant": 0,
    "dato": "2019-04-04",
    "bankkort": 59.6,
    "varer": [
      {
        "strekkode": 1111,
        "mengde": 1,
        "produktID": "h7mi21cM59LmbSoppzZw",
        "totalPris": 59.6,
        "navn": "Toalettpapir",
        "pris": 59.6
      }
    ],
    "butikk": "Bunnpris",
    "summen": 59.6,
    "UkeNr": 14,
    "timestamp": "Timestamp(seconds=1557548022, nanoseconds=492000000)",
    "documentID": "-Le_5Aj5VDPsSJ_f-1Ug"
  },
  {
    "kontant": 0,
    "dato": "2019-04-04",
    "bankkort": 143.4,
    "varer": [
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 7029161117139,
        "mengde": 1,
        "produktID": "7029161117139",
        "totalPris": 33.5,
        "navn": "Brød- GRØVT&GODT",
        "pris": 33.5
      },
      {
        "strekkode": 7311250083976,
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 92.0,
        "navn": "Snus G4",
        "pris": 92.0
      }
    ],
    "butikk": "Rema",
    "summen": 143.4,
    "UkeNr": 14,
    "timestamp": "Timestamp(seconds=1557547963, nanoseconds=431000000)",
    "documentID": "-Le_4xEPtfiNfcwxqT9W"
  },
  {
    "kontant": 50,
    "dato": "2019-04-02",
    "bankkort": 221.9,
    "varer": [
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 7048840081950,
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 25.9,
        "navn": "Melk-stor-0,5-Q",
        "pris": 25.9
      },
      {
        "strekkode": 7032069715253,
        "mengde": 1,
        "produktID": "7032069715253",
        "totalPris": 19.9,
        "navn": "MusliCrunchy-Rema1000",
        "pris": 19.9
      },
      {
        "strekkode": 7090026220592,
        "mengde": 1,
        "produktID": "7090026220592",
        "totalPris": 59.9,
        "navn": "Egg-24",
        "pris": 59.9
      },
      {
        "strekkode": 7020655860043,
        "mengde": 1,
        "produktID": "7020655860043",
        "totalPris": 24.0,
        "navn": "Brød-SPLEISE",
        "pris": 24.0
      },
      {
        "strekkode": 7032069722152,
        "mengde": 2,
        "produktID": "7032069722152",
        "totalPris": 6.0,
        "navn": "Sjampinjong-prima",
        "pris": 6.0
      },
      {
        "strekkode": 7311250013355,
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 112.3,
        "navn": "Snus General",
        "pris": 112.3
      }
    ],
    "butikk": "Rema",
    "summen": 265.9,
    "UkeNr": 14,
    "timestamp": "Timestamp(seconds=1557547808, nanoseconds=393000000)",
    "documentID": "-Le_4MMfgqdPmNn55-M7"
  },
  {
    "kontant": 0,
    "dato": "2019-03-30",
    "bankkort": 25,
    "varer": [
      {
        "strekkode": 7029161121488,
        "mengde": 1,
        "produktID": "7029161121488",
        "totalPris": 25.0,
        "navn": "Brød-Jubileums",
        "pris": 25.0
      }
    ],
    "butikk": "Rema",
    "summen": 25.0,
    "UkeNr": 13,
    "timestamp": "Timestamp(seconds=1557544109, nanoseconds=548000000)",
    "documentID": "-LeZrFNcnRYInbVpSk2e"
  },
  {
    "kontant": 0,
    "dato": "2019-03-30",
    "bankkort": 19.9,
    "varer": [
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 19.9,
        "navn": "KulturMelk",
        "pris": 19.9
      }
    ],
    "butikk": "Bunnpris",
    "summen": 19.9,
    "UkeNr": 13,
    "timestamp": "Timestamp(seconds=1557544072, nanoseconds=57000000)",
    "documentID": "-LeZr6DvjU9k583T_0d0"
  },
  {
    "kontant": -50,
    "dato": "2019-03-28",
    "bankkort": 189.4,
    "varer": [
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 7035620004346,
        "mengde": 1,
        "produktID": "7035620004346",
        "totalPris": 15.0,
        "navn": "Pesto rød- Eldorado",
        "pris": 15.0
      },
      {
        "strekkode": 7038010005459,
        "mengde": 1,
        "produktID": "7038010005459",
        "totalPris": 14.5,
        "navn": "Rømme-lett0,18",
        "pris": 14.5
      },
      {
        "strekkode": 7311250083976,
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 92.0,
        "navn": "Snus G4",
        "pris": 92.0
      }
    ],
    "butikk": "Rema",
    "summen": 139.4,
    "UkeNr": 13,
    "timestamp": "Timestamp(seconds=1557544027, nanoseconds=74000000)",
    "documentID": "-LeZqwBdcNuUTcqJviFA"
  },
  {
    "kontant": 0,
    "dato": "2019-03-28",
    "bankkort": 21.2,
    "varer": [
      {
        "strekkode": 7311041013557,
        "mengde": 1,
        "produktID": "7311041013557",
        "totalPris": 21.2,
        "navn": "Fiskepinner-FirstPrice",
        "pris": 21.2
      }
    ],
    "butikk": "Bunnpris",
    "summen": 21.2,
    "UkeNr": 13,
    "timestamp": "Timestamp(seconds=1557543923, nanoseconds=565000000)",
    "documentID": "-LeZqXycRSEBdNu5h48m"
  },
  {
    "kontant": 0,
    "dato": "2019-03-28",
    "bankkort": 93.8,
    "varer": [
      {
        "strekkode": 7311041019757,
        "mengde": 7,
        "produktID": "7311041019757",
        "totalPris": 93.8,
        "navn": "Formaggio",
        "pris": 13.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 93.8,
    "UkeNr": 13,
    "timestamp": "Timestamp(seconds=1557543875, nanoseconds=507000000)",
    "documentID": "-LeZqMGR39Dhk0Otdwi2"
  },
  {
    "kontant": 0,
    "dato": "2019-03-27",
    "bankkort": 91.9,
    "varer": [
      {
        "strekkode": 7029161121488,
        "mengde": 1,
        "produktID": "7029161121488",
        "totalPris": 25.0,
        "navn": "Brød-Jubileums",
        "pris": 25.0
      },
      {
        "strekkode": 7032069725788,
        "mengde": 1,
        "produktID": "7032069725788",
        "totalPris": 54.9,
        "navn": "Olje-Oliven Extra virgin",
        "pris": 54.9
      },
      {
        "strekkode": 101010108318,
        "mengde": 1,
        "produktID": "101010108318",
        "totalPris": 12.0,
        "navn": "spaghetti-0.5k",
        "pris": 12.0
      }
    ],
    "butikk": "Rema",
    "summen": 91.9,
    "UkeNr": 13,
    "timestamp": "Timestamp(seconds=1557543819, nanoseconds=356000000)",
    "documentID": "-LeZq8S5QjsjLAapoUeI"
  },
  {
    "kontant": 0,
    "dato": "2019-03-27",
    "bankkort": 13.4,
    "varer": [
      {
        "strekkode": 7311041019757,
        "mengde": 1,
        "produktID": "7311041019757",
        "totalPris": 13.4,
        "navn": "Formaggio",
        "pris": 13.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 13.4,
    "UkeNr": 13,
    "timestamp": "Timestamp(seconds=1557543041, nanoseconds=946000000)",
    "documentID": "-LeZnAjD-hiieFJNbRG7"
  },
  {
    "kontant": 0,
    "dato": "2019-03-26",
    "bankkort": 19.9,
    "varer": [
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 19.9,
        "navn": "KulturMelk",
        "pris": 19.9
      }
    ],
    "butikk": "Bunnpris",
    "summen": 19.9,
    "UkeNr": 13,
    "timestamp": "Timestamp(seconds=1557542994, nanoseconds=848000000)",
    "documentID": "-LeZn-E1EaLxbgLP39V1"
  },
  {
    "kontant": 0,
    "dato": "2019-03-25",
    "bankkort": 26.8,
    "varer": [
      {
        "strekkode": 7311041019757,
        "mengde": 2,
        "produktID": "7311041019757",
        "totalPris": 26.8,
        "navn": "Formaggio",
        "pris": 13.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 26.8,
    "UkeNr": 13,
    "timestamp": "Timestamp(seconds=1557542937, nanoseconds=216000000)",
    "documentID": "-LeZmm6m1aBGxOeXWtH8"
  },
  {
    "kontant": 0,
    "dato": "2019-03-25",
    "bankkort": 187.1,
    "varer": [
      {
        "strekkode": 7032069715253,
        "mengde": 1,
        "produktID": "7032069715253",
        "totalPris": 19.9,
        "navn": "MusliCrunchy-Rema1000",
        "pris": 19.9
      },
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 17.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 17.9
      },
      {
        "strekkode": 7029161121488,
        "mengde": 1,
        "produktID": "7029161121488",
        "totalPris": 25.0,
        "navn": "Brød-Jubileums",
        "pris": 25.0
      },
      {
        "strekkode": 7032069722152,
        "mengde": 2,
        "produktID": "7032069722152",
        "totalPris": 12.0,
        "navn": "Sjampinjong-prima",
        "pris": 6.0
      },
      {
        "strekkode": 7311250013355,
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 112.3,
        "navn": "Snus General",
        "pris": 112.3
      }
    ],
    "butikk": "Rema",
    "summen": 187.1,
    "UkeNr": 13,
    "timestamp": "Timestamp(seconds=1557542874, nanoseconds=308000000)",
    "documentID": "-LeZmXkyOJjmGW8Q0yX_"
  },
  {
    "kontant": 0,
    "dato": "2019-03-23",
    "bankkort": 270.6,
    "varer": [
      {
        "strekkode": 7038010005459,
        "mengde": 1,
        "produktID": "7038010005459",
        "totalPris": 14.5,
        "navn": "Rømme-lett0,18",
        "pris": 14.5
      },
      {
        "strekkode": 7311041029299,
        "mengde": 1,
        "produktID": "7311041029299",
        "totalPris": 15.0,
        "navn": "Pesto grønn- Eldorado",
        "pris": 15.0
      },
      {
        "strekkode": 7029161121488,
        "mengde": 1,
        "produktID": "7029161121488",
        "totalPris": 27.5,
        "navn": "Brød-Jubileums",
        "pris": 27.5
      },
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 17.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 17.9
      },
      {
        "strekkode": 7048840081950,
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 25.9,
        "navn": "Melk-stor-0,5-Q",
        "pris": 25.9
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 7090026220592,
        "mengde": 1,
        "produktID": "7090026220592",
        "totalPris": 59.9,
        "navn": "Egg-24",
        "pris": 59.9
      },
      {
        "strekkode": 7311250083976,
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 92.0,
        "navn": "Snus G4",
        "pris": 92.0
      }
    ],
    "butikk": "Rema",
    "summen": 270.6,
    "UkeNr": 12
  },
  {
    "kontant": 0,
    "dato": "2019-03-20",
    "bankkort": 44.4,
    "varer": [
      {
        "strekkode": 7020655860043,
        "mengde": 1,
        "produktID": "7020655860043",
        "totalPris": 26.5,
        "navn": "Brød-SPLEISE",
        "pris": 26.5
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      }
    ],
    "butikk": "CoopExtra",
    "summen": 44.4,
    "UkeNr": 12,
    "timestamp": "Timestamp(seconds=1557542565, nanoseconds=558000000)",
    "documentID": "-LeZlMNYh4SXa3ikpDDh"
  },
  {
    "kontant": 0,
    "dato": "2019-03-18",
    "bankkort": 130.1,
    "varer": [
      {
        "strekkode": 48327203421,
        "mengde": 1,
        "produktID": "48327203421",
        "totalPris": 79.9,
        "navn": "Olje-Oliven-Ybarra",
        "pris": 79.9
      },
      {
        "strekkode": 101010109254,
        "mengde": 1,
        "produktID": "101010109254",
        "totalPris": 12.2,
        "navn": "Aluminiumfolie",
        "pris": 12.2
      },
      {
        "strekkode": 7029161117139,
        "mengde": 1,
        "produktID": "7029161117139",
        "totalPris": 38.0,
        "navn": "Brød- GRØVT&GODT",
        "pris": 38.0
      }
    ],
    "butikk": "Rema",
    "summen": 130.1,
    "UkeNr": 12,
    "timestamp": "Timestamp(seconds=1557542270, nanoseconds=9000000)",
    "documentID": "-LeZkEDa6ls3EGrMdrmz"
  },
  {
    "kontant": 0,
    "dato": "2019-03-18",
    "bankkort": 73.5,
    "varer": [
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 19.9,
        "navn": "KulturMelk",
        "pris": 19.9
      },
      {
        "strekkode": 7311041019757,
        "mengde": 4,
        "produktID": "7311041019757",
        "totalPris": 53.6,
        "navn": "Formaggio",
        "pris": 13.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 73.5,
    "UkeNr": 12,
    "timestamp": "Timestamp(seconds=1557541960, nanoseconds=162000000)",
    "documentID": "-LeZj2_39qfltEVSSxNG"
  },
  {
    "kontant": 0,
    "dato": "2019-03-16",
    "bankkort": 21.2,
    "varer": [
      {
        "strekkode": 7311041013557,
        "mengde": 1,
        "produktID": "7311041013557",
        "totalPris": 21.2,
        "navn": "Fiskepinner-FirstPrice",
        "pris": 21.2
      }
    ],
    "butikk": "Bunnpris",
    "summen": 21.2,
    "UkeNr": 11,
    "timestamp": "Timestamp(seconds=1557541887, nanoseconds=188000000)",
    "documentID": "-LeZilkNVJfNoIBt3h6Y"
  },
  {
    "kontant": 0,
    "dato": "2019-03-16",
    "bankkort": 195,
    "varer": [
      {
        "strekkode": 7311250013355,
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 112.3,
        "navn": "Snus General",
        "pris": 112.3
      },
      {
        "strekkode": 7032069715253,
        "mengde": 1,
        "produktID": "7032069715253",
        "totalPris": 19.9,
        "navn": "MusliCrunchy-Rema1000",
        "pris": 19.9
      },
      {
        "strekkode": 101010103238,
        "mengde": 1,
        "produktID": "101010103238",
        "totalPris": 29.9,
        "navn": "Jif- WC",
        "pris": 29.9
      },
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 17.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 17.9
      },
      {
        "strekkode": 7311041029299,
        "mengde": 1,
        "produktID": "7311041029299",
        "totalPris": 15.0,
        "navn": "Pesto grønn- Eldorado",
        "pris": 15.0
      }
    ],
    "butikk": "Rema",
    "summen": 195.0,
    "UkeNr": 11,
    "timestamp": "Timestamp(seconds=1557541798, nanoseconds=883000000)",
    "documentID": "-LeZiRBqIqsnzwQgef5u"
  },
  {
    "kontant": 0,
    "dato": "2019-03-15",
    "bankkort": 236,
    "varer": [
      {
        "strekkode": 1111,
        "mengde": 4,
        "produktID": "jVck6nxlijSqto1dMxls",
        "totalPris": 236.0,
        "navn": "SykkelSlange",
        "pris": 59.0
      }
    ],
    "butikk": "XXL",
    "summen": 236.0,
    "UkeNr": 11,
    "timestamp": "Timestamp(seconds=1557541518, nanoseconds=330000000)",
    "documentID": "-LeZhMhFEesZr39YUG3L"
  },
  {
    "kontant": 80,
    "dato": "2019-03-15",
    "bankkort": 130.5,
    "varer": [
      {
        "strekkode": 7311041019757,
        "mengde": 4,
        "produktID": "7311041019757",
        "totalPris": 53.6,
        "navn": "Formaggio",
        "pris": 13.4
      },
      {
        "strekkode": 7020655860043,
        "mengde": 1,
        "produktID": "7020655860043",
        "totalPris": 23.6,
        "navn": "Brød-SPLEISE",
        "pris": 23.6
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 7048840081950,
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 23.4,
        "navn": "Melk-stor-0,5-Q",
        "pris": 23.4
      },
      {
        "strekkode": 7311250083976,
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 92.0,
        "navn": "Snus G4",
        "pris": 92.0
      }
    ],
    "butikk": "Kiwi",
    "summen": 210.5,
    "UkeNr": 11,
    "timestamp": "Timestamp(seconds=1557541448, nanoseconds=471000000)",
    "documentID": "-LeZh5dMS8KyhggPxlLU"
  },
  {
    "kontant": 0,
    "dato": "2019-03-15",
    "bankkort": 232.67,
    "varer": [
      {
        "strekkode": 11111,
        "mengde": 1,
        "produktID": "42eQ7LRuiS2M4qiPNyYt",
        "totalPris": 41.5,
        "navn": "Tørkeruller",
        "pris": 41.5
      },
      {
        "strekkode": 101010106475,
        "mengde": 1,
        "produktID": "101010106475",
        "totalPris": 59.9,
        "navn": "Munn væske - Listerine ",
        "pris": 59.9
      },
      {
        "strekkode": 2382664409732,
        "mengde": 1,
        "produktID": "2382664409732",
        "totalPris": 131.27,
        "navn": "Ost synnøve-Gouda-1K",
        "pris": 131.27
      }
    ],
    "butikk": "Obs",
    "summen": 232.67,
    "UkeNr": 11,
    "timestamp": "Timestamp(seconds=1557541264, nanoseconds=735000000)",
    "documentID": "-LeZgOm_wDoyGC7uu48S"
  },
  {
    "kontant": 0,
    "dato": "2019-03-12",
    "bankkort": 20,
    "varer": [
      {
        "strekkode": 7020655860043,
        "mengde": 1,
        "produktID": "7020655860043",
        "totalPris": 20.0,
        "navn": "Brød-SPLEISE",
        "pris": 20.0
      }
    ],
    "butikk": "Rema",
    "summen": 20.0,
    "UkeNr": 11,
    "timestamp": "Timestamp(seconds=1557541131, nanoseconds=132000000)",
    "documentID": "-LeZftEql1BYUS4l6-0k"
  },
  {
    "kontant": 0,
    "dato": "2019-03-11",
    "bankkort": 95.7,
    "varer": [
      {
        "strekkode": 7038010000737,
        "mengde": 2,
        "produktID": "7038010000737",
        "totalPris": 35.8,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 7090026220592,
        "mengde": 1,
        "produktID": "7090026220592",
        "totalPris": 59.9,
        "navn": "Egg-24",
        "pris": 59.9
      }
    ],
    "butikk": "Rema",
    "summen": 95.7,
    "UkeNr": 11,
    "timestamp": "Timestamp(seconds=1557541077, nanoseconds=508000000)",
    "documentID": "-LeZfg4_CUm534eOAUEy"
  },
  {
    "kontant": 0,
    "dato": "2019-03-11",
    "bankkort": 93.8,
    "varer": [
      {
        "strekkode": 7311041019757,
        "mengde": 7,
        "produktID": "7311041019757",
        "totalPris": 93.8,
        "navn": "Formaggio",
        "pris": 13.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 93.8,
    "UkeNr": 11,
    "timestamp": "Timestamp(seconds=1557540971, nanoseconds=456000000)",
    "documentID": "-LeZfH8hGUurPG4-4CTx"
  },
  {
    "kontant": 0,
    "dato": "2019-03-10",
    "bankkort": 33.5,
    "varer": [
      {
        "strekkode": 7029161117139,
        "mengde": 1,
        "produktID": "7029161117139",
        "totalPris": 33.5,
        "navn": "Brød- GRØVT&GODT",
        "pris": 33.5
      }
    ],
    "butikk": "Rema",
    "summen": 33.5,
    "UkeNr": 10,
    "timestamp": "Timestamp(seconds=1557540902, nanoseconds=581000000)",
    "documentID": "-LeZf0JbqSddQLN5ygES"
  },
  {
    "dato": "2019-03-09",
    "varer": [
      {
        "strekkode": 101010101067,
        "mengde": 3,
        "produktID": "101010101067",
        "totalPris": 11.0,
        "navn": "Brød-Rundstykker",
        "pris": 3.67
      }
    ],
    "butikk": "Rema",
    "summen": 11.0,
    "UkeNr": 10,
    "timestamp": "Timestamp(seconds=1552161292, nanoseconds=683000000)",
    "documentID": "-L_Z0RUt-9JP1z435Yjw"
  },
  {
    "dato": "2019-03-07",
    "varer": [
      {
        "strekkode": 7032069726600,
        "mengde": 3,
        "produktID": "ErL7PujeMYUwt6xvepLO",
        "totalPris": 35.7,
        "navn": "Bakeark",
        "pris": 11.9
      },
      {
        "strekkode": 7048840081950,
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 25.9,
        "navn": "Melk-stor-0,5-Q",
        "pris": 25.9
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 7021010001057,
        "mengde": 1,
        "produktID": "7021010001057",
        "totalPris": 24.3,
        "navn": "Sjokoladepålegg-Nugatti",
        "pris": 24.3
      },
      {
        "strekkode": 7311250083976,
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 92.0,
        "navn": "Snus G4",
        "pris": 92.0
      },
      {
        "strekkode": 7311250013355,
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 112.3,
        "navn": "Snus General",
        "pris": 112.3
      }
    ],
    "butikk": "Rema",
    "summen": 308.1,
    "UkeNr": 10,
    "timestamp": "Timestamp(seconds=1552153259, nanoseconds=679000000)",
    "documentID": "-L_YXnHO-knneyZLBDQ1"
  },
  {
    "dato": "2019-03-07",
    "varer": [
      {
        "strekkode": 7311041013557,
        "mengde": 1,
        "produktID": "7311041013557",
        "totalPris": 21.2,
        "navn": "Fiskepinner-FirstPrice",
        "pris": 21.2
      }
    ],
    "butikk": "Bunnpris",
    "summen": 21.2,
    "UkeNr": 10,
    "timestamp": "Timestamp(seconds=1552153047, nanoseconds=256000000)",
    "documentID": "-L_YWzTA0vVvBfF3ZUyY"
  },
  {
    "dato": "2019-03-06",
    "varer": [
      {
        "strekkode": 7311041029299,
        "mengde": 1,
        "produktID": "7311041029299",
        "totalPris": 12.5,
        "navn": "Pesto grønn- Eldorado",
        "pris": 12.5
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 19.9,
        "navn": "KulturMelk",
        "pris": 19.9
      }
    ],
    "butikk": "Bunnpris",
    "summen": 32.4,
    "UkeNr": 10,
    "timestamp": "Timestamp(seconds=1552153000, nanoseconds=702000000)",
    "documentID": "-L_YWo4lojjbFNpvG5qe"
  },
  {
    "dato": "2019-03-05",
    "varer": [
      {
        "strekkode": 7032069715253,
        "mengde": 1,
        "produktID": "7032069715253",
        "totalPris": 19.9,
        "navn": "MusliCrunchy-Rema1000",
        "pris": 19.9
      },
      {
        "strekkode": 101010109346,
        "mengde": 1,
        "produktID": "101010109346",
        "totalPris": 19.9,
        "navn": "Feil",
        "pris": 19.9
      },
      {
        "strekkode": 7041614000867,
        "mengde": 1,
        "produktID": "7041614000867",
        "totalPris": 20.0,
        "navn": "Brød-HVERDAGSGROVT",
        "pris": 20.0
      },
      {
        "strekkode": 7038010055690,
        "mengde": 2,
        "produktID": "7038010055690",
        "totalPris": 30.0,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 15.0
      }
    ],
    "butikk": "Bunnpris",
    "summen": 89.8,
    "UkeNr": 10,
    "timestamp": "Timestamp(seconds=1552152940, nanoseconds=0)",
    "documentID": "-L_YkKIFhjfsKjhEb2Ky"
  },
  {
    "dato": "2019-03-03",
    "varer": [
      {
        "strekkode": 7311250083976,
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 92.0,
        "navn": "Snus G4",
        "pris": 92.0
      }
    ],
    "butikk": "Rema",
    "summen": 92.0,
    "UkeNr": 9,
    "timestamp": "Timestamp(seconds=1552152880, nanoseconds=70000000)",
    "documentID": "-L_YWLdlw1c37frETk_B"
  },
  {
    "dato": "2019-03-02",
    "varer": [
      {
        "strekkode": 7311041013618,
        "mengde": 1,
        "produktID": "7311041013618",
        "totalPris": 13.8,
        "navn": "Champignonskiver-0,148K",
        "pris": 13.8
      },
      {
        "strekkode": 7314571151003,
        "mengde": 2,
        "produktID": "7314571151003",
        "totalPris": 47.2,
        "navn": "Shampoo-Sport",
        "pris": 23.6
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 7311041002544,
        "mengde": 1,
        "produktID": "7311041002544",
        "totalPris": 6.1,
        "navn": "Baguett-Eldorado-6stk",
        "pris": 6.1
      }
    ],
    "butikk": "CoopObs",
    "summen": 85.0,
    "UkeNr": 9,
    "timestamp": "Timestamp(seconds=1552152846, nanoseconds=433000000)",
    "documentID": "-L_YWDOcaHGaVRdv8bsh"
  },
  {
    "dato": "2019-03-02",
    "varer": [
      {
        "strekkode": 7040514501474,
        "mengde": 1,
        "produktID": "7040514501474",
        "totalPris": 15.9,
        "navn": "Løk-FirstPrice",
        "pris": 15.9
      },
      {
        "strekkode": 7041611018124,
        "mengde": 1,
        "produktID": "7041611018124",
        "totalPris": 25.9,
        "navn": "Brød-NORSK FJELLBRØD",
        "pris": 25.9
      }
    ],
    "butikk": "Bunnpris",
    "summen": 41.8,
    "UkeNr": 9,
    "timestamp": "Timestamp(seconds=1552152693, nanoseconds=393000000)",
    "documentID": "-L_YVd4-pJzHG7XSCUjo"
  },
  {
    "dato": "2019-03-02",
    "varer": [
      {
        "strekkode": 7393173362840,
        "mengde": 1,
        "produktID": "7393173362840",
        "totalPris": 149.0,
        "navn": "Wifi Smart Bulb",
        "pris": 149.0
      }
    ],
    "butikk": "Clas Ohlson",
    "summen": 149.0,
    "UkeNr": 9,
    "timestamp": "Timestamp(seconds=1552152633, nanoseconds=349000000)",
    "documentID": "-L_YVPObpsjj8eLvLcHc"
  },
  {
    "dato": "2019-03-02",
    "varer": [
      {
        "strekkode": 1111,
        "mengde": 1,
        "produktID": "aytgBxgTXshE1fyushD2",
        "totalPris": 479.0,
        "navn": "Whey Protein-3K-PF",
        "pris": 479.0
      }
    ],
    "butikk": "XXL",
    "summen": 479.0,
    "UkeNr": 9,
    "timestamp": "Timestamp(seconds=1552152503, nanoseconds=148000000)",
    "documentID": "-L_YUu_VwwRsWEjRcvBH"
  },
  {
    "kontant": 0,
    "dato": "2019-03-01",
    "bankkort": 49,
    "varer": [
      {
        "strekkode": 101010106932,
        "mengde": 1,
        "produktID": "101010106932",
        "totalPris": 49.0,
        "navn": "Sim-kort",
        "pris": 49.0
      }
    ],
    "butikk": "Narvesen",
    "summen": 49.0,
    "UkeNr": 9,
    "timestamp": "Timestamp(seconds=1552152483, nanoseconds=0)",
    "documentID": "-LecuLhSyvFU5nJpHeg0"
  },
  {
    "dato": "2019-03-01",
    "varer": [
      {
        "strekkode": 7311041019757,
        "mengde": 6,
        "produktID": "7311041019757",
        "totalPris": 80.4,
        "navn": "Formaggio",
        "pris": 13.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 80.4,
    "UkeNr": 9,
    "timestamp": "Timestamp(seconds=1552152423, nanoseconds=426000000)",
    "documentID": "-L_YUb6mYQzi3REa9fIZ"
  },
  {
    "dato": "2019-02-28",
    "varer": [
      {
        "strekkode": 7311041019757,
        "mengde": 1,
        "produktID": "7311041019757",
        "totalPris": 13.4,
        "navn": "Formaggio",
        "pris": 13.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 13.4,
    "UkeNr": 9,
    "timestamp": "Timestamp(seconds=1552148125, nanoseconds=776000000)",
    "documentID": "-L_YECpT8RB4hq5N_wIH"
  },
  {
    "dato": "2019-02-28",
    "varer": [
      {
        "strekkode": 7020655860043,
        "mengde": 1,
        "produktID": "7020655860043",
        "totalPris": 24.0,
        "navn": "Brød-SPLEISE",
        "pris": 24.0
      },
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 17.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 17.9
      },
      {
        "strekkode": 7038010005459,
        "mengde": 1,
        "produktID": "7038010005459",
        "totalPris": 14.9,
        "navn": "Rømme-lett0,18",
        "pris": 14.9
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      }
    ],
    "butikk": "Rema",
    "summen": 74.7,
    "UkeNr": 9,
    "timestamp": "Timestamp(seconds=1552148088, nanoseconds=471000000)",
    "documentID": "-L_YE3fRbIprfRzZsQYj"
  },
  {
    "dato": "2019-02-25",
    "varer": [
      {
        "strekkode": 7048840081950,
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 25.9,
        "navn": "Melk-stor-0,5-Q",
        "pris": 25.9
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 17.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 17.9
      },
      {
        "strekkode": 7311041029299,
        "mengde": 1,
        "produktID": "7311041029299",
        "totalPris": 15.0,
        "navn": "Pesto grønn- Eldorado",
        "pris": 15.0
      },
      {
        "strekkode": 7090026220592,
        "mengde": 1,
        "produktID": "7090026220592",
        "totalPris": 59.9,
        "navn": "Egg-24",
        "pris": 59.9
      },
      {
        "strekkode": 7020655860043,
        "mengde": 1,
        "produktID": "7020655860043",
        "totalPris": 24.0,
        "navn": "Brød-SPLEISE",
        "pris": 24.0
      },
      {
        "strekkode": 101010102019,
        "mengde": 1,
        "produktID": "SJeGJDQlCAX7XmUe4q1M",
        "totalPris": 2.51,
        "navn": "Løk-løsvekt",
        "pris": 2.51
      },
      {
        "strekkode": 7311250083976,
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 92.0,
        "navn": "Snus G4",
        "pris": 92.0
      }
    ],
    "butikk": "Rema",
    "summen": 255.11,
    "UkeNr": 9,
  },
  {
    "dato": "2019-02-25",
    "varer": [
      {
        "strekkode": 7311041019757,
        "mengde": 4,
        "produktID": "7311041019757",
        "totalPris": 53.6,
        "navn": "Formaggio",
        "pris": 13.4
      },
      {
        "strekkode": 2302148200006,
        "mengde": 1,
        "produktID": "2302148200006",
        "totalPris": 78.75,
        "navn": "Norvegia-1K",
        "pris": 78.75
      }
    ],
    "butikk": "Bunnpris",
    "summen": 132.35,
    "UkeNr": 9,
    "timestamp": "Timestamp(seconds=1552147866, nanoseconds=497000000)",
    "documentID": "-L_YDDVewejLj3Mjjaau"
  },
  {
    "dato": "2019-02-23",
    "varer": [
      {
        "strekkode": 7041614000867,
        "mengde": 1,
        "produktID": "7041614000867",
        "totalPris": 20.0,
        "navn": "Brød-HVERDAGSGROVT",
        "pris": 20.0
      },
      {
        "strekkode": 7311041013441,
        "mengde": 1,
        "produktID": "7311041013441",
        "totalPris": 19.9,
        "navn": "MusliCrunchy-FirstPrice",
        "pris": 19.9
      },
      {
        "strekkode": 7311250013355,
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 116.9,
        "navn": "Snus General",
        "pris": 116.9
      }
    ],
    "butikk": "Bunnpris",
    "summen": 156.8,
    "UkeNr": 8,
    "timestamp": "Timestamp(seconds=1552147798, nanoseconds=658000000)",
    "documentID": "-L_YCxxjw2rzO77n2NBZ"
  },
  {
    "dato": "2019-02-22",
    "varer": [
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 17.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 17.9
      }
    ],
    "butikk": "Bunnpris",
    "summen": 35.8,
    "UkeNr": 8,
    "timestamp": "Timestamp(seconds=1552147682, nanoseconds=421000000)",
    "documentID": "-L_YCWZub2cwLkJi89fi"
  },
  {
    "dato": "2019-02-19",
    "varer": [
      {
        "strekkode": 7311250083976,
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 92.0,
        "navn": "Snus G4",
        "pris": 92.0
      }
    ],
    "butikk": "Rema",
    "summen": 92.0,
    "UkeNr": 8,
    "timestamp": "Timestamp(seconds=1552147639, nanoseconds=0)",
    "documentID": "-L_YfsI22E56--JG8P9-"
  },
  {
    "dato": "2019-02-19",
    "varer": [
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 17.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 17.9
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 7048840081950,
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 25.9,
        "navn": "Melk-stor-0,5-Q",
        "pris": 25.9
      },
      {
        "strekkode": 7029161121488,
        "mengde": 1,
        "produktID": "7029161121488",
        "totalPris": 25.0,
        "navn": "Brød-Jubileums",
        "pris": 25.0
      }
    ],
    "butikk": "Rema",
    "summen": 86.7,
    "UkeNr": 8,
    "timestamp": "Timestamp(seconds=1552147632, nanoseconds=674000000)",
    "documentID": "-L_YCKRXajYnivIwWK2V"
  },
  {
    "dato": "2019-02-18",
    "varer": [
      {
        "strekkode": 6410708762683,
        "mengde": 1,
        "produktID": "6410708762683",
        "totalPris": 46.9,
        "navn": "Olje-Oliven eldorado",
        "pris": 46.9
      }
    ],
    "butikk": "Bunnpris",
    "summen": 46.9,
    "UkeNr": 8,
    "timestamp": "Timestamp(seconds=1552147558, nanoseconds=477000000)",
    "documentID": "-L_YC2KHBNrvjRE4FjKQ"
  },
  {
    "dato": "2019-02-18",
    "varer": [
      {
        "strekkode": 7311041013557,
        "mengde": 1,
        "produktID": "7311041013557",
        "totalPris": 18.5,
        "navn": "Fiskepinner-FirstPrice",
        "pris": 18.5
      },
      {
        "strekkode": 7311041019757,
        "mengde": 7,
        "produktID": "7311041019757",
        "totalPris": 93.8,
        "navn": "Formaggio",
        "pris": 13.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 112.3,
    "UkeNr": 8,
    "timestamp": "Timestamp(seconds=1552146984, nanoseconds=813000000)",
    "documentID": "-L_Y9rGH4pJX45-GAIRA"
  },
  {
    "dato": "2019-02-16",
    "varer": [
      {
        "strekkode": 101010103702,
        "mengde": 0.25,
        "produktID": "K0UOyr11TO0G6aTPx3hD",
        "totalPris": 24.9,
        "navn": "Hvitløk-løsvekt",
        "pris": 24.9
      },
      {
        "strekkode": 7038010014604,
        "mengde": 1,
        "produktID": "7038010014604",
        "totalPris": 59.19,
        "navn": "Norvegia-0,5K",
        "pris": 59.19
      },
      {
        "strekkode": 7020655860043,
        "mengde": 1,
        "produktID": "7020655860043",
        "totalPris": 27,
        "navn": "Brød-SPLEISE",
        "pris": 27
      },
      {
        "strekkode": 101010101906,
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": -0.09,
        "navn": "avrunding",
        "pris": -0.09
      }
    ],
    "butikk": "Rema",
    "summen": 111.0,
    "UkeNr": 7,
    "timestamp": "Timestamp(seconds=1552146906, nanoseconds=342000000)",
    "documentID": "-L_Y9Z5spJ0BZxPjwnjj"
  },
  {
    "dato": "2019-02-15",
    "varer": [
      {
        "strekkode": 7050122131611,
        "mengde": 4,
        "produktID": "7050122131611",
        "totalPris": 66.0,
        "navn": "Dipmix",
        "pris": 66.0
      },
      {
        "strekkode": 7311041019757,
        "mengde": 2,
        "produktID": "7311041019757",
        "totalPris": 26.8,
        "navn": "Formaggio",
        "pris": 13.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 92.8,
    "UkeNr": 7,
    "timestamp": "Timestamp(seconds=1552146757, nanoseconds=598000000)",
    "documentID": "-L_Y8zlPv03Oz7qzHzH4"
  },
  {
    "dato": "2019-02-11",
    "varer": [
      {
        "strekkode": 7311041013557,
        "mengde": 1,
        "produktID": "7311041013557",
        "totalPris": 18.5,
        "navn": "Fiskepinner-FirstPrice",
        "pris": 18.5
      }
    ],
    "butikk": "Bunnpris",
    "summen": 18.5,
    "UkeNr": 7,
    "timestamp": "Timestamp(seconds=1552146496, nanoseconds=772000000)",
    "documentID": "-L_Y8-5aV--vLachl6vU"
  },
  {
    "dato": "2019-02-09",
    "varer": [
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 17.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 17.9
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 18.9,
        "navn": "KulturMelk",
        "pris": 18.9
      },
      {
        "strekkode": 7020655860043,
        "mengde": 1,
        "produktID": "7020655860043",
        "totalPris": 20.0,
        "navn": "Brød-SPLEISE",
        "pris": 20.0
      }
    ],
    "butikk": "Rema",
    "summen": 56.8,
    "UkeNr": 6,
    "timestamp": "Timestamp(seconds=1552146457, nanoseconds=394000000)",
    "documentID": "-L_Y7qTEG98vJXcBgT9r"
  },
  {
    "dato": "2019-02-08",
    "varer": [
      {
        "strekkode": 7311250013355,
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 93.4,
        "navn": "Snus General",
        "pris": 93.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 93.4,
    "UkeNr": 6,
    "timestamp": "Timestamp(seconds=1552146395, nanoseconds=718000000)",
    "documentID": "-L_Y7bSPruO60ftAKQKs"
  },
  {
    "dato": "2019-02-06",
    "varer": [
      {
        "strekkode": 7020655860043,
        "mengde": 1,
        "produktID": "7020655860043",
        "totalPris": 23.9,
        "navn": "Brød-SPLEISE",
        "pris": 23.9
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 10.0,
        "navn": "KulturMelk",
        "pris": 10.0
      },
      {
        "strekkode": 7070646283320,
        "mengde": 1,
        "produktID": "gYPJMZvTE1ZMDq2uC3wc",
        "totalPris": 229.0,
        "navn": "Whey Protein-1K-PF",
        "pris": 229.0
      },
      {
        "strekkode": 6414300084983,
        "mengde": 1,
        "produktID": "6414300084983",
        "totalPris": 34.6,
        "navn": "Tørkepapir Serla",
        "pris": 34.6
      },
      {
        "strekkode": 7039610005849,
        "mengde": 1,
        "produktID": "7039610005849",
        "totalPris": 29.9,
        "navn": "Egg-18",
        "pris": 29.9
      },
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 20.8,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 20.8
      }
    ],
    "butikk": "CoopObs",
    "summen": 348.2,
    "UkeNr": 6,
    "timestamp": "Timestamp(seconds=1552146356, nanoseconds=559000000)",
    "documentID": "-L_Y7SrDCzQOf4hz0FdP"
  },
  {
    "dato": "2019-02-05",
    "varer": [
      {
        "strekkode": 7311041019757,
        "mengde": 7,
        "produktID": "7311041019757",
        "totalPris": 93.8,
        "navn": "Formaggio",
        "pris": 13.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 93.8,
    "UkeNr": 6,
    "timestamp": "Timestamp(seconds=1552146199, nanoseconds=207000000)",
    "documentID": "-L_Y6rSYZ7hNR8BOT_9c"
  },
  {
    "dato": "2019-02-03",
    "varer": [
      {
        "strekkode": 7040913334390,
        "mengde": 1,
        "produktID": "7040913334390",
        "totalPris": 29.9,
        "navn": "Kaffe-0,25K",
        "pris": 29.9
      }
    ],
    "butikk": "Rema",
    "summen": 29.9,
    "UkeNr": 5,
    "timestamp": "Timestamp(seconds=1552146158, nanoseconds=861000000)",
    "documentID": "-L_Y6hcmryQT1jQSedZ2"
  },
  {
    "dato": "2019-02-05",
    "varer": [
      {
        "strekkode": 7048840081950,
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 26.7,
        "navn": "Melk-stor-0,5-Q",
        "pris": 26.7
      },
      {
        "strekkode": 7032069715253,
        "mengde": 1,
        "produktID": "7032069715253",
        "totalPris": 19.9,
        "navn": "MusliCrunchy-Rema1000",
        "pris": 19.9
      },
      {
        "strekkode": 7311041029299,
        "mengde": 1,
        "produktID": "7311041029299",
        "totalPris": 30.5,
        "navn": "Pesto grønn- Eldorado",
        "pris": 30.5
      }
    ],
    "butikk": "Rema",
    "summen": 77.1,
    "UkeNr": 6,
    "timestamp": "Timestamp(seconds=1552146126, nanoseconds=742000000)",
    "documentID": "-L_Y6_lC2rqXB9oUSRFa"
  },
  {
    "dato": "2019-02-03",
    "varer": [
      {
        "strekkode": 7029161117139,
        "mengde": 1,
        "produktID": "7029161117139",
        "totalPris": 29.0,
        "navn": "Brød- GRØVT&GODT",
        "pris": 29.0
      },
      {
        "strekkode": 7311250013355,
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 112.3,
        "navn": "Snus General",
        "pris": 112.3
      }
    ],
    "butikk": "Rema",
    "summen": 141.3,
    "UkeNr": 5,
    "timestamp": "Timestamp(seconds=1552146039, nanoseconds=739000000)",
    "documentID": "-L_Y6FXdIqcBBQt1LCiT"
  },
  {
    "dato": "2019-02-01",
    "varer": [
      {
        "strekkode": 7311041019757,
        "mengde": 2,
        "produktID": "7311041019757",
        "totalPris": 26.8,
        "navn": "Formaggio",
        "pris": 13.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 26.8,
    "UkeNr": 5,
    "timestamp": "Timestamp(seconds=1552145982, nanoseconds=454000000)",
    "documentID": "-L_Y61ZYTMnHdohupaIC"
  },
  {
    "dato": "2019-02-01",
    "varer": [
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 20.5,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 20.5
      },
      {
        "strekkode": 7038010005459,
        "mengde": 1,
        "produktID": "7038010005459",
        "totalPris": 15.9,
        "navn": "Rømme-lett0,18",
        "pris": 15.9
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 18.9,
        "navn": "KulturMelk",
        "pris": 18.9
      },
      {
        "strekkode": 7311250083976,
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 92.7,
        "navn": "Snus G4",
        "pris": 92.7
      }
    ],
    "butikk": "Rema",
    "summen": 148.0,
    "UkeNr": 5,
    "timestamp": "Timestamp(seconds=1552145948, nanoseconds=223000000)",
    "documentID": "-L_Y5u8ldouXfDDnR-an"
  },
  {
    "dato": "2019-01-30",
    "varer": [
      {
        "strekkode": 1111,
        "mengde": 1,
        "produktID": "i7Z2fywdOpjel4HEix7e",
        "totalPris": 15.6,
        "navn": "Tannkrem",
        "pris": 15.6
      },
      {
        "strekkode": 101010107724,
        "mengde": 3,
        "produktID": "87UsRoroXvkfLQhionEg",
        "totalPris": 91.6,
        "navn": "KjøptForAndre",
        "pris": 30.53
      },
      {
        "strekkode": 7029161121488,
        "mengde": 1,
        "produktID": "7029161121488",
        "totalPris": 27.5,
        "navn": "Brød-Jubileums",
        "pris": 27.5
      },
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 19.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 19.9
      }
    ],
    "butikk": "Rema",
    "summen": 154.6,
    "UkeNr": 5,
    "timestamp": "Timestamp(seconds=1552082973, nanoseconds=878000000)",
    "documentID": "-L_ULfOUTosR6y9OVf43"
  },
  {
    "dato": "2019-01-28",
    "varer": [
      {
        "strekkode": 7048840081950,
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 24.9,
        "navn": "Melk-stor-0,5-Q",
        "pris": 24.9
      },
      {
        "strekkode": 7032069715253,
        "mengde": 1,
        "produktID": "7032069715253",
        "totalPris": 17.9,
        "navn": "MusliCrunchy-Rema1000",
        "pris": 17.9
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 7029161117139,
        "mengde": 1,
        "produktID": "7029161117139",
        "totalPris": 29.0,
        "navn": "Brød- GRØVT&GODT",
        "pris": 29.0
      }
    ],
    "butikk": "Rema",
    "summen": 89.7,
    "UkeNr": 5,
    "timestamp": "Timestamp(seconds=1552082696, nanoseconds=416000000)",
    "documentID": "-L_UKbbxZXBRCBe659EZ"
  },
  {
    "dato": "2019-01-25",
    "varer": [
      {
        "strekkode": 7090026220592,
        "mengde": 1,
        "produktID": "7090026220592",
        "totalPris": 59.9,
        "navn": "Egg-24",
        "pris": 59.9
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 19.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 19.9
      },
      {
        "strekkode": 7311041013519,
        "mengde": 1,
        "produktID": "7311041013519",
        "totalPris": 17.3,
        "navn": "Spaghetti",
        "pris": 17.3
      },
      {
        "strekkode": 101010107724,
        "mengde": 1,
        "produktID": "87UsRoroXvkfLQhionEg",
        "totalPris": 28.9,
        "navn": "KjøptForAndre",
        "pris": 28.9
      },
      {
        "strekkode": 7311250083976,
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 91.2,
        "navn": "Snus G4",
        "pris": 91.2
      },
      {
        "strekkode": 7311250013355,
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 111.1,
        "navn": "Snus General",
        "pris": 111.1
      },
      {
        "strekkode": 7020655860043,
        "mengde": 1,
        "produktID": "7020655860043",
        "totalPris": 23.5,
        "navn": "Brød-SPLEISE",
        "pris": 23.5
      }
    ],
    "butikk": "Rema",
    "summen": 369.7,
    "UkeNr": 4
  },
  {
    "dato": "2019-01-25",
    "varer": [
      {
        "strekkode": 7311041019757,
        "mengde": 6,
        "produktID": "7311041019757",
        "totalPris": 80.4,
        "navn": "Formaggio",
        "pris": 13.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 80.4,
    "UkeNr": 4,
    "timestamp": "Timestamp(seconds=1552082399, nanoseconds=225000000)",
    "documentID": "-L_UJU4bwhfo9iV9315v"
  },
  {
    "dato": "2019-01-22",
    "varer": [
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 7311041029299,
        "mengde": 1,
        "produktID": "7311041029299",
        "totalPris": 11.5,
        "navn": "Pesto grønn- Eldorado",
        "pris": 11.5
      },
      {
        "strekkode": 7020655860043,
        "mengde": 1,
        "produktID": "7020655860043",
        "totalPris": 23.5,
        "navn": "Brød-SPLEISE",
        "pris": 23.5
      }
    ],
    "butikk": "Rema",
    "summen": 52.9,
    "UkeNr": 4,
    "timestamp": "Timestamp(seconds=1552082354, nanoseconds=68000000)",
    "documentID": "-L_UJJ1tZf6YDY19usvG"
  },
  {
    "dato": "2019-01-22",
    "varer": [
      {
        "strekkode": 7311041013557,
        "mengde": 1,
        "produktID": "7311041013557",
        "totalPris": 18.6,
        "navn": "Fiskepinner-FirstPrice",
        "pris": 18.6
      }
    ],
    "butikk": "Bunnpris",
    "summen": 18.6,
    "UkeNr": 4,
    "timestamp": "Timestamp(seconds=1552082285, nanoseconds=262000000)",
    "documentID": "-L_UJ2Eyx9szsZCIoeU1"
  },
  {
    "dato": "2019-01-21",
    "varer": [
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 21.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 21.9
      },
      {
        "strekkode": 7050122131611,
        "mengde": 2,
        "produktID": "7050122131611",
        "totalPris": 33.0,
        "navn": "Dipmix",
        "pris": 16.5
      },
      {
        "strekkode": 7048840081950,
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 25.9,
        "navn": "Melk-stor-0,5-Q",
        "pris": 25.9
      },
      {
        "strekkode": 7038010005459,
        "mengde": 1,
        "produktID": "7038010005459",
        "totalPris": 16.9,
        "navn": "Rømme-lett0,18",
        "pris": 16.9
      }
    ],
    "butikk": "Bunnpris",
    "summen": 97.7,
    "UkeNr": 4,
    "timestamp": "Timestamp(seconds=1552082208, nanoseconds=260000000)",
    "documentID": "-L_UIkQzlGgyySXFtf_i"
  },
  {
    "dato": "2019-01-22",
    "varer": [
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 21.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 21.9
      },
      {
        "strekkode": 7050122131611,
        "mengde": 2,
        "produktID": "7050122131611",
        "totalPris": 33.0,
        "navn": "Dipmix",
        "pris": 16.5
      },
      {
        "strekkode": 7048840081950,
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 25.9,
        "navn": "Melk-stor-0,5-Q",
        "pris": 25.9
      },
      {
        "strekkode": 7038010005459,
        "mengde": 1,
        "produktID": "7038010005459",
        "totalPris": 16.9,
        "navn": "Rømme-lett0,18",
        "pris": 16.9
      }
    ],
    "butikk": "Bunnpris",
    "summen": 97.7,
    "UkeNr": 4,
    "timestamp": "Timestamp(seconds=1552082207, nanoseconds=885000000)",
    "documentID": "-L_UIkQzlGgyySXFtf_h"
  },
  {
    "dato": "2019-01-19",
    "varer": [
      {
        "strekkode": 7029161117139,
        "mengde": 1,
        "produktID": "7029161117139",
        "totalPris": 29.9,
        "navn": "Brød- GRØVT&GODT",
        "pris": 29.9
      },
      {
        "strekkode": 7311250083976,
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 90.4,
        "navn": "Snus G4",
        "pris": 90.4
      },
      {
        "strekkode": 101010103702,
        "mengde": 1,
        "produktID": "K0UOyr11TO0G6aTPx3hD",
        "totalPris": 13.9,
        "navn": "Hvitløk-løsvekt",
        "pris": 13.9
      },
      {
        "strekkode": 101010105850,
        "mengde": 1,
        "produktID": "101010105850",
        "totalPris": 59.36,
        "navn": "Ost Jarlsbergost-0,45",
        "pris": 59.36
      },
      {
        "strekkode": 7038010028441,
        "mengde": 1,
        "produktID": "7038010028441",
        "totalPris": 57.9,
        "navn": "Brunost-Original-1kg",
        "pris": 57.9
      }
    ],
    "butikk": "CoopExtra",
    "summen": 251.46,
    "UkeNr": 3,
    "timestamp": "Timestamp(seconds=1552082083, nanoseconds=883000000)",
    "documentID": "-L_UIH3wZfIXa2OQACio"
  },
  {
    "dato": "2019-01-19",
    "varer": [
      {
        "strekkode": 7311041013441,
        "mengde": 1,
        "produktID": "7311041013441",
        "totalPris": 17.9,
        "navn": "MusliCrunchy-FirstPrice",
        "pris": 17.9
      },
      {
        "strekkode": 7311041019757,
        "mengde": 7,
        "produktID": "7311041019757",
        "totalPris": 93.8,
        "navn": "Formaggio",
        "pris": 13.4
      }
    ],
    "butikk": "Kiwi",
    "summen": 111.7,
    "UkeNr": 3,
    "timestamp": "Timestamp(seconds=1552081541, nanoseconds=0)",
    "documentID": "-LXzQJC6NgCIxnqQp-hh"
  },
  {
    "dato": "2019-01-17",
    "varer": [
      {
        "strekkode": 101010107724,
        "mengde": 2,
        "produktID": "87UsRoroXvkfLQhionEg",
        "totalPris": 37,
        "navn": "KjøptForAndre",
        "pris": 18.5
      },
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 19.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 19.9
      },
      {
        "strekkode": 7032069722152,
        "mengde": 2,
        "produktID": "7032069722152",
        "totalPris": 10,
        "navn": "Sjampinjong-prima",
        "pris": 5
      },
      {
        "strekkode": 7029161121488,
        "mengde": 1,
        "produktID": "7029161121488",
        "totalPris": 27.5,
        "navn": "Brød-Jubileums",
        "pris": 27.5
      },
      {
        "strekkode": 7038010000737,
        "mengde": 2,
        "produktID": "7038010000737",
        "totalPris": 35.8,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 101010102019,
        "mengde": 0.248,
        "produktID": "SJeGJDQlCAX7XmUe4q1M",
        "totalPris": 4.94,
        "navn": "Løk-løsvekt",
        "pris": 4.94
      },
      {
        "strekkode": 7311250013355,
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 111.1,
        "navn": "Snus General",
        "pris": 111.1
      }
    ],
    "butikk": "Rema",
    "summen": 246.24,
    "UkeNr": 3,
    "timestamp": "Timestamp(seconds=1552081540, nanoseconds=577000000)",
    "documentID": "-L_UGCQ2V4JFpgJir3Ai"
  },
  {
    "dato": "2019-01-15",
    "varer": [
      {
        "strekkode": 7020655860043,
        "mengde": 1,
        "produktID": "7020655860043",
        "totalPris": 23.9,
        "navn": "Brød-SPLEISE",
        "pris": 23.9
      },
      {
        "strekkode": 7314571151003,
        "mengde": 2,
        "produktID": "7314571151003",
        "totalPris": 47.2,
        "navn": "Shampoo-Sport",
        "pris": 23.6
      },
      {
        "strekkode": 101010101906,
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": -0.1,
        "navn": "avrunding",
        "pris": -0.1
      },
      {
        "strekkode": 7070646283320,
        "mengde": 1,
        "produktID": "gYPJMZvTE1ZMDq2uC3wc",
        "totalPris": 229.0,
        "navn": "Whey Protein-1K-PF",
        "pris": 229.0
      }
    ],
    "butikk": "Obs",
    "summen": 300.0,
    "UkeNr": 3,
    "timestamp": "Timestamp(seconds=1552081214, nanoseconds=0)",
    "documentID": "-LXzQ2mdDFqQmT8m_efN"
  },
  {
    "dato": "2019-01-15",
    "varer": [
      {
        "strekkode": 7393173281356,
        "mengde": 1,
        "produktID": "7393173281356",
        "totalPris": 59.9,
        "navn": "Batteri-ClasOhlson X18",
        "pris": 59.9
      }
    ],
    "butikk": "Clas Ohlson",
    "summen": 59.9,
    "UkeNr": 3,
    "timestamp": "Timestamp(seconds=1552081204, nanoseconds=482000000)",
    "documentID": "-L_UEvQBAxt9XAtexXMH"
  },
  {
    "dato": "2019-01-14",
    "varer": [
      {
        "strekkode": 7311041019757,
        "mengde": 3,
        "produktID": "7311041019757",
        "totalPris": 40.2,
        "navn": "Formaggio",
        "pris": 13.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 40.2,
    "UkeNr": 3,
    "timestamp": "Timestamp(seconds=1552081155, nanoseconds=994000000)",
    "documentID": "-L_UEjYossXFzzUACdYJ"
  },
  {
    "dato": "2019-01-14",
    "varer": [
      {
        "strekkode": 7090026220592,
        "mengde": 1,
        "produktID": "7090026220592",
        "totalPris": 59.9,
        "navn": "Egg-24",
        "pris": 59.9
      },
      {
        "strekkode": 7048840081950,
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 24.9,
        "navn": "Melk-stor-0,5-Q",
        "pris": 24.9
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 19.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 19.9
      },
      {
        "strekkode": 101010107724,
        "mengde": 1,
        "produktID": "87UsRoroXvkfLQhionEg",
        "totalPris": 109.0,
        "navn": "KjøptForAndre",
        "pris": 109.0
      },
      {
        "strekkode": 7311041029299,
        "mengde": 1,
        "produktID": "7311041029299",
        "totalPris": 11.5,
        "navn": "Pesto grønn- Eldorado",
        "pris": 11.5
      },
      {
        "strekkode": 101010108462,
        "mengde": 1,
        "produktID": "alzmU8vv3SbAsDiaMlmr",
        "totalPris": 1.6,
        "navn": "Pose",
        "pris": 1.6
      },
      {
        "strekkode": 7311250083976,
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 91.2,
        "navn": "Snus G4",
        "pris": 91.2
      }
    ],
    "butikk": "Rema",
    "summen": 335.9,
    "UkeNr": 3
  },
  {
    "dato": "2019-01-14",
    "varer": [
      {
        "strekkode": 7311041013557,
        "mengde": 1,
        "produktID": "7311041013557",
        "totalPris": 18.6,
        "navn": "Fiskepinner-FirstPrice",
        "pris": 18.6
      }
    ],
    "butikk": "Bunnpris",
    "summen": 18.6,
    "UkeNr": 3,
    "timestamp": "Timestamp(seconds=1552080643, nanoseconds=484000000)",
    "documentID": "-L_UCm5lSNxrFkGmpDla"
  },
  {
    "dato": "2019-01-13",
    "varer": [
      {
        "strekkode": 7029161117139,
        "mengde": 1,
        "produktID": "7029161117139",
        "totalPris": 33.5,
        "navn": "Brød- GRØVT&GODT",
        "pris": 33.5
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      }
    ],
    "butikk": "Rema",
    "summen": 51.4,
    "UkeNr": 2,
    "timestamp": "Timestamp(seconds=1549399900, nanoseconds=453000000)",
    "documentID": "-LXzQYiFFVpdsDRKc6OA"
  },
  {
    "dato": "2019-01-12",
    "varer": [
      {
        "strekkode": 101010109865,
        "mengde": 2,
        "produktID": "101010109865",
        "totalPris": 89.3,
        "navn": "Shampoo",
        "pris": 44.65
      }
    ],
    "butikk": "Kiwi",
    "summen": 89.3,
    "UkeNr": 2,
    "timestamp": "Timestamp(seconds=1549399418, nanoseconds=950000000)",
    "documentID": "-LXzOiCGf5BPr0T7pgim"
  },
  {
    "dato": "2019-01-08",
    "varer": [
      {
        "strekkode": 7311041013557,
        "mengde": 1,
        "produktID": "7311041013557",
        "totalPris": 21.4,
        "navn": "Fiskepinner-FirstPrice",
        "pris": 21.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 21.4,
    "UkeNr": 2,
    "timestamp": "Timestamp(seconds=1547036263, nanoseconds=453000000)",
    "documentID": "-LVmY-XYGS5kvaGFp9gH"
  },
  {
    "dato": "2019-01-08",
    "varer": [
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 7039610000172,
        "mengde": 1,
        "produktID": "7039610000172",
        "totalPris": 27.9,
        "navn": "Egg-12",
        "pris": 27.9
      },
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 19.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 19.9
      },
      {
        "strekkode": 7038010005459,
        "mengde": 1,
        "produktID": "7038010005459",
        "totalPris": 14.9,
        "navn": "Rømme-lett0,18",
        "pris": 14.9
      },
      {
        "strekkode": 7029161121488,
        "mengde": 1,
        "produktID": "7029161121488",
        "totalPris": 27.5,
        "navn": "Brød-Jubileums",
        "pris": 27.5
      },
      {
        "strekkode": 7311250083976,
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 91.2,
        "navn": "Snus G4",
        "pris": 91.2
      },
      {
        "strekkode": 7311250013355,
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 111.1,
        "navn": "Snus General",
        "pris": 111.1
      }
    ],
    "butikk": "Rema",
    "summen": 310.4,
    "UkeNr": 2,
    "timestamp": "Timestamp(seconds=1547036227, nanoseconds=778000000)",
    "documentID": "-LVmXro4AxdG078GSddC"
  },
  {
    "dato": "2019-01-05",
    "varer": [
      {
        "strekkode": 7029161121488,
        "mengde": 1,
        "produktID": "7029161121488",
        "totalPris": 27.5,
        "navn": "Brød-Jubileums",
        "pris": 27.5
      },
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 19.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 19.9
      },
      {
        "strekkode": 7021010001057,
        "mengde": 1,
        "produktID": "7021010001057",
        "totalPris": 24.9,
        "navn": "Sjokoladepålegg-Nugatti",
        "pris": 24.9
      },
      {
        "strekkode": 1111,
        "mengde": 1,
        "produktID": "wyG67uYPhx4lkDpGsORP",
        "totalPris": 6.7,
        "navn": "Tannborste",
        "pris": 6.7
      }
    ],
    "butikk": "Rema",
    "summen": 79.0,
    "UkeNr": 1,
    "timestamp": "Timestamp(seconds=1547036081, nanoseconds=271000000)",
    "documentID": "-LVmXJ24MuvMLpDedyfI"
  },
  {
    "dato": "2019-01-02",
    "varer": [
      {
        "strekkode": 101010107724,
        "mengde": 5,
        "produktID": "87UsRoroXvkfLQhionEg",
        "totalPris": 85.7,
        "navn": "KjøptForAndre",
        "pris": 17.14
      }
    ],
    "butikk": "Obs",
    "summen": 85.7,
    "UkeNr": 1,
    "timestamp": "Timestamp(seconds=1547035741, nanoseconds=725000000)",
    "documentID": "-LVmW08eFVaWjCV3a3ZR"
  },
  {
    "dato": "2019-01-02",
    "varer": [
      {
        "strekkode": 101010108141,
        "mengde": 1,
        "produktID": "101010108141",
        "totalPris": 29.9,
        "navn": "sykkellykt bak",
        "pris": 29.9
      }
    ],
    "butikk": "Biltema",
    "summen": 29.9,
    "UkeNr": 1,
    "timestamp": "Timestamp(seconds=1547035504, nanoseconds=730000000)",
    "documentID": "-LVmV6Hc-Uz_JJGeJAKh"
  },
  {
    "dato": "2018-12-31",
    "varer": [
      {
        "strekkode": 101010107724,
        "mengde": 1,
        "produktID": "87UsRoroXvkfLQhionEg",
        "totalPris": 17.9,
        "navn": "KjøptForAndre",
        "pris": 17.9
      }
    ],
    "butikk": "Meny",
    "summen": 17.9,
    "UkeNr": 1,
    "timestamp": "Timestamp(seconds=1547035260, nanoseconds=855000000)",
    "documentID": "-LVmUAkvvSrbuISnzsjU"
  },
  {
    "dato": "2018-12-31",
    "varer": [
      {
        "strekkode": 101010107724,
        "mengde": 2,
        "produktID": "87UsRoroXvkfLQhionEg",
        "totalPris": 58.0,
        "navn": "KjøptForAndre",
        "pris": 29.0
      }
    ],
    "butikk": "Meny",
    "summen": 58.0,
    "UkeNr": 1,
    "timestamp": "Timestamp(seconds=1547035213, nanoseconds=288000000)",
    "documentID": "-LVmU-8jEmcWBchnUENz"
  },
  {
    "dato": "2018-12-27",
    "varer": [
      {
        "strekkode": 101010107724,
        "mengde": 1,
        "produktID": "87UsRoroXvkfLQhionEg",
        "totalPris": 170.1,
        "navn": "KjøptForAndre",
        "pris": 170.1
      }
    ],
    "butikk": "Meny",
    "summen": 170.1,
    "UkeNr": 52,
    "timestamp": "Timestamp(seconds=1547035161, nanoseconds=534000000)",
    "documentID": "-LVmTnW1lihKgGJoaAMA"
  },
  {
    "dato": "2018-12-22",
    "varer": [
      {
        "strekkode": 101010107724,
        "mengde": 5,
        "produktID": "87UsRoroXvkfLQhionEg",
        "totalPris": 141.7,
        "navn": "KjøptForAndre",
        "pris": 28.34
      }
    ],
    "butikk": "Obs",
    "summen": 141.7,
    "UkeNr": 51,
    "timestamp": "Timestamp(seconds=1547035112, nanoseconds=406000000)",
    "documentID": "-LVmTbWQJQP-ls4NlXau"
  },
  {
    "dato": "2018-12-21",
    "varer": [
      {
        "strekkode": 101010107724,
        "mengde": 11,
        "produktID": "87UsRoroXvkfLQhionEg",
        "totalPris": 160.3,
        "navn": "KjøptForAndre",
        "pris": 14.57
      }
    ],
    "butikk": "Rema",
    "summen": 160.3,
    "UkeNr": 51,
    "timestamp": "Timestamp(seconds=1547035058, nanoseconds=823000000)",
    "documentID": "-LVmTPQ2ce6rRRHag_4I"
  },
  {
    "dato": "2018-12-22",
    "varer": [
      {
        "strekkode": 101010105157,
        "mengde": 1,
        "produktID": "101010105157",
        "totalPris": 258.0,
        "navn": "SSD Kingston A400 120GB",
        "pris": 258.0
      },
      {
        "strekkode": 101010103382,
        "mengde": 1,
        "produktID": "101010103382",
        "totalPris": 36.0,
        "navn": "USB-minne",
        "pris": 36.0
      }
    ],
    "butikk": "NetOnNet",
    "summen": 294.0,
    "UkeNr": 51,
    "timestamp": "Timestamp(seconds=1547034831, nanoseconds=223000000)",
    "documentID": "-LVmSXqfFHqZXnWvm6j_"
  },
  {
    "dato": "2018-12-22",
    "varer": [
      {
        "strekkode": 101010106772,
        "mengde": 1,
        "produktID": "101010106772",
        "totalPris": 99.9,
        "navn": "Lydkabel for headset",
        "pris": 99.9
      },
      {
        "strekkode": 101010109926,
        "mengde": 1,
        "produktID": "101010109926",
        "totalPris": 199.0,
        "navn": "Lydkort USB",
        "pris": 199.0
      }
    ],
    "butikk": "Clas Ohlson",
    "summen": 298.9,
    "UkeNr": 51,
    "timestamp": "Timestamp(seconds=1547034356, nanoseconds=3000000)",
    "documentID": "-LVmQiovtiI2WsYNlz0-"
  },
  {
    "dato": "2018-12-13",
    "varer": [
      {
        "strekkode": 7311250013355,
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 109.5,
        "navn": "Snus General",
        "pris": 109.5
      }
    ],
    "butikk": "Extra",
    "summen": 109.5,
    "UkeNr": 50,
    "timestamp": "Timestamp(seconds=1547033248, nanoseconds=219000000)",
    "documentID": "-LVmMVMy_1PDZuwDLWeI"
  },
  {
    "dato": "2018-12-04",
    "varer": [
      {
        "strekkode": 7311250013355,
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 114.0,
        "navn": "Snus General",
        "pris": 114.0
      }
    ],
    "butikk": "Bunnpris",
    "summen": 114.0,
    "UkeNr": 49,
    "timestamp": "Timestamp(seconds=1547033170, nanoseconds=87000000)",
    "documentID": "-LVmMCF7N0Ptj44uFja1"
  },
  {
    "dato": "2018-12-18",
    "varer": [
      {
        "strekkode": 101010101029,
        "mengde": 1,
        "produktID": "8bH8ZfnbTOU1AhE3e5N9",
        "totalPris": 8.0,
        "navn": "Konvolutt",
        "pris": 8.0
      },
      {
        "strekkode": 101010104686,
        "mengde": 1,
        "produktID": "101010104686",
        "totalPris": 38.0,
        "navn": "brevsendings porto",
        "pris": 38.0
      }
    ],
    "butikk": "Posten",
    "summen": 46.0,
    "UkeNr": 51,
    "timestamp": "Timestamp(seconds=1545294379, nanoseconds=443000000)",
    "documentID": "-LU9iE8OsxkdZfINMFJi"
  },
  {
    "dato": "2018-12-18",
    "varer": [
      {
        "strekkode": 101010108462,
        "mengde": 1,
        "produktID": "alzmU8vv3SbAsDiaMlmr",
        "totalPris": 1.6,
        "navn": "Pose",
        "pris": 1.6
      },
      {
        "strekkode": 101010101975,
        "mengde": 1,
        "produktID": "101010101975",
        "totalPris": 40.4,
        "navn": "Ost skiver-Jarlsbergost",
        "pris": 40.4
      },
      {
        "strekkode": 11111,
        "mengde": 1,
        "produktID": "h7mi21cM59LmbSoppzZw",
        "totalPris": 99.0,
        "navn": "Toalettpapir",
        "pris": 99.0
      },
      {
        "strekkode": 2302148200006,
        "mengde": 1,
        "produktID": "2302148200006",
        "totalPris": 68.99,
        "navn": "Norvegia-1K",
        "pris": 68.99
      }
    ],
    "butikk": "Obs",
    "summen": 209.99,
    "UkeNr": 51,
    "timestamp": "Timestamp(seconds=1545294167, nanoseconds=159000000)",
    "documentID": "-LU9hQQhrWL5jXC_w5zA"
  },
  {
    "dato": "2018-12-18",
    "varer": [
      {
        "strekkode": 7311250083976,
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 90.4,
        "navn": "Snus G4",
        "pris": 90.4
      },
      {
        "strekkode": 7070646283320,
        "mengde": 1,
        "produktID": "gYPJMZvTE1ZMDq2uC3wc",
        "totalPris": 229.0,
        "navn": "Whey Protein-1K-PF",
        "pris": 229.0
      }
    ],
    "butikk": "Obs",
    "summen": 319.4,
    "UkeNr": 51,
    "timestamp": "Timestamp(seconds=1545294069, nanoseconds=937000000)",
    "documentID": "-LU9h2fRI3QVw_8MDwmd"
  },
  {
    "dato": "2018-12-18",
    "varer": [
      {
        "strekkode": 101010101432,
        "mengde": 1,
        "produktID": "101010101432",
        "totalPris": 69.0,
        "navn": "Drikkeglass",
        "pris": 69.0
      },
      {
        "strekkode": 101010103832,
        "mengde": 1,
        "produktID": "101010103832",
        "totalPris": 49.0,
        "navn": "Tallerken ",
        "pris": 49.0
      }
    ],
    "butikk": "Obs",
    "summen": 118.0,
    "UkeNr": 51,
    "timestamp": "Timestamp(seconds=1545293987, nanoseconds=834000000)",
    "documentID": "-LU9gjb7qYoQMLQqAZQZ"
  },
  {
    "dato": "2018-12-17",
    "varer": [
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 19.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 19.9
      },
      {
        "strekkode": 7020655860043,
        "mengde": 1,
        "produktID": "7020655860043",
        "totalPris": 23.5,
        "navn": "Brød-SPLEISE",
        "pris": 23.5
      }
    ],
    "butikk": "Rema",
    "summen": 43.4,
    "UkeNr": 51,
    "timestamp": "Timestamp(seconds=1545293870, nanoseconds=65000000)",
    "documentID": "-LU9gHxc5ZWbgdIEeJb3"
  },
  {
    "dato": "2018-12-17",
    "varer": [
      {
        "strekkode": 7311041029299,
        "mengde": 1,
        "produktID": "7311041029299",
        "totalPris": 12.5,
        "navn": "Pesto grønn- Eldorado",
        "pris": 12.5
      },
      {
        "strekkode": 7038010005459,
        "mengde": 1,
        "produktID": "7038010005459",
        "totalPris": 16.9,
        "navn": "Rømme-lett0,18",
        "pris": 16.9
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 19.9,
        "navn": "KulturMelk",
        "pris": 19.9
      },
      {
        "strekkode": 7038010000911,
        "mengde": 1,
        "produktID": "7038010000911",
        "totalPris": 25.9,
        "navn": "Melk-stor-0,5-Tine",
        "pris": 25.9
      }
    ],
    "butikk": "Bunnpris",
    "summen": 75.2,
    "UkeNr": 51,
    "timestamp": "Timestamp(seconds=1545293822, nanoseconds=244000000)",
    "documentID": "-LU9g6AC7MxmRyrEhaET"
  },
  {
    "dato": "2018-12-17",
    "varer": [
      {
        "strekkode": 1111,
        "mengde": 1,
        "produktID": "4EHpBRhZKxqMdg1jHwvB",
        "totalPris": 24.9,
        "navn": "Tøyvask",
        "pris": 24.9
      }
    ],
    "butikk": "Bunnpris",
    "summen": 24.9,
    "UkeNr": 51,
    "timestamp": "Timestamp(seconds=1545293734, nanoseconds=342000000)",
    "documentID": "-LU9flp4HxFPujUIodWQ"
  },
  {
    "dato": "2018-12-15",
    "varer": [
      {
        "strekkode": 7311041019757,
        "mengde": 7,
        "produktID": "7311041019757",
        "totalPris": 93.8,
        "navn": "Formaggio",
        "pris": 13.4
      }
    ],
    "butikk": "Kiwi",
    "summen": 93.8,
    "UkeNr": 50,
    "timestamp": "Timestamp(seconds=1545293704, nanoseconds=103000000)",
    "documentID": "-LU9feNTom-84XmXhyXO"
  },
  {
    "dato": "2018-12-15",
    "varer": [
      {
        "strekkode": 7032069715253,
        "mengde": 1,
        "produktID": "7032069715253",
        "totalPris": 17.9,
        "navn": "MusliCrunchy-Rema1000",
        "pris": 17.9
      },
      {
        "strekkode": 7020655860043,
        "mengde": 1,
        "produktID": "7020655860043",
        "totalPris": 23.5,
        "navn": "Brød-SPLEISE",
        "pris": 23.5
      }
    ],
    "butikk": "Rema",
    "summen": 41.4,
    "UkeNr": 50,
    "timestamp": "Timestamp(seconds=1545293652, nanoseconds=682000000)",
    "documentID": "-LU9fSnTkRZkx10hk_GE"
  },
  {
    "dato": "2018-12-14",
    "varer": [
      {
        "strekkode": 101010109346,
        "mengde": 1,
        "produktID": "101010109346",
        "totalPris": -93.8,
        "navn": "Feil",
        "pris": -93.8
      },
      {
        "strekkode": 7311250013355,
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 113.8,
        "navn": "Snus General",
        "pris": 113.8
      },
      {
        "strekkode": 101010101906,
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": 0.8,
        "navn": "avrunding",
        "pris": 0.8
      }
    ],
    "butikk": "Bunnpris",
    "summen": 20.8,
    "UkeNr": 50,
    "timestamp": "Timestamp(seconds=1545293542, nanoseconds=830000000)",
    "documentID": "-LU9f1zNIoW3J9gfP1qE"
  },
  {
    "dato": "2018-12-13",
    "varer": [
      {
        "strekkode": 7311250083976,
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 90.0,
        "navn": "Snus G4",
        "pris": 90.0
      },
      {
        "strekkode": 101010109346,
        "mengde": 1,
        "produktID": "101010109346",
        "totalPris": 93.8,
        "navn": "Feil",
        "pris": 93.8
      }
    ],
    "butikk": "Bunnpris",
    "summen": 183.8,
    "UkeNr": 50,
    "timestamp": "Timestamp(seconds=1545293212, nanoseconds=610000000)",
    "documentID": "-LU9dmO93LFN_jj0oVei"
  },
  {
    "dato": "2018-12-14",
    "varer": [
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 21.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 21.9
      },
      {
        "strekkode": 7311041013557,
        "mengde": 1,
        "produktID": "7311041013557",
        "totalPris": 21.5,
        "navn": "Fiskepinner-FirstPrice",
        "pris": 21.5
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 19.9,
        "navn": "KulturMelk",
        "pris": 19.9
      }
    ],
    "butikk": "Bunnpris",
    "summen": 63.3,
    "UkeNr": 50,
    "timestamp": "Timestamp(seconds=1545292051, nanoseconds=803000000)",
    "documentID": "-LU9_M-1jC25tezwHe6E"
  },
  {
    "dato": "2018-12-12",
    "varer": [
      {
        "strekkode": 7038010005459,
        "mengde": 1,
        "produktID": "7038010005459",
        "totalPris": 16.9,
        "navn": "Rømme-lett0,18",
        "pris": 16.9
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 19.9,
        "navn": "KulturMelk",
        "pris": 19.9
      },
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 21.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 21.9
      },
      {
        "strekkode": 7038010001918,
        "mengde": 1,
        "produktID": "7038010001918",
        "totalPris": 25.9,
        "navn": "Melk-1L-0,5-Tine",
        "pris": 25.9
      },
      {
        "strekkode": 7041614000867,
        "mengde": 1,
        "produktID": "7041614000867",
        "totalPris": 18.5,
        "navn": "Brød-HVERDAGSGROVT",
        "pris": 18.5
      },
      {
        "strekkode": 7050122131611,
        "mengde": 1,
        "produktID": "7050122131611",
        "totalPris": 49.5,
        "navn": "Dipmix",
        "pris": 49.5
      }
    ],
    "butikk": "Bunnpris",
    "summen": 152.6,
    "UkeNr": 50,
    "timestamp": "Timestamp(seconds=1545291981, nanoseconds=586000000)",
    "documentID": "-LU9_4moAL0bn41tEi87"
  },
  {
    "dato": "2018-12-09",
    "varer": [
      {
        "strekkode": 7029161117139,
        "mengde": 1,
        "produktID": "7029161117139",
        "totalPris": 33.5,
        "navn": "Brød- GRØVT&GODT",
        "pris": 33.5
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      }
    ],
    "butikk": "Rema",
    "summen": 51.4,
    "UkeNr": 49,
    "timestamp": "Timestamp(seconds=1545291673, nanoseconds=619000000)",
    "documentID": "-LU9YugS3tqEPTXXYCht"
  },
  {
    "dato": "2018-12-08",
    "varer": [
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 19.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 19.9
      }
    ],
    "butikk": "Rema",
    "summen": 19.9,
    "UkeNr": 49,
    "timestamp": "Timestamp(seconds=1545291626, nanoseconds=514000000)",
    "documentID": "-LU9YjCKSJdPKcsdrDT6"
  },
  {
    "dato": "2018-12-07",
    "varer": [
      {
        "strekkode": 101010102637,
        "mengde": 1,
        "produktID": "101010102637",
        "totalPris": 33.9,
        "navn": "Rørisolasjon",
        "pris": 33.9
      }
    ],
    "butikk": "ObsBygg",
    "summen": 33.9,
    "UkeNr": 49,
    "timestamp": "Timestamp(seconds=1544202182, nanoseconds=211000000)",
    "documentID": "-LT8bpm4jeMBI0JqLb7P"
  },
  {
    "dato": "2018-12-05",
    "varer": [
      {
        "strekkode": 101010104525,
        "mengde": 2,
        "produktID": "101010104525",
        "totalPris": 12.9,
        "navn": "hvitløk ",
        "pris": 6.45
      },
      {
        "strekkode": 7311041013557,
        "mengde": 1,
        "produktID": "7311041013557",
        "totalPris": 21.5,
        "navn": "Fiskepinner-FirstPrice",
        "pris": 21.5
      },
      {
        "strekkode": 7041611018124,
        "mengde": 1,
        "produktID": "7041611018124",
        "totalPris": 15.0,
        "navn": "Brød-NORSK FJELLBRØD",
        "pris": 15.0
      },
      {
        "strekkode": 7311041019757,
        "mengde": 7,
        "produktID": "7311041019757",
        "totalPris": 93.8,
        "navn": "Formaggio",
        "pris": 13.4
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 19.9,
        "navn": "KulturMelk",
        "pris": 19.9
      },
      {
        "strekkode": 7048840081950,
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 25.9,
        "navn": "Melk-stor-0,5-Q",
        "pris": 25.9
      },
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 21.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 21.9
      }
    ],
    "butikk": "Bunnpris",
    "summen": 210.9,
    "UkeNr": 49,
    "timestamp": "Timestamp(seconds=1544202009, nanoseconds=801000000)",
    "documentID": "-LT8bAe3brI1_c24GgUn"
  },
  {
    "dato": "2018-12-07",
    "varer": [
      {
        "strekkode": 7032069715253,
        "mengde": 1,
        "produktID": "7032069715253",
        "totalPris": 17.9,
        "navn": "MusliCrunchy-Rema1000",
        "pris": 17.9
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 7090026220592,
        "mengde": 1,
        "produktID": "7090026220592",
        "totalPris": 59.9,
        "navn": "Egg-24",
        "pris": 59.9
      },
      {
        "strekkode": 7311250083976,
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 90.4,
        "navn": "Snus G4",
        "pris": 90.4
      }
    ],
    "butikk": "Rema",
    "summen": 186.1,
    "UkeNr": 49,
    "timestamp": "Timestamp(seconds=1544201764, nanoseconds=545000000)",
    "documentID": "-LT8aEkbfKGgOmODkV3g"
  },
  {
    "dato": "2018-12-04",
    "varer": [
      {
        "strekkode": 101010106291,
        "mengde": 1,
        "produktID": "101010106291",
        "totalPris": 9.9,
        "navn": "Klor FirstPrice",
        "pris": 9.9
      },
      {
        "strekkode": 101010101906,
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": 0.1,
        "navn": "avrunding",
        "pris": 0.1
      }
    ],
    "butikk": "Bunnpris",
    "summen": 10.0,
    "UkeNr": 49,
    "timestamp": "Timestamp(seconds=1544200893, nanoseconds=828000000)",
    "documentID": "-LT8Xv5m-8Qq1ojSW0H9"
  },
  {
    "dato": "2018-12-03",
    "varer": [
      {
        "strekkode": 101010104969,
        "mengde": 1,
        "produktID": "101010104969",
        "totalPris": 39.9,
        "navn": "Vevteip",
        "pris": 39.9
      },
      {
        "strekkode": 101010104143,
        "mengde": 1,
        "produktID": "101010104143",
        "totalPris": 15.9,
        "navn": "slipeark",
        "pris": 15.9
      },
      {
        "strekkode": 101010101906,
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": 0.2,
        "navn": "avrunding",
        "pris": 0.2
      }
    ],
    "butikk": "Clas Ohlson",
    "summen": 56.0,
    "UkeNr": 49,
    "timestamp": "Timestamp(seconds=1544200828, nanoseconds=807000000)",
    "documentID": "-LT8XfJVJASQQnf6Hmi4"
  },
  {
    "dato": "2018-12-03",
    "varer": [
      {
        "strekkode": 101010103979,
        "mengde": 1,
        "produktID": "101010103979",
        "totalPris": 998.0,
        "navn": "Sykkeldekk ",
        "pris": 998.0
      }
    ],
    "butikk": "XXL",
    "summen": 998.0,
    "UkeNr": 49,
    "timestamp": "Timestamp(seconds=1544200500, nanoseconds=765000000)",
    "documentID": "-LT8WQGyf1TPm2cm2RXm"
  },
  {
    "dato": "2018-12-02",
    "varer": [
      {
        "strekkode": 7311041048931,
        "mengde": 1,
        "produktID": "7311041048931",
        "totalPris": 32.9,
        "navn": "NøtterMix",
        "pris": 32.9
      },
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 19.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 19.9
      },
      {
        "strekkode": 7029161117139,
        "mengde": 1,
        "produktID": "7029161117139",
        "totalPris": 33.5,
        "navn": "Brød- GRØVT&GODT",
        "pris": 33.5
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 101010101906,
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": -0.2,
        "navn": "avrunding",
        "pris": -0.2
      }
    ],
    "butikk": "Rema",
    "summen": 104.0,
    "UkeNr": 48,
    "timestamp": "Timestamp(seconds=1544200370, nanoseconds=653000000)",
    "documentID": "-LT8Vv8C0iv0qTJmdmAX"
  },
  {
    "dato": "2018-11-29",
    "varer": [
      {
        "strekkode": 7041614000867,
        "mengde": 1,
        "produktID": "7041614000867",
        "totalPris": 18.5,
        "navn": "Brød-HVERDAGSGROVT",
        "pris": 18.5
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 19.9,
        "navn": "KulturMelk",
        "pris": 19.9
      },
      {
        "strekkode": 101010101906,
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": -0.4,
        "navn": "avrunding",
        "pris": -0.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 38.0,
    "UkeNr": 48,
    "timestamp": "Timestamp(seconds=1544200008, nanoseconds=702000000)",
    "documentID": "-LT8UY6nQj7yNhY0Ghyy"
  },
  {
    "dato": "2018-11-27",
    "varer": [
      {
        "strekkode": 7613035962965,
        "mengde": 1,
        "produktID": "7613035962965",
        "totalPris": 28.3,
        "navn": "Nescafe-Gull",
        "pris": 28.3
      },
      {
        "strekkode": 7032069726600,
        "mengde": 4,
        "produktID": "ErL7PujeMYUwt6xvepLO",
        "totalPris": 47.6,
        "navn": "Bakeark",
        "pris": 11.9
      },
      {
        "strekkode": 101010106475,
        "mengde": 1,
        "produktID": "101010106475",
        "totalPris": 59.9,
        "navn": "Listerine ",
        "pris": 59.9
      },
      {
        "strekkode": 101010101906,
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": 0.3,
        "navn": "avrunding",
        "pris": 0.3
      },
      {
        "strekkode": 101010106765,
        "mengde": 1,
        "produktID": "101010106765",
        "totalPris": 14.9,
        "navn": "Pose - Brødpose",
        "pris": 14.9
      }
    ],
    "butikk": "Rema",
    "summen": 151.0,
    "UkeNr": 48,
    "timestamp": "Timestamp(seconds=1544199930, nanoseconds=331000000)",
    "documentID": "-LT8UExfggO1rqXuXA-E"
  },
  {
    "dato": "2018-11-26",
    "varer": [
      {
        "strekkode": 101010105065,
        "mengde": 2,
        "produktID": "101010105065",
        "totalPris": 698.0,
        "navn": "Vektskiver",
        "pris": 349.0
      }
    ],
    "butikk": "XXL",
    "summen": 698.0,
    "UkeNr": 48,
    "timestamp": "Timestamp(seconds=1544197946, nanoseconds=631000000)",
    "documentID": "-LT8MferGq4lCDthAp-u"
  },
  {
    "dato": "2018-11-23",
    "varer": [
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 19.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 19.9
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 7048840081950,
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 24.9,
        "navn": "Melk-stor-0,5-Q",
        "pris": 24.9
      },
      {
        "strekkode": 7090026220592,
        "mengde": 1,
        "produktID": "7090026220592",
        "totalPris": 59.9,
        "navn": "Egg-24",
        "pris": 59.9
      },
      {
        "strekkode": 7032069715253,
        "mengde": 1,
        "produktID": "7032069715253",
        "totalPris": 17.9,
        "navn": "MusliCrunchy-Rema1000",
        "pris": 17.9
      },
      {
        "strekkode": 7029161111724,
        "mengde": 1,
        "produktID": "7029161111724",
        "totalPris": 20.0,
        "navn": "brød-BRANN",
        "pris": 20.0
      }
    ],
    "butikk": "Rema",
    "summen": 160.5,
    "UkeNr": 47,
    "timestamp": "Timestamp(seconds=1544197452, nanoseconds=921000000)",
    "documentID": "-LT8Kn5vQ_A2v_lnICO0"
  },
  {
    "dato": "2018-11-23",
    "varer": [
      {
        "strekkode": 101010107021,
        "mengde": 1,
        "produktID": "101010107021",
        "totalPris": 995.0,
        "navn": "Lenovo L24e-20",
        "pris": 995.0
      }
    ],
    "butikk": "Elkjøp ",
    "summen": 995.0,
    "UkeNr": 47,
    "timestamp": "Timestamp(seconds=1544197343, nanoseconds=979000000)",
    "documentID": "-LT8KNRROgQ_Kah1i5gO"
  },
  {
    "dato": "2018-11-21",
    "varer": [
      {
        "strekkode": 7311041019757,
        "mengde": 8,
        "produktID": "7311041019757",
        "totalPris": 107.2,
        "navn": "Formaggio",
        "pris": 13.4
      },
      {
        "strekkode": 7311041029299,
        "mengde": 1,
        "produktID": "7311041029299",
        "totalPris": 10.9,
        "navn": "Pesto grønn- Eldorado",
        "pris": 10.9
      },
      {
        "strekkode": 7311250083976,
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 89.0,
        "navn": "Snus G4",
        "pris": 89.0
      },
      {
        "strekkode": 101010101906,
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": -0.1,
        "navn": "avrunding",
        "pris": -0.1
      }
    ],
    "butikk": "Kiwi",
    "summen": 207.0,
    "UkeNr": 47,
    "timestamp": "Timestamp(seconds=1544193092, nanoseconds=89000000)",
    "documentID": "-LT847fGYWMM5WF7YPpe"
  },
  {
    "dato": "2018-11-20",
    "varer": [
      {
        "strekkode": 101010107625,
        "mengde": 1,
        "produktID": "101010107625",
        "totalPris": 29.9,
        "navn": "skuerskive M3",
        "pris": 29.9
      },
      {
        "strekkode": 101010101906,
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": 0.1,
        "navn": "avrunding",
        "pris": 0.1
      }
    ],
    "butikk": "Clas Ohlson",
    "summen": 30.0,
    "UkeNr": 47,
    "timestamp": "Timestamp(seconds=1544191090, nanoseconds=302000000)",
    "documentID": "-LT7xWVUtiyLGYIP9iIO"
  },
  {
    "dato": "2018-11-20",
    "varer": [
      {
        "strekkode": 101010105522,
        "mengde": 1,
        "produktID": "101010105522",
        "totalPris": 21.9,
        "navn": "sporskruer",
        "pris": 21.9
      },
      {
        "strekkode": 101010104105,
        "mengde": 1,
        "produktID": "101010104105",
        "totalPris": 24.9,
        "navn": "Mutter M3",
        "pris": 24.9
      },
      {
        "strekkode": 101010101906,
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": 0.2,
        "navn": "avrunding",
        "pris": 0.2
      }
    ],
    "butikk": "Clas Ohlson",
    "summen": 47.0,
    "UkeNr": 47,
    "timestamp": "Timestamp(seconds=1544191021, nanoseconds=953000000)",
    "documentID": "-LT7xFfnPXcxqN8ZvJnk"
  },
  {
    "dato": "2018-11-19",
    "varer": [
      {
        "strekkode": 101010102804,
        "mengde": 1,
        "produktID": "101010102804",
        "totalPris": 99.0,
        "navn": "Brukt belte",
        "pris": 99.0
      }
    ],
    "butikk": "Fretex",
    "summen": 99.0,
    "UkeNr": 47,
    "timestamp": "Timestamp(seconds=1542834667, nanoseconds=188000000)",
    "documentID": "-LRs6AmWWeA9wppNf1o2"
  },
  {
    "dato": "2018-11-20",
    "varer": [
      {
        "strekkode": 7029161111724,
        "mengde": 1,
        "produktID": "7029161111724",
        "totalPris": 20.0,
        "navn": "brød-BRANN",
        "pris": 20.0
      },
      {
        "strekkode": 1111,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 19.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 19.9
      },
      {
        "strekkode": 7032069722152,
        "mengde": 2,
        "produktID": "7032069722152",
        "totalPris": 10.0,
        "navn": "Sjampinjong-prima",
        "pris": 5.0
      },
      {
        "strekkode": 7038010005459,
        "mengde": 1,
        "produktID": "7038010005459",
        "totalPris": 14.9,
        "navn": "Rømme-lett0,18",
        "pris": 14.9
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 7311250013355,
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 109.5,
        "navn": "Snus General",
        "pris": 109.5
      },
      {
        "strekkode": 11111,
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": -0.2,
        "navn": "avrunding",
        "pris": -0.2
      }
    ],
    "butikk": "Rema",
    "summen": 192.0,
    "UkeNr": 47,
    "timestamp": "Timestamp(seconds=1542825825, nanoseconds=223000000)",
    "documentID": "-LRr_S1Ri-2dcGNS1Z6-"
  },
  {
    "dato": "2018-11-19",
    "varer": [
      {
        "strekkode": 7045010003019,
        "mengde": 1,
        "produktID": "7045010003019",
        "totalPris": 22.4,
        "navn": "Basilikum - Hindu",
        "pris": 22.4
      },
      {
        "strekkode": 7311041013557,
        "mengde": 1,
        "produktID": "7311041013557",
        "totalPris": 21.5,
        "navn": "Fiskepinner-FirstPrice",
        "pris": 21.5
      },
      {
        "strekkode": 7311041019757,
        "mengde": 3,
        "produktID": "7311041019757",
        "totalPris": 40.2,
        "navn": "Formaggio",
        "pris": 13.4
      },
      {
        "strekkode": 7311041013519,
        "mengde": 1,
        "produktID": "7311041013519",
        "totalPris": 10.0,
        "navn": "Spaghetti",
        "pris": 10.0
      },
      {
        "strekkode": 111111,
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": -0.1,
        "navn": "avrunding",
        "pris": -0.1
      }
    ],
    "butikk": "Bunnpris",
    "summen": 94.0,
    "UkeNr": 47,
    "timestamp": "Timestamp(seconds=1542825311, nanoseconds=129000000)",
    "documentID": "-LRrYUXFlNUWqxeYpO5T"
  },
  {
    "dato": "2018-11-18",
    "varer": [
      {
        "strekkode": 7029161117139,
        "mengde": 1,
        "produktID": "7029161117139",
        "totalPris": 25.0,
        "navn": "Brød- GRØVT&GODT",
        "pris": 25.0
      },
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 19.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 19.9
      },
      {
        "strekkode": 7038010000737,
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "strekkode": 111111,
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": 0.2,
        "navn": "avrunding",
        "pris": 0.2
      }
    ],
    "butikk": "Rema",
    "summen": 63.0,
    "UkeNr": 46,
    "timestamp": "Timestamp(seconds=1542822379, nanoseconds=247000000)",
    "documentID": "-LRrNIix5nhwZPWDO_WN"
  },
  {
    "dato": "2018-11-16",
    "varer": [
      {
        "strekkode": 101010,
        "mengde": 2,
        "produktID": "87UsRoroXvkfLQhionEg",
        "totalPris": 34.8,
        "navn": "KjøptForAndre",
        "pris": 17.4
      },
      {
        "strekkode": 7032069715253,
        "mengde": 1,
        "produktID": "7032069715253",
        "totalPris": 17.9,
        "navn": "MusliCrunchy-Rema1000",
        "pris": 17.9
      },
      {
        "strekkode": 7311250083976,
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 90.4,
        "navn": "Snus G4",
        "pris": 90.4
      },
      {
        "strekkode": 11111,
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": -0.1,
        "navn": "avrunding",
        "pris": -0.1
      }
    ],
    "butikk": "Rema",
    "summen": 143.0,
    "UkeNr": 46,
    "timestamp": "Timestamp(seconds=1542822245, nanoseconds=901000000)",
    "documentID": "-LRrMn7dSkXVJMalkRAh"
  },
  {
    "dato": "2018-11-16",
    "varer": [
      {
        "strekkode": 7039610000172,
        "mengde": 1,
        "produktID": "7039610000172",
        "totalPris": 28.9,
        "navn": "Egg-12",
        "pris": 28.9
      },
      {
        "strekkode": 11111,
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": 0.1,
        "navn": "avrunding",
        "pris": 0.1
      }
    ],
    "butikk": "Rema",
    "summen": 29.0,
    "UkeNr": 46,
    "timestamp": "Timestamp(seconds=1542822140, nanoseconds=636000000)",
    "documentID": "-LRrMOXrOeWTQTEtNZBc"
  },
  {
    "dato": "2018-11-02",
    "varer": [
      {
        "strekkode": 7050122131611,
        "mengde": 1,
        "produktID": "7050122131611",
        "totalPris": 13.9,
        "navn": "Dipmix",
        "pris": 13.9
      },
      {
        "strekkode": 7038010000737,
        "mengde": 2,
        "produktID": "7038010000737",
        "totalPris": 36.8,
        "navn": "KulturMelk",
        "pris": 18.4
      },
      {
        "strekkode": 7038010055690,
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 19.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 19.9
      },
      {
        "strekkode": 7038010055652,
        "mengde": 1,
        "produktID": "7038010055652",
        "totalPris": 12.0,
        "navn": "Yoghurt-0,5K-naturell",
        "pris": 12.0
      },
      {
        "strekkode": 7613035962965,
        "mengde": 1,
        "produktID": "7613035962965",
        "totalPris": 28.3,
        "navn": "Nescafe-Gull",
        "pris": 28.3
      },
      {
        "strekkode": 7090026220592,
        "mengde": 1,
        "produktID": "7090026220592",
        "totalPris": 59.9,
        "navn": "Egg-24",
        "pris": 59.9
      }
    ],
    "butikk": "Rema",
    "summen": 170.8,
    "UkeNr": 44,
    "timestamp": "Timestamp(seconds=1542822086, nanoseconds=737000000)",
    "documentID": "-LRrMBBw4ZCksKVFPWoQ"
  },
  {
    "dato": "2018-11-15",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 23.4,
        "navn": "Melk-stor-0,5-Q",
        "pris": 23.4
      },
      {
        "mengde": 1,
        "produktID": "7020655860043",
        "totalPris": 23.9,
        "navn": "Brød-SPLEISE",
        "pris": 23.9
      },
      {
        "mengde": 1,
        "produktID": "2382664409732",
        "totalPris": 109.95,
        "navn": "Ost synnøve-Gouda-1K",
        "pris": 109.95
      },
      {
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 19.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 19.9
      }
    ],
    "butikk": "CoopExtra",
    "summen": 195.05,
    "UkeNr": 46,
    "timestamp": "Timestamp(seconds=1542291615, nanoseconds=200000000)",
    "documentID": "-LRMjaWeAF3OkhbfP3hu"
  },
  {
    "dato": "2018-11-12",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7020655860043",
        "totalPris": 35.9,
        "navn": "Brød-SPLEISE",
        "pris": 35.9
      },
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 19.9,
        "navn": "KulturMelk",
        "pris": 19.9
      },
      {
        "mengde": 1,
        "produktID": "7038010005459",
        "totalPris": 16.9,
        "navn": "Rømme-lett0,18",
        "pris": 16.9
      },
      {
        "mengde": 1,
        "produktID": "7037421061559",
        "totalPris": 39.9,
        "navn": "Julekaker ",
        "pris": 39.9
      },
      {
        "mengde": 1,
        "produktID": "7038010000911",
        "totalPris": 26.7,
        "navn": "Melk-stor-0,5-Tine",
        "pris": 26.7
      },
      {
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 21.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 21.9
      },
      {
        "mengde": 3,
        "produktID": "7050122131611",
        "totalPris": 49.5,
        "navn": "Dipmix",
        "pris": 16.5
      },
      {
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 113.8,
        "navn": "Snus General",
        "pris": 113.8
      }
    ],
    "butikk": "Bunnpris",
    "summen": 324.5,
    "UkeNr": 46,
    "timestamp": "Timestamp(seconds=1542227990, nanoseconds=266000000)",
    "documentID": "-LRIwt2po85IEHhaFAs3"
  },
  {
    "dato": "2018-11-11",
    "varer": [
      {
        "mengde": 1,
        "produktID": "5710557161110",
        "totalPris": 169.0,
        "navn": "Kjøtt-MB",
        "pris": 169.0
      }
    ],
    "butikk": "SlettenButikk",
    "summen": 169.0,
    "UkeNr": 45,
    "timestamp": "Timestamp(seconds=1542227316, nanoseconds=481000000)",
    "documentID": "-LRIuJeQBoaoOvhcmnJr"
  },
  {
    "dato": "2018-11-10",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7311041013557",
        "totalPris": 21.9,
        "navn": "Fiskepinner-FirstPrice",
        "pris": 21.9
      },
      {
        "mengde": 7,
        "produktID": "7311041019757",
        "totalPris": 93.8,
        "navn": "Formaggio",
        "pris": 13.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 115.7,
    "UkeNr": 45,
    "timestamp": "Timestamp(seconds=1542227270, nanoseconds=454000000)",
    "documentID": "-LRIu8LggRET82jafY2_"
  },
  {
    "dato": "2018-11-10",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 89,
        "navn": "Snus G4",
        "pris": 89
      },
      {
        "mengde": 1,
        "produktID": "87UsRoroXvkfLQhionEg",
        "totalPris": 50,
        "navn": "KjøptForAndre",
        "pris": 50
      }
    ],
    "butikk": "Kiwi",
    "summen": 139,
    "UkeNr": 45,
    "timestamp": "Timestamp(seconds=1542227166, nanoseconds=841000000)",
    "documentID": "-LRItkADQ6oCd9th-Bpe"
  },
  {
    "dato": "2018-11-09",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7046110009239",
        "totalPris": 44.9,
        "navn": "Jif-Kjøkken-Oven",
        "pris": 44.9
      },
      {
        "mengde": 1,
        "produktID": "VGkn3RmCHcllcFn0iOqe",
        "totalPris": 39.9,
        "navn": "PoseLukker",
        "pris": 39.9
      },
      {
        "mengde": 1,
        "produktID": "6414300084983",
        "totalPris": 26.4,
        "navn": "Tørkepapir Serla",
        "pris": 26.4
      }
    ],
    "butikk": "CoopExtra",
    "summen": 111.2,
    "UkeNr": 45,
    "timestamp": "Timestamp(seconds=1542227119, nanoseconds=189000000)",
    "documentID": "-LRItZQ1iIsluw3YzRPm"
  },
  {
    "dato": "2018-11-08",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7038010045080",
        "totalPris": 29.9,
        "navn": "Yoghurt-0,85K-vanilje",
        "pris": 29.9
      },
      {
        "mengde": 1,
        "produktID": "7020655860043",
        "totalPris": 20,
        "navn": "Brød-SPLEISE",
        "pris": 20
      },
      {
        "mengde": 1,
        "produktID": "ErL7PujeMYUwt6xvepLO",
        "totalPris": 11.9,
        "navn": "Bakeark",
        "pris": 11.9
      },
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "mengde": 1,
        "produktID": "87UsRoroXvkfLQhionEg",
        "totalPris": 90.9,
        "navn": "KjøptForAndre",
        "pris": 90.9
      }
    ],
    "butikk": "Rema",
    "summen": 170.6,
    "UkeNr": 45,
    "timestamp": "Timestamp(seconds=1542226696, nanoseconds=972000000)",
    "documentID": "-LRIrxI2KqSZUpXjZDgn"
  },
  {
    "dato": "2018-11-06",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7032069715253",
        "totalPris": 17.9,
        "navn": "MusliCrunchy-Rema1000",
        "pris": 17.9
      },
      {
        "mengde": 1,
        "produktID": "7020655860043",
        "totalPris": 20.0,
        "navn": "Brød-SPLEISE",
        "pris": 20.0
      },
      {
        "mengde": 1,
        "produktID": "7038010000911",
        "totalPris": 26.4,
        "navn": "Melk-stor-0,5-Tine",
        "pris": 26.4
      },
      {
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 19.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 19.9
      },
      {
        "mengde": 1,
        "produktID": "7038010014604",
        "totalPris": 64.03,
        "navn": "Norvegia-0,5K",
        "pris": 64.03
      },
      {
        "mengde": 1,
        "produktID": "7038010028441",
        "totalPris": 84.9,
        "navn": "Brunost-Original-1kg",
        "pris": 84.9
      }
    ],
    "butikk": "Rema",
    "summen": 233.13,
    "UkeNr": 45,
    "timestamp": "Timestamp(seconds=1542223080, nanoseconds=986000000)",
    "documentID": "-LRIe9UfyuCvzpkIphDh"
  },
  {
    "dato": "2018-11-05",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7311041029299",
        "totalPris": 11.5,
        "navn": "Pesto grønn- Eldorado",
        "pris": 11.5
      },
      {
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 90.4,
        "navn": "Snus G4",
        "pris": 90.4
      },
      {
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 109.5,
        "navn": "Snus General",
        "pris": 109.5
      }
    ],
    "butikk": "Rema",
    "summen": 211.4,
    "UkeNr": 45,
    "timestamp": "Timestamp(seconds=1542222936, nanoseconds=559000000)",
    "documentID": "-LRIdbEo6ELj1UIDnLra"
  },
  {
    "dato": "2018-11-04",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7029161117139",
        "totalPris": 29.0,
        "navn": "Brød- GRØVT&GODT",
        "pris": 29.0
      }
    ],
    "butikk": "Rema",
    "summen": 29.0,
    "UkeNr": 44,
    "timestamp": "Timestamp(seconds=1542222715, nanoseconds=895000000)",
    "documentID": "-LRIclP8sVu-agpbMmWH"
  },
  {
    "dato": "2018-10-31",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7020650444606",
        "totalPris": 25.0,
        "navn": "Brød-Møllerens",
        "pris": 25.0
      },
      {
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 19.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 19.9
      },
      {
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 109.5,
        "navn": "Snus General",
        "pris": 109.5
      }
    ],
    "butikk": "Rema",
    "summen": 154.4,
    "UkeNr": 44,
    "timestamp": "Timestamp(seconds=1542222510, nanoseconds=624000000)",
    "documentID": "-LRIbzIOTQ4Y_bhDiUhu"
  },
  {
    "dato": "2018-10-29",
    "varer": [
      {
        "mengde": 7,
        "produktID": "7311041019757",
        "totalPris": 93.8,
        "navn": "Formaggio",
        "pris": 13.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 93.8,
    "UkeNr": 44,
    "timestamp": "Timestamp(seconds=1542222414, nanoseconds=215000000)",
    "documentID": "-LRIbbkYAiSp5HTsqX1H"
  },
  {
    "dato": "2018-10-29",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7020655860043",
        "totalPris": 23.5,
        "navn": "Brød-SPLEISE",
        "pris": 23.5
      },
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 18.4,
        "navn": "KulturMelk",
        "pris": 18.4
      },
      {
        "mengde": 1,
        "produktID": "7032069715253",
        "totalPris": 17.9,
        "navn": "MusliCrunchy-Rema1000",
        "pris": 17.9
      },
      {
        "mengde": 1,
        "produktID": "7038010005459",
        "totalPris": 14.9,
        "navn": "Rømme-lett0,18",
        "pris": 14.9
      },
      {
        "mengde": 1,
        "produktID": "7020650711005",
        "totalPris": 15.7,
        "navn": "Mjøl-Bygg",
        "pris": 15.7
      },
      {
        "mengde": 1,
        "produktID": "7032069722152",
        "totalPris": 5.0,
        "navn": "Sjampinjong-prima",
        "pris": 5.0
      },
      {
        "mengde": 1,
        "produktID": "7035620004346",
        "totalPris": 12.5,
        "navn": "Pesto rød- Eldorado",
        "pris": 12.5
      },
      {
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 24.9,
        "navn": "Melk-stor-0,5-Q",
        "pris": 24.9
      },
      {
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 19.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 19.9
      }
    ],
    "butikk": "Rema",
    "summen": 152.7,
    "UkeNr": 44,
    "timestamp": "Timestamp(seconds=1542222340, nanoseconds=49000000)",
    "documentID": "-LRIbKXOZVYP0rLvvTKY"
  },
  {
    "dato": "2018-10-28",
    "varer": [
      {
        "mengde": 1,
        "produktID": "5710557161110",
        "totalPris": 163.0,
        "navn": "Kjøtt-MB",
        "pris": 163.0
      }
    ],
    "butikk": "SlettenButikk",
    "summen": 163.0,
    "UkeNr": 43,
    "timestamp": "Timestamp(seconds=1542216458, nanoseconds=929000000)",
    "documentID": "-LRIFtmon9SrEHw_ziFa"
  },
  {
    "dato": "2018-10-25T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "87UsRoroXvkfLQhionEg",
        "totalPris": 21.5,
        "navn": "KjøptForAndre",
        "pris": 21.5
      }
    ],
    "butikk": "Bunnpris",
    "summen": 21.5,
    "UkeNr": 43,
    "timestamp": "80",
    "documentID": "f2r4IcAWtQkHbwHIhCdj"
  },
  {
    "dato": "2018-10-25T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7039610000172",
        "totalPris": 29.9,
        "navn": "Egg-12",
        "pris": 29.9
      },
      {
        "mengde": 2,
        "produktID": "7314571151003",
        "totalPris": 47.2,
        "navn": "Shampoo-Sport",
        "pris": 23.6
      },
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 35.8,
        "navn": "KulturMelk",
        "pris": 35.8
      },
      {
        "mengde": 1,
        "produktID": "7041614000867",
        "totalPris": 19.9,
        "navn": "Brød-HVERDAGSGROVT",
        "pris": 19.9
      },
      {
        "mengde": 1,
        "produktID": "J8K1OhNZSQppLWzGI9oP",
        "totalPris": 25.5,
        "navn": "Såpe-Håndsåpe",
        "pris": 25.5
      },
      {
        "mengde": 1,
        "produktID": "7038010055652",
        "totalPris": 13.2,
        "navn": "Yoghurt-0,5K-naturell",
        "pris": 13.2
      },
      {
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 20.2,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 20.2
      }
    ],
    "butikk": "CoopObs",
    "summen": 191.69999999999996,
    "UkeNr": 43,
    "timestamp": "79",
    "documentID": "vc2qt9f1p5DKdRVRcKRH"
  },
  {
    "dato": "2018-10-25T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 115,
        "navn": "Snus General",
        "pris": 115
      }
    ],
    "butikk": "Shell",
    "summen": 115,
    "UkeNr": 43,
    "timestamp": "78",
    "documentID": "3gBDtKwjv0DO4AIJRioM"
  },
  {
    "dato": "2018-10-23T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 21.2,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 21.2
      },
      {
        "mengde": 1,
        "produktID": "7041611018124",
        "totalPris": 15,
        "navn": "Brød-NORSK FJELLBRØD",
        "pris": 15
      },
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 19.9,
        "navn": "KulturMelk",
        "pris": 19.9
      },
      {
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 91,
        "navn": "Snus General",
        "pris": 91
      }
    ],
    "butikk": "Bunnpris",
    "summen": 147.1,
    "UkeNr": 43,
    "timestamp": "77",
    "documentID": "tgQNNBTVI9p40fpxxdjj"
  },
  {
    "dato": "2018-10-22T00:00:00",
    "varer": [
      {
        "mengde": 7,
        "produktID": "7311041019757",
        "totalPris": 93.8,
        "navn": "Formaggio",
        "pris": 13.4
      },
      {
        "mengde": 1,
        "produktID": "7311041029299",
        "totalPris": 10.9,
        "navn": "Pesto grønn- Eldorado",
        "pris": 10.9
      },
      {
        "mengde": 1,
        "produktID": "alzmU8vv3SbAsDiaMlmr",
        "totalPris": 1.6,
        "navn": "Pose",
        "pris": 1.6
      }
    ],
    "butikk": "Kiwi",
    "summen": 106.3,
    "UkeNr": 43,
    "timestamp": "76",
    "documentID": "G5FCYGiMFDnaOuX0UKE5"
  },
  {
    "dato": "2018-10-20T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7032069715253",
        "totalPris": 17.9,
        "navn": "MusliCrunchy-Rema1000",
        "pris": 17.9
      },
      {
        "mengde": 1,
        "produktID": "7020655860043",
        "totalPris": 23.5,
        "navn": "Brød-SPLEISE",
        "pris": 23.5
      },
      {
        "mengde": 1,
        "produktID": "7021010001057",
        "totalPris": 24.9,
        "navn": "Sjokoladepålegg-Nugatti",
        "pris": 24.9
      }
    ],
    "butikk": "Rema",
    "summen": 66.3,
    "UkeNr": 42,
    "timestamp": "75",
    "documentID": "1HFOGPP6luZ35faZkltO"
  },
  {
    "dato": "2018-10-19T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "3086121601019",
        "totalPris": 154,
        "navn": "brev-sporring",
        "pris": 154
      }
    ],
    "butikk": "Posten",
    "summen": 154,
    "UkeNr": 42,
    "timestamp": "74",
    "documentID": "A9eDLTAm3F6RX4weq2aA"
  },
  {
    "dato": "2018-10-19T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 109.5,
        "navn": "Snus General",
        "pris": 109.5
      },
      {
        "mengde": 1,
        "produktID": "ZctxD3sCjSnOtRvrRWtC",
        "totalPris": 39.9,
        "navn": "Penn",
        "pris": 39.9
      }
    ],
    "butikk": "CoopExtra",
    "summen": 149.4,
    "UkeNr": 42,
    "timestamp": "73",
    "documentID": "BEmZzxFy2GUckmUlMKTW"
  },
  {
    "dato": "2018-10-19T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 18.4,
        "navn": "KulturMelk",
        "pris": 18.4
      },
      {
        "mengde": 1,
        "produktID": "2302148200006",
        "totalPris": 109.9,
        "navn": "Norvegia-1K",
        "pris": 109.9
      },
      {
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 24.9,
        "navn": "Melk-stor-0,5-Q",
        "pris": 24.9
      },
      {
        "mengde": 1,
        "produktID": "7039610005849",
        "totalPris": 49.6,
        "navn": "Egg-18",
        "pris": 49.6
      },
      {
        "mengde": 1,
        "produktID": "7311041013557",
        "totalPris": 25.9,
        "navn": "Fiskepinner-FirstPrice",
        "pris": 25.9
      },
      {
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 12,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 12
      }
    ],
    "butikk": "CoopExtra",
    "summen": 240.70000000000002,
    "UkeNr": 42,
    "timestamp": "72",
    "documentID": "nx0VxwS38WF1cgunywQD"
  },
  {
    "dato": "2018-10-18T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7038010005459",
        "totalPris": 14.9,
        "navn": "Rømme-lett0,18",
        "pris": 14.9
      },
      {
        "mengde": 1,
        "produktID": "7029161124687",
        "totalPris": 17.5,
        "navn": "Brød-KNEIPP-PRIMA",
        "pris": 17.5
      }
    ],
    "butikk": "Rema",
    "summen": 32.4,
    "UkeNr": 42,
    "timestamp": "71",
    "documentID": "MOe7d9A5tqG9XWMClYUv"
  },
  {
    "dato": "2018-10-15T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7038010055676",
        "totalPris": 26.9,
        "navn": "Yoghurt-0,5K-vanilje",
        "pris": 26.9
      },
      {
        "mengde": 1,
        "produktID": "7020655860043",
        "totalPris": 33.5,
        "navn": "Brød-SPLEISE",
        "pris": 33.5
      },
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 18.4,
        "navn": "KulturMelk",
        "pris": 18.4
      },
      {
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 24.9,
        "navn": "Melk-stor-0,5-Q",
        "pris": 24.9
      },
      {
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 90.4,
        "navn": "Snus G4",
        "pris": 90.4
      }
    ],
    "butikk": "Rema",
    "summen": 194.1,
    "UkeNr": 42,
    "timestamp": "70",
    "documentID": "0iATpPXCQzAcHjcOI5RC"
  },
  {
    "dato": "2018-10-15T00:00:00",
    "varer": [
      {
        "mengde": 3,
        "produktID": "7311041019757",
        "totalPris": 40.2,
        "navn": "Formaggio",
        "pris": 13.4
      },
      {
        "mengde": 1,
        "produktID": "7311041013557",
        "totalPris": 20.7,
        "navn": "Fiskepinner-FirstPrice",
        "pris": 20.7
      }
    ],
    "butikk": "Bunnpris",
    "summen": 60.900000000000006,
    "UkeNr": 42,
    "timestamp": "69",
    "documentID": "cZbk5l8c4mw6G7E7zVAx"
  },
  {
    "dato": "2018-10-13T00:00:00",
    "varer": [
      {
        "mengde": 0.342,
        "produktID": "X0CWKFVB2YvVGWxTIvAL",
        "totalPris": 15.36,
        "navn": "Tomater-løsvekt",
        "pris": 44.91228070175438
      }
    ],
    "butikk": "Rema",
    "summen": 15.36,
    "UkeNr": 41,
    "timestamp": "68",
    "documentID": "FPBjuvkra1PnCGFb82YK"
  },
  {
    "dato": "2018-10-12T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "42eQ7LRuiS2M4qiPNyYt",
        "totalPris": 39.9,
        "navn": "Tørkeruller",
        "pris": 39.9
      },
      {
        "mengde": 1,
        "produktID": "7020655860043",
        "totalPris": 23.9,
        "navn": "Brød-SPLEISE",
        "pris": 23.9
      }
    ],
    "butikk": "CoopExtra",
    "summen": 63.8,
    "UkeNr": 41,
    "timestamp": "67",
    "documentID": "sEwftgCbCiKAQeE5HozJ"
  },
  {
    "dato": "2018-10-11T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7032069722152",
        "totalPris": 5,
        "navn": "Sjampinjong-prima",
        "pris": 5
      },
      {
        "mengde": 1,
        "produktID": "48327203421",
        "totalPris": 76.9,
        "navn": "Olje-Oliven-Ybarra",
        "pris": 76.9
      },
      {
        "mengde": 1,
        "produktID": "7311041013519",
        "totalPris": 10.9,
        "navn": "Spaghetti",
        "pris": 10.9
      }
    ],
    "butikk": "Rema",
    "summen": 92.80000000000001,
    "UkeNr": 41,
    "timestamp": "66",
    "documentID": "Ggpyb1TXUWimbHnX1dof"
  },
  {
    "dato": "2018-10-10T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7032069715253",
        "totalPris": 17.9,
        "navn": "MusliCrunchy-Rema1000",
        "pris": 17.9
      },
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "mengde": 1,
        "produktID": "7038010055676",
        "totalPris": 26.9,
        "navn": "Yoghurt-0,5K-vanilje",
        "pris": 26.9
      },
      {
        "mengde": 1,
        "produktID": "7038010005459",
        "totalPris": 14.9,
        "navn": "Rømme-lett0,18",
        "pris": 14.9
      },
      {
        "mengde": 1,
        "produktID": "7029161124687",
        "totalPris": 6.9,
        "navn": "Brød-KNEIPP-PRIMA",
        "pris": 6.9
      },
      {
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 90.4,
        "navn": "Snus G4",
        "pris": 90.4
      }
    ],
    "butikk": "Rema",
    "summen": 174.9,
    "UkeNr": 41,
    "timestamp": "65",
    "documentID": "g0SI2stzEAdg3QHnTj0e"
  },
  {
    "dato": "2018-10-10T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 113.8,
        "navn": "Snus General",
        "pris": 113.8
      }
    ],
    "butikk": "Bunnpris",
    "summen": 113.8,
    "UkeNr": 41,
    "timestamp": "64",
    "documentID": "TTItw6RRf5ZmTXwJ51pG"
  },
  {
    "dato": "2018-10-08T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7090026220592",
        "totalPris": 59.9,
        "navn": "Egg-24",
        "pris": 59.9
      },
      {
        "mengde": 1,
        "produktID": "7613035962965",
        "totalPris": 27.9,
        "navn": "Nescafe-Gull",
        "pris": 27.9
      },
      {
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 24.9,
        "navn": "Melk-stor-0,5-Q",
        "pris": 24.9
      }
    ],
    "butikk": "Rema",
    "summen": 112.69999999999999,
    "UkeNr": 41,
    "timestamp": "63",
    "documentID": "0iHZDLNl5DNIZWDuBCV0"
  },
  {
    "dato": "2018-10-08T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "h7mi21cM59LmbSoppzZw",
        "totalPris": 99,
        "navn": "Toalettpapir",
        "pris": 99
      }
    ],
    "butikk": "Rema",
    "summen": 99,
    "UkeNr": 41,
    "timestamp": "62",
    "documentID": "UOCEB4QuXafSmePiGcbf"
  },
  {
    "dato": "2018-10-07T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7041611018124",
        "totalPris": 29,
        "navn": "Brød-NORSK FJELLBRØD",
        "pris": 29
      },
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 18.4,
        "navn": "KulturMelk",
        "pris": 18.4
      },
      {
        "mengde": 1,
        "produktID": "7048840000500",
        "totalPris": 15.9,
        "navn": "Melk-1L-0,5-Q",
        "pris": 15.9
      }
    ],
    "butikk": "Rema",
    "summen": 63.3,
    "UkeNr": 40,
    "timestamp": "61",
    "documentID": "zHQMmTaIDVFOcWHlaL3Z"
  },
  {
    "dato": "2018-10-07T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "5319991692329",
        "totalPris": 19,
        "navn": "Sterk saus",
        "pris": 19
      }
    ],
    "butikk": "SlettenButikk",
    "summen": 19,
    "UkeNr": 40,
    "timestamp": "60",
    "documentID": "07GPaYcFrbVXkzh19hEE"
  },
  {
    "dato": "2018-10-05T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "JZ3bpZyqvDpG02nAxSCj",
        "totalPris": 70.4,
        "navn": "Barberblader",
        "pris": 70.4
      }
    ],
    "butikk": "Kiwi",
    "summen": 70.4,
    "UkeNr": 40,
    "timestamp": "59",
    "documentID": "6XMdmoSSYBc1xB5n5Ohn"
  },
  {
    "dato": "2018-10-04T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7311041013557",
        "totalPris": 20.7,
        "navn": "Fiskepinner-FirstPrice",
        "pris": 20.7
      },
      {
        "mengde": 1,
        "produktID": "7311041019757",
        "totalPris": 40.2,
        "navn": "Formaggio",
        "pris": 40.2
      }
    ],
    "butikk": "Bunnpris",
    "summen": 60.900000000000006,
    "UkeNr": 40,
    "timestamp": "58",
    "documentID": "qz4PRGUTSwbbDD56MKUl"
  },
  {
    "dato": "2018-10-04T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 18.4,
        "navn": "KulturMelk",
        "pris": 18.4
      },
      {
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 19.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 19.9
      },
      {
        "mengde": 1,
        "produktID": "7029161124687",
        "totalPris": 17.5,
        "navn": "Brød-KNEIPP-PRIMA",
        "pris": 17.5
      },
      {
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 89.9,
        "navn": "Snus G4",
        "pris": 89.9
      },
      {
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 109.5,
        "navn": "Snus General",
        "pris": 109.5
      }
    ],
    "butikk": "Rema",
    "summen": 255.2,
    "UkeNr": 40,
    "timestamp": "57",
    "documentID": "8Y454uPdfAaGk7xEhm9z"
  },
  {
    "dato": "2018-10-02T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "438tIJyY0SrNuAF845j4",
        "totalPris": 499,
        "navn": "Whey Protein-3K-Tri-Whey",
        "pris": 499
      }
    ],
    "butikk": "XXL",
    "summen": 499,
    "UkeNr": 40,
    "timestamp": "56",
    "documentID": "1ZK6SgEKFb2SKTBTR3iA"
  },
  {
    "dato": "2018-10-02T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "42eQ7LRuiS2M4qiPNyYt",
        "totalPris": 40.6,
        "navn": "Tørkeruller",
        "pris": 40.6
      },
      {
        "mengde": 1,
        "produktID": "7038010005459",
        "totalPris": 16.3,
        "navn": "Rømme-lett0,18",
        "pris": 16.3
      },
      {
        "mengde": 1,
        "produktID": "5701390430488",
        "totalPris": 58,
        "navn": "Skål-små",
        "pris": 58
      },
      {
        "mengde": 1,
        "produktID": "5701390066731",
        "totalPris": 98,
        "navn": "Skål-store",
        "pris": 98
      }
    ],
    "butikk": "CoopObs",
    "summen": 212.9,
    "UkeNr": 40,
    "timestamp": "55",
    "documentID": "mBB0UOJIVOG82Ywgnp5H"
  },
  {
    "dato": "2018-10-02T00:00:00",
    "varer": [
      {
        "mengde": 2,
        "produktID": "4008321202710",
        "totalPris": 100,
        "navn": "Lyspære",
        "pris": 50
      }
    ],
    "butikk": "Clas Ohlson",
    "summen": 100,
    "UkeNr": 40,
    "timestamp": "54",
    "documentID": "tYfvtZUr93pSIjYdnRQ5"
  },
  {
    "dato": "2018-10-01T00:00:00",
    "varer": [
      {
        "mengde": 5,
        "produktID": "7311041019757",
        "totalPris": 67,
        "navn": "Formaggio",
        "pris": 13.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 67,
    "UkeNr": 40,
    "timestamp": "53",
    "documentID": "0xubVrLiWyEzZN0w7iQ9"
  },
  {
    "dato": "2018-10-01T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7020655860043",
        "totalPris": 20,
        "navn": "Brød-SPLEISE",
        "pris": 20
      },
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 18.4,
        "navn": "KulturMelk",
        "pris": 18.4
      },
      {
        "mengde": 1,
        "produktID": "7038010055676",
        "totalPris": 26.9,
        "navn": "Yoghurt-0,5K-vanilje",
        "pris": 26.9
      },
      {
        "mengde": 1,
        "produktID": "7035620004346",
        "totalPris": 12.2,
        "navn": "Pesto rød- Eldorado",
        "pris": 12.2
      }
    ],
    "butikk": "Rema",
    "summen": 77.5,
    "UkeNr": 40,
    "timestamp": "52",
    "documentID": "eMj0354vP49gsKabAPxk"
  },
  {
    "dato": "2018-09-29T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 18.4,
        "navn": "KulturMelk",
        "pris": 18.4
      },
      {
        "mengde": 1,
        "produktID": "87UsRoroXvkfLQhionEg",
        "totalPris": 16.9,
        "navn": "KjøptForAndre",
        "pris": 16.9
      },
      {
        "mengde": 1,
        "produktID": "7041611018124",
        "totalPris": 31.2,
        "navn": "Brød-NORSK FJELLBRØD",
        "pris": 31.2
      }
    ],
    "butikk": "Rema",
    "summen": 66.5,
    "UkeNr": 39,
    "timestamp": "51",
    "documentID": "h4bKgDdOGWgCr3o2y2V4"
  },
  {
    "dato": "2018-09-28T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7032069715253",
        "totalPris": 17.9,
        "navn": "MusliCrunchy-Rema1000",
        "pris": 17.9
      },
      {
        "mengde": 1,
        "produktID": "7311041013557",
        "totalPris": 20.6,
        "navn": "Fiskepinner-FirstPrice",
        "pris": 20.6
      },
      {
        "mengde": 1,
        "produktID": "7040514501474",
        "totalPris": 19.9,
        "navn": "Løk-FirstPrice",
        "pris": 19.9
      },
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "mengde": 1,
        "produktID": "7034281131002",
        "totalPris": 84.4,
        "navn": "Ost synnøve-1K",
        "pris": 84.4
      },
      {
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 89,
        "navn": "Snus G4",
        "pris": 89
      }
    ],
    "butikk": "Bunnpris",
    "summen": 249.7,
    "UkeNr": 39,
    "timestamp": "50",
    "documentID": "Ee3eO69QEmssK3v4uyoj"
  },
  {
    "dato": "2018-09-27T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "fBwxKR44XmJNvs2h91IL",
        "totalPris": 29.9,
        "navn": "Batteri-Klokke",
        "pris": 29.9
      }
    ],
    "butikk": "Kjell&Company",
    "summen": 29.9,
    "UkeNr": 39,
    "timestamp": "49",
    "documentID": "2ZQCxpBpJuWht2jLTKPj"
  },
  {
    "dato": "2018-09-25T00:00:00",
    "varer": [
      {
        "mengde": 4,
        "produktID": "7050122131611",
        "totalPris": 55.6,
        "navn": "Dipmix",
        "pris": 13.9
      },
      {
        "mengde": 2,
        "produktID": "7311041019757",
        "totalPris": 26.8,
        "navn": "Formaggio",
        "pris": 13.4
      },
      {
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 97,
        "navn": "Snus General",
        "pris": 97
      }
    ],
    "butikk": "Bunnpris",
    "summen": 179.4,
    "UkeNr": 39,
    "timestamp": "48",
    "documentID": "5LlcqEfdEWbJ8RfYUz26"
  },
  {
    "dato": "2018-09-22T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 89.9,
        "navn": "Snus G4",
        "pris": 89.9
      }
    ],
    "butikk": "Rema",
    "summen": 89.9,
    "UkeNr": 38,
    "timestamp": "46",
    "documentID": "9KHfp43pDS9OJ9WUmnOJ"
  },
  {
    "dato": "2018-09-21T00:00:00",
    "varer": [
      {
        "mengde": 3,
        "produktID": "7035620011146",
        "totalPris": 26.7,
        "navn": "Pizzasaus-Eldorado",
        "pris": 8.9
      },
      {
        "mengde": 1,
        "produktID": "7039610000172",
        "totalPris": 26.9,
        "navn": "Egg-12",
        "pris": 26.9
      },
      {
        "mengde": 1,
        "produktID": "7041614000867",
        "totalPris": 16.8,
        "navn": "Brød-HVERDAGSGROVT",
        "pris": 16.8
      },
      {
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 23.4,
        "navn": "Melk-stor-0,5-Q",
        "pris": 23.4
      },
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "mengde": 0.43,
        "produktID": "X0CWKFVB2YvVGWxTIvAL",
        "totalPris": 8.64,
        "navn": "Tomater-løsvekt",
        "pris": 20.093023255813954
      }
    ],
    "butikk": "Bunnpris",
    "summen": 120.33999999999999,
    "UkeNr": 38,
    "timestamp": "45",
    "documentID": "3hbuB91ZNgymJV5TsXTg"
  },
  {
    "dato": "2018-09-18T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7034281134003",
        "totalPris": 29.9,
        "navn": "Ost synnøve-0,48K",
        "pris": 29.9
      },
      {
        "mengde": 1,
        "produktID": "7311041013557",
        "totalPris": 22.5,
        "navn": "Fiskepinner-FirstPrice",
        "pris": 22.5
      }
    ],
    "butikk": "Spar",
    "summen": 52.4,
    "UkeNr": 38,
    "timestamp": "44",
    "documentID": "KMblcQXiulpZW7yugVTc"
  },
  {
    "dato": "2018-09-17T00:00:00",
    "varer": [
      {
        "mengde": 2,
        "produktID": "7038010000737",
        "totalPris": 36.8,
        "navn": "KulturMelk",
        "pris": 18.4
      },
      {
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 24.9,
        "navn": "Melk-stor-0,5-Q",
        "pris": 24.9
      },
      {
        "mengde": 1,
        "produktID": "7038010005459",
        "totalPris": 16.3,
        "navn": "Rømme-lett0,18",
        "pris": 16.3
      },
      {
        "mengde": 1,
        "produktID": "7038010055676",
        "totalPris": 26.9,
        "navn": "Yoghurt-0,5K-vanilje",
        "pris": 26.9
      },
      {
        "mengde": 1,
        "produktID": "7032069715253",
        "totalPris": 17.9,
        "navn": "MusliCrunchy-Rema1000",
        "pris": 17.9
      },
      {
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 109.5,
        "navn": "Snus General",
        "pris": 109.5
      }
    ],
    "butikk": "Rema",
    "summen": 232.3,
    "UkeNr": 38,
    "timestamp": "43",
    "documentID": "EVqSUCi8jGdwIcKviAoE"
  },
  {
    "dato": "2018-09-16T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7311041048931",
        "totalPris": 31.9,
        "navn": "NøtterMix",
        "pris": 31.9
      },
      {
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 19.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 19.9
      },
      {
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 89.9,
        "navn": "Snus G4",
        "pris": 89.9
      }
    ],
    "butikk": "Rema",
    "summen": 141.7,
    "UkeNr": 37,
    "timestamp": "42",
    "documentID": "sK0JdobSkQ8UQFaKSTiy"
  },
  {
    "dato": "2018-09-14T00:00:00",
    "varer": [
      {
        "mengde": 2,
        "produktID": "7038010000737",
        "totalPris": 36.8,
        "navn": "KulturMelk",
        "pris": 18.4
      },
      {
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 24.9,
        "navn": "Melk-stor-0,5-Q",
        "pris": 24.9
      },
      {
        "mengde": 1,
        "produktID": "7038010005459",
        "totalPris": 16.3,
        "navn": "Rømme-lett0,18",
        "pris": 16.3
      },
      {
        "mengde": 1,
        "produktID": "7038010045080",
        "totalPris": 26.9,
        "navn": "Yoghurt-0,85K-vanilje",
        "pris": 26.9
      },
      {
        "mengde": 1,
        "produktID": "7032069715253",
        "totalPris": 17.9,
        "navn": "MusliCrunchy-Rema1000",
        "pris": 17.9
      },
      {
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 109.5,
        "navn": "Snus General",
        "pris": 109.5
      }
    ],
    "butikk": "Rema",
    "summen": 232.3,
    "UkeNr": 37,
    "timestamp": "41",
    "documentID": "YhbM5qFg7KkyXy1ZB66m"
  },
  {
    "dato": "2018-09-14T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7340011364306",
        "totalPris": 11.2,
        "navn": "Pesto grønn-coop",
        "pris": 11.2
      },
      {
        "mengde": 1,
        "produktID": "7613035962965",
        "totalPris": 27.9,
        "navn": "Nescafe-Gull",
        "pris": 27.9
      },
      {
        "mengde": 1,
        "produktID": "7041611018124",
        "totalPris": 23.9,
        "navn": "Brød-NORSK FJELLBRØD",
        "pris": 23.9
      },
      {
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 19.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 19.9
      }
    ],
    "butikk": "CoopExtra",
    "summen": 82.89999999999999,
    "UkeNr": 37,
    "timestamp": "40",
    "documentID": "W6Mj8fWvB9h33H1vzf86"
  },
  {
    "dato": "2018-09-14T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7020650113205",
        "totalPris": 11.4,
        "navn": "Mjøl-Hvete",
        "pris": 11.4
      },
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 19.9,
        "navn": "KulturMelk",
        "pris": 19.9
      },
      {
        "mengde": 1,
        "produktID": "7311040640228",
        "totalPris": 14.4,
        "navn": "Oliven-0,34K-sorte",
        "pris": 14.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 45.699999999999996,
    "UkeNr": 37,
    "timestamp": "39",
    "documentID": "G0hXSGZavvFEWkcBCTTg"
  },
  {
    "dato": "2018-09-14T00:00:00",
    "varer": [
      {
        "mengde": 7,
        "produktID": "7311041019757",
        "totalPris": 93.8,
        "navn": "Formaggio",
        "pris": 13.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 93.8,
    "UkeNr": 37,
    "timestamp": "38",
    "documentID": "jz3auxIWX8NVO8ZtDrNW"
  },
  {
    "dato": "2018-09-11T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "hN8QtY5RT1mrtajUCJXW",
        "totalPris": 299,
        "navn": "Futballbukse",
        "pris": 299
      }
    ],
    "butikk": "Obs",
    "summen": 299,
    "UkeNr": 37,
    "timestamp": "37",
    "documentID": "Vqx8KhA2tnhfArFOaxmg"
  },
  {
    "dato": "2018-09-11T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 24.9,
        "navn": "Melk-stor-0,5-Q",
        "pris": 24.9
      },
      {
        "mengde": 1,
        "produktID": "HLyoK7UBaa8aylJUn05N",
        "totalPris": 34.9,
        "navn": "Lynlim ",
        "pris": 34.9
      },
      {
        "mengde": 1,
        "produktID": "7090026220592",
        "totalPris": 59.9,
        "navn": "Egg-24",
        "pris": 59.9
      },
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 18.4,
        "navn": "KulturMelk",
        "pris": 18.4
      },
      {
        "mengde": 1,
        "produktID": "7041614000867",
        "totalPris": 17.5,
        "navn": "Brød-HVERDAGSGROVT",
        "pris": 17.5
      },
      {
        "mengde": 0.3,
        "produktID": "SJeGJDQlCAX7XmUe4q1M",
        "totalPris": 7.84,
        "navn": "Løk-løsvekt",
        "pris": 26.133333333333333
      },
      {
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 19.9,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 19.9
      },
      {
        "mengde": 1,
        "produktID": "7038010005459",
        "totalPris": 16.3,
        "navn": "Rømme-lett0,18",
        "pris": 16.3
      },
      {
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 89.9,
        "navn": "Snus G4",
        "pris": 89.9
      }
    ],
    "butikk": "Rema",
    "summen": 289.54,
    "UkeNr": 37,
    "timestamp": "36",
    "documentID": "njQfKJC5rsTIZsCinese"
  },
  {
    "dato": "2018-09-08T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 109.5,
        "navn": "Snus General",
        "pris": 109.5
      },
      {
        "mengde": 1,
        "produktID": "7310500173467",
        "totalPris": 52.2,
        "navn": "Fiskepinner-Findus-30",
        "pris": 52.2
      },
      {
        "mengde": 1,
        "produktID": "7038010055676",
        "totalPris": 19.9,
        "navn": "Yoghurt-0,5K-vanilje",
        "pris": 19.9
      },
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 18.4,
        "navn": "KulturMelk",
        "pris": 18.4
      },
      {
        "mengde": 1,
        "produktID": "7021010001057",
        "totalPris": 21.9,
        "navn": "Sjokoladepålegg-Nugatti",
        "pris": 21.9
      },
      {
        "mengde": 1,
        "produktID": "7032069715253",
        "totalPris": 17.9,
        "navn": "MusliCrunchy-Rema1000",
        "pris": 17.9
      },
      {
        "mengde": 1,
        "produktID": "7040514507650",
        "totalPris": 29.9,
        "navn": "Hvitløk-utenFedd",
        "pris": 29.9
      }
    ],
    "butikk": "Rema",
    "summen": 269.7,
    "UkeNr": 36,
    "timestamp": "35",
    "documentID": "eeln82RtHeu2AKuZQYlK"
  },
  {
    "dato": "2018-09-07T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "Wnp1wDnep9gt5yaPWnbw",
        "totalPris": 299,
        "navn": "Jakke med hette",
        "pris": 299
      },
      {
        "mengde": 1,
        "produktID": "hcYO0QLwfYiUrrXE4lnk",
        "totalPris": 699,
        "navn": "Sko M/77 ",
        "pris": 699
      },
      {
        "mengde": 1,
        "produktID": "i7Z2fywdOpjel4HEix7e",
        "totalPris": 25,
        "navn": "Tannkrem",
        "pris": 25
      },
      {
        "mengde": 1,
        "produktID": "alzmU8vv3SbAsDiaMlmr",
        "totalPris": 1,
        "navn": "Pose",
        "pris": 1
      }
    ],
    "butikk": "Spare Kjøp",
    "summen": 1024,
    "UkeNr": 36,
    "timestamp": "34",
    "documentID": "5b0pCvfkFXS9r9A73ThV"
  },
  {
    "dato": "2018-09-07T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7041611018124",
        "totalPris": 27.9,
        "navn": "Brød-NORSK FJELLBRØD",
        "pris": 27.9
      },
      {
        "mengde": 1,
        "produktID": "7038010055676",
        "totalPris": 19.9,
        "navn": "Yoghurt-0,5K-vanilje",
        "pris": 19.9
      },
      {
        "mengde": 1,
        "produktID": "SwtPUMzLpFRreYnRJsio",
        "totalPris": 12.4,
        "navn": "UniversalKult",
        "pris": 12.4
      },
      {
        "mengde": 1,
        "produktID": "7VymTjOM04R4cssCnX2J",
        "totalPris": 28.2,
        "navn": "Shoe Polish ",
        "pris": 28.2
      }
    ],
    "butikk": "Rema",
    "summen": 88.39999999999999,
    "UkeNr": 36,
    "timestamp": "33",
    "documentID": "lP1YQgM0rKmGZkklfSns"
  },
  {
    "dato": "2018-09-05T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "TgeM0CYPN7kBQeBQl6av",
        "totalPris": 159,
        "navn": "Kjøkkenvekt",
        "pris": 159
      }
    ],
    "butikk": "Clas Ohlson",
    "summen": 159,
    "UkeNr": 36,
    "timestamp": "32",
    "documentID": "DPvTtWF3eZGPqMUESHvu"
  },
  {
    "dato": "2018-09-05T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7311040640228",
        "totalPris": 29,
        "navn": "Oliven-0,34K-sorte",
        "pris": 29
      }
    ],
    "butikk": "Bunnpris",
    "summen": 29,
    "UkeNr": 36,
    "timestamp": "31",
    "documentID": "rQyHVh0gdwZSZigTnJw7"
  },
  {
    "dato": "2018-09-04T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "8bH8ZfnbTOU1AhE3e5N9",
        "totalPris": 17.9,
        "navn": "Konvolutt",
        "pris": 17.9
      }
    ],
    "butikk": "Posten",
    "summen": 17.9,
    "UkeNr": 36,
    "timestamp": "30",
    "documentID": "0SVWwqLT5qp0EMCyliHI"
  },
  {
    "dato": "2018-09-04T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 101,
        "navn": "Snus General",
        "pris": 101
      },
      {
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 91,
        "navn": "Snus G4",
        "pris": 91
      },
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 19.9,
        "navn": "KulturMelk",
        "pris": 19.9
      },
      {
        "mengde": 1,
        "produktID": "7038010055676",
        "totalPris": 21.2,
        "navn": "Yoghurt-0,5K-vanilje",
        "pris": 21.2
      }
    ],
    "butikk": "Bunnpris",
    "summen": 233.1,
    "UkeNr": 36,
    "timestamp": "29",
    "documentID": "dyIdIAGiTLWbfMV98TzC"
  },
  {
    "dato": "2018-09-03T00:00:00",
    "varer": [
      {
        "mengde": 4,
        "produktID": "7311041019757",
        "totalPris": 53.6,
        "navn": "Formaggio",
        "pris": 13.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 53.6,
    "UkeNr": 36,
    "timestamp": "28",
    "documentID": "WzZp4D6VVQUYEIyE7DxX"
  },
  {
    "dato": "2018-09-03T00:00:00",
    "varer": [
      {
        "mengde": 3,
        "produktID": "7050122131611",
        "totalPris": 47.7,
        "navn": "Dipmix",
        "pris": 15.9
      },
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 19.7,
        "navn": "KulturMelk",
        "pris": 19.7
      },
      {
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 25.7,
        "navn": "Melk-stor-0,5-Q",
        "pris": 25.7
      },
      {
        "mengde": 1,
        "produktID": "7038010005459",
        "totalPris": 17.8,
        "navn": "Rømme-lett0,18",
        "pris": 17.8
      },
      {
        "mengde": 1,
        "produktID": "2302148200006",
        "totalPris": 73.12,
        "navn": "Norvegia-1K",
        "pris": 73.12
      },
      {
        "mengde": 1,
        "produktID": "7039610000172",
        "totalPris": 43.9,
        "navn": "Egg-12",
        "pris": 43.9
      }
    ],
    "butikk": "Spar",
    "summen": 227.92000000000002,
    "UkeNr": 36,
    "timestamp": "27",
    "documentID": "4801DN9nAHqL1IVMSyja"
  },
  {
    "dato": "2018-09-02T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7311041048931",
        "totalPris": 31.9,
        "navn": "NøtterMix",
        "pris": 31.9
      },
      {
        "mengde": 1,
        "produktID": "7041611018124",
        "totalPris": 31.2,
        "navn": "Brød-NORSK FJELLBRØD",
        "pris": 31.2
      }
    ],
    "butikk": "Rema",
    "summen": 63.099999999999994,
    "UkeNr": 35,
    "timestamp": "26",
    "documentID": "MM7fjSHBSPXRzrgA8Fwb"
  },
  {
    "dato": "2018-08-30T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7090007520765",
        "totalPris": 29.8,
        "navn": "Krydder-pizza",
        "pris": 29.8
      }
    ],
    "butikk": "Rema",
    "summen": 29.8,
    "UkeNr": 35,
    "timestamp": "25",
    "documentID": "ZAYXxYVbmVftJO4LzA4j"
  },
  {
    "dato": "2018-08-27T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7039610005849",
        "totalPris": 49.9,
        "navn": "Egg-18",
        "pris": 49.9
      },
      {
        "mengde": 1,
        "produktID": "7038010007231",
        "totalPris": 19.9,
        "navn": "appelsinjuice-Sunniva",
        "pris": 19.9
      },
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 19.9,
        "navn": "KulturMelk",
        "pris": 19.9
      },
      {
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 15,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 15
      }
    ],
    "butikk": "Bunnpris",
    "summen": 104.69999999999999,
    "UkeNr": 35,
    "timestamp": "23",
    "documentID": "6ZQUqXTt0sJe8eNP8vEc"
  },
  {
    "dato": "2018-08-27T00:00:00",
    "varer": [
      {
        "mengde": 6,
        "produktID": "7311041019757",
        "totalPris": 80.4,
        "navn": "Formaggio",
        "pris": 13.4
      }
    ],
    "butikk": "Kiwi",
    "summen": 80.4,
    "UkeNr": 35,
    "timestamp": "22",
    "documentID": "m0dj6xVjZJjBYt4cjdEi"
  },
  {
    "dato": "2018-08-26T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "5710557161110",
        "totalPris": 167,
        "navn": "Kjøtt-MB",
        "pris": 167
      },
      {
        "mengde": 1,
        "produktID": "5319991692329",
        "totalPris": 54,
        "navn": "Sterk saus",
        "pris": 54
      }
    ],
    "butikk": "SlettenButikk",
    "summen": 221,
    "UkeNr": 34,
    "timestamp": "21",
    "documentID": "UUaF1t7D70x7SLUzWiaj"
  },
  {
    "dato": "2018-08-24T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "4EHpBRhZKxqMdg1jHwvB",
        "totalPris": 20.7,
        "navn": "Tøyvask",
        "pris": 20.7
      },
      {
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 91,
        "navn": "Snus G4",
        "pris": 91
      }
    ],
    "butikk": "Bunnpris",
    "summen": 111.7,
    "UkeNr": 34,
    "timestamp": "20",
    "documentID": "YwbKx8sBW0JmFZFuZm2L"
  },
  {
    "dato": "2018-08-24T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "mengde": 1,
        "produktID": "7041611018124",
        "totalPris": 23.9,
        "navn": "Brød-NORSK FJELLBRØD",
        "pris": 23.9
      },
      {
        "mengde": 1,
        "produktID": "X0CWKFVB2YvVGWxTIvAL",
        "totalPris": 19.9,
        "navn": "Tomater-løsvekt",
        "pris": 19.9
      }
    ],
    "butikk": "CoopExtra",
    "summen": 61.699999999999996,
    "UkeNr": 34,
    "timestamp": "19",
    "documentID": "XYTzEtHCAcvQQGRILmIY"
  },
  {
    "dato": "2018-08-21T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7035110121607",
        "totalPris": 20.6,
        "navn": "Fiskepinner-Findus-15",
        "pris": 20.6
      },
      {
        "mengde": 1,
        "produktID": "7038010005459",
        "totalPris": 16.9,
        "navn": "Rømme-lett0,18",
        "pris": 16.9
      },
      {
        "mengde": 2,
        "produktID": "7050122131611",
        "totalPris": 27.8,
        "navn": "Dipmix",
        "pris": 13.9
      },
      {
        "mengde": 0.2,
        "produktID": "4KeSDukfltn25JH80ERO",
        "totalPris": 7.83,
        "navn": "Lime-løsvekt",
        "pris": 39.15
      },
      {
        "mengde": 1,
        "produktID": "gQM2a4duq2YJvD7HeA18",
        "totalPris": 28.9,
        "navn": "Toalettrens ",
        "pris": 28.9
      }
    ],
    "butikk": "Kiwi",
    "summen": 102.03,
    "UkeNr": 34,
    "timestamp": "18",
    "documentID": "grwXhcWQ5DQ6EQHQC2Vo"
  },
  {
    "dato": "2018-08-21T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7311041013441",
        "totalPris": 16.5,
        "navn": "MusliCrunchy-FirstPrice",
        "pris": 16.5
      },
      {
        "mengde": 1,
        "produktID": "7041611018124",
        "totalPris": 26.9,
        "navn": "Brød-NORSK FJELLBRØD",
        "pris": 26.9
      }
    ],
    "butikk": "Bunnpris",
    "summen": 43.4,
    "UkeNr": 34,
    "timestamp": "17",
    "documentID": "1Qcnqd2fHvODvDXU8dEs"
  },
  {
    "dato": "2018-08-21T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7311041029299",
        "totalPris": 12.5,
        "navn": "Pesto grønn- Eldorado",
        "pris": 12.5
      }
    ],
    "butikk": "Bunnpris",
    "summen": 12.5,
    "UkeNr": 34,
    "timestamp": "16",
    "documentID": "L2KizlgHhQsQYsvIcC3c"
  },
  {
    "dato": "2018-08-20T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 19.9,
        "navn": "KulturMelk",
        "pris": 19.9
      },
      {
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 15,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 15
      }
    ],
    "butikk": "Bunnpris",
    "summen": 34.9,
    "UkeNr": 34,
    "timestamp": "15",
    "documentID": "ZSSUCiR7zhfKEGlkxbvK"
  },
  {
    "dato": "2018-08-19T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7311250013355",
        "totalPris": 109.5,
        "navn": "Snus General",
        "pris": 109.5
      },
      {
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 89.9,
        "navn": "Snus G4",
        "pris": 89.9
      }
    ],
    "butikk": "Rema",
    "summen": 199.4,
    "UkeNr": 33,
    "timestamp": "14",
    "documentID": "zI2rGyBV6ODVezh39Tsx"
  },
  {
    "dato": "2018-08-17T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7041611018124",
        "totalPris": 28.5,
        "navn": "Brød-NORSK FJELLBRØD",
        "pris": 28.5
      },
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "mengde": 1,
        "produktID": "7039610005849",
        "totalPris": 47.8,
        "navn": "Egg-18",
        "pris": 47.8
      },
      {
        "mengde": 1,
        "produktID": "7038010045080",
        "totalPris": 26.9,
        "navn": "Yoghurt-0,85K-vanilje",
        "pris": 26.9
      },
      {
        "mengde": 2,
        "produktID": "7048840000500",
        "totalPris": 25,
        "navn": "Melk-1L-0,5-Q",
        "pris": 12.5
      }
    ],
    "butikk": "CoopExtra",
    "summen": 146.1,
    "UkeNr": 33,
    "timestamp": "13",
    "documentID": "sRlbZDLpdFB6PRgmSE4a"
  },
  {
    "dato": "2018-08-17T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "2302148200006",
        "totalPris": 90.22,
        "navn": "Norvegia-1K",
        "pris": 90.22
      },
      {
        "mengde": 4,
        "produktID": "7311041019757",
        "totalPris": 53.6,
        "navn": "Formaggio",
        "pris": 13.4
      },
      {
        "mengde": 1,
        "produktID": "7040913334390",
        "totalPris": 129,
        "navn": "Kaffe-0,25K",
        "pris": 129
      }
    ],
    "butikk": "Kiwi",
    "summen": 272.82,
    "UkeNr": 33,
    "timestamp": "12",
    "documentID": "x7RO9oz3oSfp882PvuNF"
  },
  {
    "dato": "2018-08-13T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7038010055690",
        "totalPris": 16.4,
        "navn": "Yoghurt-0,5K-skogsbær",
        "pris": 16.4
      },
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 17.9,
        "navn": "KulturMelk",
        "pris": 17.9
      },
      {
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 23.4,
        "navn": "Melk-stor-0,5-Q",
        "pris": 23.4
      },
      {
        "mengde": 1,
        "produktID": "ZRapwUHuS2C3jFcie9Bp",
        "totalPris": 20.4,
        "navn": "shoes'  Shine sponge",
        "pris": 20.4
      },
      {
        "mengde": 1,
        "produktID": "7038010005459",
        "totalPris": 16.9,
        "navn": "Rømme-lett0,18",
        "pris": 16.9
      },
      {
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 89,
        "navn": "Snus G4",
        "pris": 89
      }
    ],
    "butikk": "Kiwi",
    "summen": 184,
    "UkeNr": 33,
    "timestamp": "11",
    "documentID": "LWGRGT2hVCbHaEpGs3MR"
  },
  {
    "dato": "2018-08-14T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7041611018124",
        "totalPris": 25,
        "navn": "Brød-NORSK FJELLBRØD",
        "pris": 25
      },
      {
        "mengde": 1,
        "produktID": "7032069715253",
        "totalPris": 17.9,
        "navn": "MusliCrunchy-Rema1000",
        "pris": 17.9
      },
      {
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": 0.1,
        "navn": "avrunding",
        "pris": 0.1
      }
    ],
    "butikk": "Rema",
    "summen": 43,
    "UkeNr": 33,
    "timestamp": "10",
    "documentID": "hUGmuLiG4klSYDovJTQ4"
  },
  {
    "dato": "2018-08-13T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "Xl1z78QoBR5E9P0hufjV",
        "totalPris": 23.9,
        "navn": "Filterposer",
        "pris": 23.9
      }
    ],
    "butikk": "Bunnpris",
    "summen": 23.9,
    "UkeNr": 33,
    "timestamp": "9",
    "documentID": "upXsdztO6KBgCwfFVVtc"
  },
  {
    "dato": "2018-08-10T00:00:00",
    "varer": [
      {
        "mengde": 6,
        "produktID": "h7mi21cM59LmbSoppzZw",
        "totalPris": 60,
        "navn": "Toalettpapir",
        "pris": 10
      },
      {
        "mengde": 1,
        "produktID": "alzmU8vv3SbAsDiaMlmr",
        "totalPris": 1,
        "navn": "Pose",
        "pris": 1
      }
    ],
    "butikk": "Meny",
    "summen": 61,
    "UkeNr": 32,
    "timestamp": "8",
    "documentID": "2077caffSk0F8CyvjIDO"
  },
  {
    "dato": "2018-08-10T00:00:00",
    "varer": [
      {
        "mengde": 7,
        "produktID": "7311041019757",
        "totalPris": 93.8,
        "navn": "Formaggio",
        "pris": 13.4
      },
      {
        "mengde": 1,
        "produktID": "7041614000867",
        "totalPris": 16.8,
        "navn": "Brød-HVERDAGSGROVT",
        "pris": 16.8
      },
      {
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": 0.4,
        "navn": "avrunding",
        "pris": 0.4
      }
    ],
    "butikk": "Kiwi",
    "summen": 111,
    "UkeNr": 32,
    "timestamp": "7",
    "documentID": "O8zedHvXP38eeix3ylVZ"
  },
  {
    "dato": "2018-08-09T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "438tIJyY0SrNuAF845j4",
        "totalPris": 489,
        "navn": "Whey Protein-3K-Tri-Whey",
        "pris": 489
      }
    ],
    "butikk": "XXL",
    "summen": 489,
    "UkeNr": 32,
    "timestamp": "6",
    "documentID": "RebPoQau6aAWQigz1DJy"
  },
  {
    "dato": "2018-08-06T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "dzer1URthCx9XaaweH9K",
        "totalPris": 250,
        "navn": "Fritak",
        "pris": 250
      }
    ],
    "butikk": "Nygård Skole",
    "summen": 250,
    "UkeNr": 32,
    "timestamp": "5",
    "documentID": "JDwZsmz3VbgPyVR2jLlx"
  },
  {
    "dato": "2018-08-06T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7034281131002",
        "totalPris": 58.88,
        "navn": "Ost synnøve-1K",
        "pris": 58.88
      },
      {
        "mengde": 1,
        "produktID": "7039610005849",
        "totalPris": 47.8,
        "navn": "Egg-18",
        "pris": 47.8
      },
      {
        "mengde": 1,
        "produktID": "7041614000867",
        "totalPris": 16.9,
        "navn": "Brød-HVERDAGSGROVT",
        "pris": 16.9
      },
      {
        "mengde": 1,
        "produktID": "7038010045080",
        "totalPris": 26.9,
        "navn": "Yoghurt-0,85K-vanilje",
        "pris": 26.9
      }
    ],
    "butikk": "Extra",
    "summen": 150.48000000000002,
    "UkeNr": 32,
    "timestamp": "4",
    "documentID": "RJ4jDJX3uxgC2zcTORwp"
  },
  {
    "dato": "2018-08-03T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "3PJMLKsAi7fp6oUIvwcU",
        "totalPris": 11.2,
        "navn": "ukjent",
        "pris": 11.2
      },
      {
        "mengde": 1,
        "produktID": "3PJMLKsAi7fp6oUIvwcU",
        "totalPris": 20,
        "navn": "ukjent",
        "pris": 20
      },
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 18.4,
        "navn": "KulturMelk",
        "pris": 18.4
      },
      {
        "mengde": 1,
        "produktID": "7048840081950",
        "totalPris": 24.9,
        "navn": "Melk-stor-0,5-Q",
        "pris": 24.9
      },
      {
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": 0.5,
        "navn": "avrunding",
        "pris": 0.5
      }
    ],
    "butikk": "Rema",
    "summen": 75,
    "UkeNr": 31,
    "timestamp": "3",
    "documentID": "Q53WGtYATd3lh229Gzl1"
  },
  {
    "dato": "2018-08-03T00:00:00",
    "varer": [
      {
        "mengde": 7,
        "produktID": "7311041019757",
        "totalPris": 89.60000000000001,
        "navn": "Formaggio",
        "pris": 12.8
      },
      {
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": 0.4,
        "navn": "avrunding",
        "pris": 0.4
      }
    ],
    "butikk": "Bunnpris",
    "summen": 90.00000000000001,
    "UkeNr": 31,
    "timestamp": "2",
    "documentID": "rIhP6UhGvetG6kEkT7bc"
  },
  {
    "dato": "2018-08-01T00:00:00",
    "varer": [
      {
        "mengde": 1,
        "produktID": "7032069715253",
        "totalPris": 17.9,
        "navn": "MusliCrunchy-Rema1000",
        "pris": 17.9
      },
      {
        "mengde": 1,
        "produktID": "7038010045073",
        "totalPris": 29.9,
        "navn": "Yoghurt-0,85K-naturell",
        "pris": 29.9
      },
      {
        "mengde": 1,
        "produktID": "48327203421",
        "totalPris": 76.9,
        "navn": "Olje-Oliven-Ybarra",
        "pris": 76.9
      },
      {
        "mengde": 1,
        "produktID": "7038010000737",
        "totalPris": 18.4,
        "navn": "KulturMelk",
        "pris": 18.4
      },
      {
        "mengde": 1,
        "produktID": "7035620035821",
        "totalPris": 22.9,
        "navn": "Sjokoladepålegg-FirstPrice-N",
        "pris": 22.9
      },
      {
        "mengde": 1,
        "produktID": "7311250083976",
        "totalPris": 89.9,
        "navn": "Snus G4",
        "pris": 89.9
      },
      {
        "mengde": 1,
        "produktID": "ZN8EaAMkqhWx1iOYmVRc",
        "totalPris": 0.1,
        "navn": "avrunding",
        "pris": 0.1
      }
    ],
    "butikk": "Rema",
    "summen": 256,
    "UkeNr": 31,
    "timestamp": "1",
    "documentID": "qOxBoLF40lVfUthxXBAv"
  }
];

var produktCollection = [
  {
    "strekkode": 6210242355163,
    "nettovekt": 0.4,
    "navn": "Bønner FoulMudemass ",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 14,
        "Mettet fett": 0.5,
        "Enumettet": 0,
        "Salt": 1.17,
        "Energi": 485,
        "Stivelse": 0,
        "Sukkerarter": 1,
        "Kostfiber": 0,
        "Kalorier": 116,
        "Fett": 4.8,
        "Protein": 5
      }
    },
    "documentID": "6210242355163"
  },
  {
    "strekkode": 5281003554102,
    "nettovekt": 0.4,
    "navn": "Bønner - Al Rabih",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 17,
        "Mettet fett": 0,
        "Enumettet": 0,
        "Salt": 0.4,
        "Energi": 416,
        "Stivelse": 0,
        "Sukkerarter": 1.5,
        "Kostfiber": 7,
        "Kalorier": 100,
        "Fett": 0,
        "Protein": 9
      }
    },
    "documentID": "5281003554102"
  },
  {
    "strekkode": 7032060010999,
    "nettovekt": 0.2,
    "navn": "Reker i Lake",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 1.2,
        "Mettet fett": 0,
        "Enumettet": 0,
        "Salt": 2.4,
        "Energi": 344,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 82,
        "Fett": 1.2,
        "Protein": 18.8
      }
    },
    "documentID": "7032060010999"
  },
  {
    "strekkode": 101010103276,
    "nettovekt": 1,
    "navn": "Valnøtter - løsvekt",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 45,
        "Karbohydrater": 13.71,
        "Mettet fett": 7,
        "Enumettet": 10,
        "Salt": 0,
        "Energi": 2738,
        "Stivelse": 0,
        "Sukkerarter": 3,
        "Kostfiber": 7,
        "Kalorier": 654,
        "Fett": 65,
        "Protein": 15
      }
    },
    "documentID": "101010103276"
  },
  {
    "strekkode": 606449098761,
    "nettovekt": 0,
    "navn": "Wi-Fi USB adapter",
    "matvare": false,
    "info": " ",
    "documentID": "606449098761"
  },
  {
    "strekkode": 7393173278752,
    "nettovekt": 0,
    "navn": "Nettverk tester",
    "matvare": false,
    "info": " ",
    "documentID": "7393173278752"
  },
  {
    "strekkode": 7050122131574,
    "nettovekt": 0.022,
    "navn": "Dipmix holiday",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 61,
        "Mettet fett": 0.2,
        "Enumettet": 0,
        "Salt": 20.8,
        "Energi": 1255,
        "Stivelse": 0,
        "Sukkerarter": 31,
        "Kostfiber": 0,
        "Kalorier": 300,
        "Fett": 2.3,
        "Protein": 6.4
      }
    },
    "documentID": "7050122131574"
  },
  {
    "strekkode": 7038010062735,
    "nettovekt": 0.85,
    "navn": "Yoghurt-0.85K-Mango",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 11,
        "Mettet fett": 2,
        "Enumettet": 0,
        "Salt": 0.1,
        "Energi": 357,
        "Stivelse": 0,
        "Sukkerarter": 10,
        "Kostfiber": 0,
        "Kalorier": 85,
        "Fett": 3.1,
        "Protein": 3.7
      }
    },
    "documentID": "7038010062735"
  },
  {
    "strekkode": 101010101265,
    "nettovekt": 1,
    "navn": "Paprika-chili-løsvekt",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 7.8,
        "Mettet fett": 0.1,
        "Enumettet": 0.1,
        "Salt": 0,
        "Energi": 160,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 40,
        "Fett": 0.3,
        "Protein": 0.5
      }
    },
    "documentID": "101010101265"
  },
  {
    "strekkode": 7071867100014,
    "nettovekt": 0.65,
    "navn": "Brød- Midtøsten ",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0.9,
        "Karbohydrater": 52.2,
        "Mettet fett": 0.3,
        "Enumettet": 0.7,
        "Salt": 0.3,
        "Energi": 1131,
        "Stivelse": 0,
        "Sukkerarter": 3.3,
        "Kostfiber": 2.2,
        "Kalorier": 267,
        "Fett": 2.2,
        "Protein": 8.5
      }
    },
    "documentID": "7071867100014"
  },
  {
    "strekkode": 7046110002094,
    "nettovekt": 0.5,
    "navn": "Zalo oppvaskmiddel ",
    "matvare": false,
    "info": " ",
    "documentID": "7046110002094"
  },
  {
    "strekkode": 7045010003699,
    "nettovekt": 0.036,
    "navn": "Krydder PepperMix",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 40.4,
        "Mettet fett": 1,
        "Enumettet": 0,
        "Salt": 0,
        "Energi": 1194,
        "Stivelse": 0,
        "Sukkerarter": 0.3,
        "Kostfiber": 23.5,
        "Kalorier": 285,
        "Fett": 3.3,
        "Protein": 9.9
      }
    },
    "documentID": "7045010003699"
  },
  {
    "strekkode": 2302436905026,
    "nettovekt": 0.5,
    "navn": "Ost Jarlsberg-0,5K",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 0,
        "Mettet fett": 18,
        "Enumettet": 0,
        "Salt": 1.2,
        "Energi": 1512,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 364,
        "Fett": 28,
        "Protein": 28
      }
    },
    "documentID": "2302436905026"
  },
  {
    "strekkode": 7045010003156,
    "nettovekt": 0.07,
    "navn": "Krydder - kyllingkrydder",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 7.6,
        "Mettet fett": 0.6,
        "Enumettet": 0,
        "Salt": 56.2,
        "Energi": 535,
        "Stivelse": 0,
        "Sukkerarter": 2.8,
        "Kostfiber": 10.2,
        "Kalorier": 128,
        "Fett": 3.8,
        "Protein": 11.9
      }
    },
    "documentID": "7045010003156"
  },
  {
    "strekkode": 7025110160478,
    "nettovekt": 0.19,
    "navn": "Røkt laks - Xtra",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 0,
        "Mettet fett": 1.6,
        "Enumettet": 0,
        "Salt": 3,
        "Energi": 749,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 190,
        "Fett": 11,
        "Protein": 22
      }
    },
    "documentID": "7025110160478"
  },
  {
    "strekkode": 5031020038761,
    "nettovekt": 0.18,
    "navn": "Røkt laks - FirstPrice",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 0,
        "Mettet fett": 2.5,
        "Enumettet": 0,
        "Salt": 3,
        "Energi": 938,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 225,
        "Fett": 14.7,
        "Protein": 23.2
      }
    },
    "documentID": "5031020038761"
  },
  {
    "strekkode": 101010103696,
    "nettovekt": 0.4,
    "navn": "Salat",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 1.5,
        "Mettet fett": 0.0,
        "Enumettet": 0,
        "Salt": 0,
        "Energi": 51,
        "Stivelse": 0,
        "Sukkerarter": 1.5,
        "Kostfiber": 1.1,
        "Kalorier": 12,
        "Fett": 0.1,
        "Protein": 0.8
      }
    },
    "documentID": "101010103696"
  },
  {
    "strekkode": 101010109889,
    "nettovekt": 1,
    "navn": "Mandler-løsvekt",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 12,
        "Karbohydrater": 16,
        "Mettet fett": 8,
        "Enumettet": 30,
        "Salt": 5,
        "Energi": 2420,
        "Stivelse": 1,
        "Sukkerarter": 5,
        "Kostfiber": 10,
        "Kalorier": 580,
        "Fett": 50,
        "Protein": 20
      }
    },
    "documentID": "101010109889"
  },
  {
    "strekkode": 101010108189,
    "nettovekt": 0,
    "navn": "Vifte- Gulv-ogBordvifte",
    "matvare": false,
    "info": " ",
    "documentID": "101010108189"
  },
  {
    "strekkode": 101010102675,
    "nettovekt": 0,
    "navn": "Retur",
    "matvare": false,
    "info": " ",
    "documentID": "101010102675"
  },
  {
    "strekkode": 101010108356,
    "nettovekt": 0,
    "navn": "Batteri-U9VL",
    "matvare": false,
    "info": " ",
    "documentID": "101010108356"
  },
  {
    "strekkode": 7048840200979,
    "nettovekt": 1.75,
    "navn": "Melk-stor-Hel-Q",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 4.4,
        "Mettet fett": 2.6,
        "Enumettet": 0,
        "Salt": 0.1,
        "Energi": 279,
        "Stivelse": 0,
        "Sukkerarter": 4.4,
        "Kostfiber": 0,
        "Kalorier": 67,
        "Fett": 4,
        "Protein": 3.3
      }
    },
    "documentID": "7048840200979"
  },
  {
    "strekkode": 7048840000012,
    "nettovekt": 1,
    "navn": "Melk-1L-Hel-Q",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 4.4,
        "Mettet fett": 2.6,
        "Enumettet": 0,
        "Salt": 0.1,
        "Energi": 275,
        "Stivelse": 0,
        "Sukkerarter": 4.4,
        "Kostfiber": 0,
        "Kalorier": 66,
        "Fett": 3.9,
        "Protein": 3.3
      }
    },
    "documentID": "7048840000012"
  },
  {
    "strekkode": 7038010052422,
    "nettovekt": 1.75,
    "navn": "Melk-stor-Hel-Tine",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 4.5,
        "Mettet fett": 2.3,
        "Enumettet": 0,
        "Salt": 0.1,
        "Energi": 264,
        "Stivelse": 0,
        "Sukkerarter": 4.5,
        "Kostfiber": 0,
        "Kalorier": 63,
        "Fett": 3.5,
        "Protein": 3.4
      }
    },
    "documentID": "7038010052422"
  },
  {
    "strekkode": 7038010000065,
    "nettovekt": 1,
    "navn": "Melk-1L-Hel-Tine",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 4.5,
        "Mettet fett": 2.3,
        "Enumettet": 0,
        "Salt": 0.1,
        "Energi": 264,
        "Stivelse": 0,
        "Sukkerarter": 4.5,
        "Kostfiber": 0,
        "Kalorier": 63,
        "Fett": 3.5,
        "Protein": 3.4
      }
    },
    "documentID": "7038010000065"
  },
  {
    "strekkode": 101010103467,
    "nettovekt": 0.7,
    "navn": "Brød-bondebrød",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 2.5,
        "Karbohydrater": 35.2,
        "Mettet fett": 0.8,
        "Enumettet": 1.8,
        "Salt": 0.97,
        "Energi": 1060,
        "Stivelse": 0,
        "Sukkerarter": 2,
        "Kostfiber": 6.7,
        "Kalorier": 252,
        "Fett": 5.8,
        "Protein": 11.3
      }
    },
    "documentID": "101010103467"
  },
  {
    "strekkode": 101010106932,
    "nettovekt": 0,
    "navn": "Sim-kort",
    "matvare": false,
    "info": " ",
    "documentID": "101010106932"
  },
  {
    "strekkode": 101010108738,
    "nettovekt": 1.8,
    "navn": "Kylling-Ytterøy-Kyllingfilet",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 0,
        "Mettet fett": 0.3,
        "Enumettet": 0,
        "Salt": 0.1,
        "Energi": 439,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 105,
        "Fett": 1,
        "Protein": 23.8
      }
    },
    "documentID": "101010108738"
  },
  {
    "strekkode": 7072175104930,
    "nettovekt": 1.8,
    "navn": "Kylling-ytterøy-Lårbiff",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 0,
        "Mettet fett": 2.3,
        "Enumettet": 0,
        "Salt": 0.2,
        "Energi": 632,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 151,
        "Fett": 8.8,
        "Protein": 18
      }
    },
    "documentID": "7072175104930"
  },
  {
    "strekkode": 101010104761,
    "nettovekt": 0,
    "navn": "Sokker-5stykker",
    "matvare": false,
    "info": " ",
    "documentID": "101010104761"
  },
  {
    "strekkode": 8690103115538,
    "nettovekt": 0.5,
    "navn": "Oliven-0,5K-Tyrkisk",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 5.7,
        "Mettet fett": 5.9,
        "Enumettet": 0,
        "Salt": 5.5,
        "Energi": 1499,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 2.2,
        "Kalorier": 364,
        "Fett": 36.6,
        "Protein": 1.8
      }
    },
    "documentID": "8690103115538"
  },
  {
    "strekkode": 101010101333,
    "nettovekt": 0,
    "navn": "tilbud",
    "matvare": false,
    "info": " ",
    "documentID": "101010101333"
  },
  {
    "strekkode": 7038010055669,
    "nettovekt": 0.5,
    "navn": "Yoghurt-0,5K-Melon",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 12,
        "Mettet fett": 2,
        "Enumettet": 0,
        "Salt": 0.1,
        "Energi": 377,
        "Stivelse": 0,
        "Sukkerarter": 11,
        "Kostfiber": 0,
        "Kalorier": 90,
        "Fett": 3,
        "Protein": 3.7
      }
    },
    "documentID": "7038010055669"
  },
  {
    "strekkode": 7038010053368,
    "nettovekt": 0.7,
    "navn": "Ost Jarlsbergost 0,7K",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 0,
        "Mettet fett": 17,
        "Enumettet": 0,
        "Salt": 1.1,
        "Energi": 1458,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 351,
        "Fett": 27,
        "Protein": 27
      }
    },
    "documentID": "7038010053368"
  },
  {
    "strekkode": 8712561851084,
    "nettovekt": 0,
    "navn": "Sun - oppvaskmiddel ",
    "matvare": false,
    "info": " ",
    "documentID": "8712561851084"
  },
  {
    "strekkode": 101010108318,
    "nettovekt": 0.5,
    "navn": "spaghetti-0.5k",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 65,
        "Mettet fett": 0.5,
        "Enumettet": 0,
        "Salt": 0,
        "Energi": 1500,
        "Stivelse": 72,
        "Sukkerarter": 3,
        "Kostfiber": 2,
        "Kalorier": 350,
        "Fett": 2,
        "Protein": 14
      }
    },
    "documentID": "101010108318"
  },
  {
    "strekkode": 7032069725788,
    "nettovekt": 0.5,
    "navn": "Olje-Oliven Extra virgin",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 8.1,
        "Karbohydrater": 0,
        "Mettet fett": 13,
        "Enumettet": 67.0,
        "Salt": 0,
        "Energi": 3404,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 828,
        "Fett": 92,
        "Protein": 0
      }
    },
    "documentID": "7032069725788"
  },
  {
    "strekkode": 101010109254,
    "nettovekt": 0,
    "navn": "Aluminiumfolie",
    "matvare": false,
    "info": " ",
    "documentID": "101010109254"
  },
  {
    "strekkode": 101010103238,
    "nettovekt": 0,
    "navn": "Jif- WC",
    "matvare": false,
    "info": " ",
    "documentID": "101010103238"
  },
  {
    "strekkode": 101010101067,
    "nettovekt": 0.075,
    "navn": "Brød-Rundstykker",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 1,
        "Karbohydrater": 50,
        "Mettet fett": 0.5,
        "Enumettet": 0.5,
        "Salt": 0.8,
        "Energi": 950,
        "Stivelse": 10,
        "Sukkerarter": 1.5,
        "Kostfiber": 8,
        "Kalorier": 230,
        "Fett": 2,
        "Protein": 10
      }
    },
    "documentID": "101010101067"
  },
  {
    "strekkode": 7393173362840,
    "nettovekt": 0,
    "navn": "Wifi Smart Bulb",
    "matvare": false,
    "info": " ",
    "documentID": "7393173362840"
  },
  {
    "strekkode": 6410708762683,
    "nettovekt": 0.5,
    "navn": "Olje-Oliven eldorado",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 8.2,
        "Karbohydrater": 0,
        "Mettet fett": 12.8,
        "Enumettet": 70.4,
        "Salt": 0,
        "Energi": 3381,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 822,
        "Fett": 91.4,
        "Protein": 0
      }
    },
    "documentID": "6410708762683"
  },
  {
    "strekkode": 101010105850,
    "nettovekt": 0.446,
    "navn": "Ost Jarlsbergost-0,45K",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 0,
        "Mettet fett": 17,
        "Enumettet": 0,
        "Salt": 1.1,
        "Energi": 1458,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 351,
        "Fett": 27,
        "Protein": 27
      }
    },
    "documentID": "101010105850"
  },
  {
    "strekkode": 101010109865,
    "nettovekt": 0,
    "navn": "Shampoo",
    "matvare": false,
    "info": " ",
    "documentID": "101010109865"
  },
  {
    "strekkode": 7393173281356,
    "nettovekt": 0,
    "navn": "Batteri-ClasOhlson X18",
    "matvare": false,
    "info": " ",
    "documentID": "7393173281356"
  },
  {
    "strekkode": 7393173222717,
    "nettovekt": 0,
    "navn": "Batteri-ClasOhlson X10",
    "matvare": false,
    "info": " ",
    "documentID": "7393173222717"
  },
  {
    "strekkode": 101010108141,
    "nettovekt": 0,
    "navn": "sykkellykt bak",
    "matvare": false,
    "info": " ",
    "documentID": "101010108141"
  },
  {
    "strekkode": 101010103382,
    "nettovekt": 0,
    "navn": "USB-minne",
    "matvare": false,
    "info": " ",
    "documentID": "101010103382"
  },
  {
    "strekkode": 101010105157,
    "nettovekt": 0,
    "navn": "SSD Kingston A400 120GB",
    "matvare": false,
    "info": " ",
    "documentID": "101010105157"
  },
  {
    "strekkode": 101010106772,
    "nettovekt": 0,
    "navn": "Lydkabel for headset",
    "matvare": false,
    "info": " ",
    "documentID": "101010106772"
  },
  {
    "strekkode": 101010109926,
    "nettovekt": 0,
    "navn": "Lydkort USB",
    "matvare": false,
    "info": " ",
    "documentID": "101010109926"
  },
  {
    "strekkode": 101010104686,
    "nettovekt": 0,
    "navn": "brevsendings porto",
    "matvare": false,
    "info": " ",
    "documentID": "101010104686"
  },
  {
    "strekkode": 101010103832,
    "nettovekt": 0,
    "navn": "Tallerken ",
    "matvare": false,
    "info": " ",
    "documentID": "101010103832"
  },
  {
    "strekkode": 101010101432,
    "nettovekt": 0,
    "navn": "Drikkeglass",
    "matvare": false,
    "info": " ",
    "documentID": "101010101432"
  },
  {
    "strekkode": 101010109346,
    "nettovekt": 0,
    "navn": "Feil",
    "matvare": false,
    "info": " ",
    "documentID": "101010109346"
  },
  {
    "strekkode": 101010101975,
    "nettovekt": 0.25,
    "navn": "Ost skiver-Jarlsbergost",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 0,
        "Mettet fett": 17,
        "Enumettet": 0,
        "Salt": 1.1,
        "Energi": 1458,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 351,
        "Fett": 27,
        "Protein": 27
      }
    },
    "documentID": "101010101975"
  },
  {
    "strekkode": 101010102637,
    "nettovekt": 0,
    "navn": "Rørisolasjon",
    "matvare": false,
    "info": " ",
    "documentID": "101010102637"
  },
  {
    "strekkode": 101010104525,
    "nettovekt": 0.05,
    "navn": "hvitløk-1stk",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0.6,
        "Karbohydrater": 18.6,
        "Mettet fett": 0,
        "Enumettet": 0,
        "Salt": 0,
        "Energi": 480,
        "Stivelse": 0,
        "Sukkerarter": 3.9,
        "Kostfiber": 1.7,
        "Kalorier": 115,
        "Fett": 0.6,
        "Protein": 7.9
      }
    },
    "documentID": "101010104525"
  },
  {
    "strekkode": 101010106291,
    "nettovekt": 1,
    "navn": "Klor FirstPrice",
    "matvare": false,
    "info": " ",
    "documentID": "101010106291"
  },
  {
    "strekkode": 101010104143,
    "nettovekt": 0,
    "navn": "slipeark",
    "matvare": false,
    "info": " ",
    "documentID": "101010104143"
  },
  {
    "strekkode": 101010104969,
    "nettovekt": 0,
    "navn": "Vevteip",
    "matvare": false,
    "info": " ",
    "documentID": "101010104969"
  },
  {
    "strekkode": 101010103979,
    "nettovekt": 0,
    "navn": "Sykkeldekk ",
    "matvare": false,
    "info": " ",
    "documentID": "101010103979"
  },
  {
    "strekkode": 101010106475,
    "nettovekt": 1,
    "navn": "Munn væske - Listerine ",
    "matvare": false,
    "info": " ",
    "documentID": "101010106475"
  },
  {
    "strekkode": 101010106765,
    "nettovekt": 0,
    "navn": "Pose - Brødpose",
    "matvare": false,
    "info": " ",
    "documentID": "101010106765"
  },
  {
    "strekkode": 7039010545761,
    "nettovekt": 0.2,
    "navn": "Pannekaker",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 23,
        "Mettet fett": 0.3,
        "Enumettet": 0,
        "Salt": 0.4,
        "Energi": 608,
        "Stivelse": 0,
        "Sukkerarter": 2.2,
        "Kostfiber": 5.1,
        "Kalorier": 144,
        "Fett": 1.9,
        "Protein": 6.2
      }
    },
    "documentID": "7039010545761"
  },
  {
    "strekkode": 101010101234,
    "nettovekt": 0,
    "navn": "Lisser ",
    "matvare": false,
    "info": " ",
    "documentID": "101010101234"
  },
  {
    "strekkode": 101010105065,
    "nettovekt": 30,
    "navn": "Vektskiver",
    "matvare": false,
    "info": " ",
    "documentID": "101010105065"
  },
  {
    "strekkode": 101010107021,
    "nettovekt": 0,
    "navn": "Lenovo L24e-20",
    "matvare": false,
    "info": " ",
    "documentID": "101010107021"
  },
  {
    "strekkode": 101010107625,
    "nettovekt": 0,
    "navn": "skuerskive M3",
    "matvare": false,
    "info": " ",
    "documentID": "101010107625"
  },
  {
    "strekkode": 101010104105,
    "nettovekt": 0,
    "navn": "Mutter M3",
    "matvare": false,
    "info": " ",
    "documentID": "101010104105"
  },
  {
    "strekkode": 101010105522,
    "nettovekt": 0,
    "navn": "sporskruer",
    "matvare": false,
    "info": " ",
    "documentID": "101010105522"
  },
  {
    "strekkode": 7041614004056,
    "nettovekt": 0.2,
    "navn": "BurgerBrød",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 45.2,
        "Mettet fett": 0.7,
        "Enumettet": 0,
        "Salt": 0.7,
        "Energi": 1163,
        "Stivelse": 0,
        "Sukkerarter": 3.8,
        "Kostfiber": 6.9,
        "Kalorier": 278,
        "Fett": 4.7,
        "Protein": 9.8
      }
    },
    "documentID": "7041614004056"
  },
  {
    "strekkode": 7029161121488,
    "nettovekt": 0.75,
    "navn": "Brød-Jubileums",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 2.5,
        "Karbohydrater": 35.2,
        "Mettet fett": 0.8,
        "Enumettet": 1.8,
        "Salt": 0.97,
        "Energi": 1059,
        "Stivelse": 0,
        "Sukkerarter": 2,
        "Kostfiber": 6.7,
        "Kalorier": 252,
        "Fett": 5.8,
        "Protein": 11.3
      }
    },
    "documentID": "7029161121488"
  },
  {
    "strekkode": 101010102804,
    "nettovekt": 0,
    "navn": "Brukt belte",
    "matvare": false,
    "info": " ",
    "documentID": "101010102804"
  },
  {
    "strekkode": 7045010003019,
    "nettovekt": 0.011,
    "navn": "Basilikum - Hindu",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 10,
        "Mettet fett": 2.2,
        "Enumettet": 0,
        "Salt": 0.2,
        "Energi": 1013,
        "Stivelse": 0,
        "Sukkerarter": 1.7,
        "Kostfiber": 37.7,
        "Kalorier": 244,
        "Fett": 4.1,
        "Protein": 23
      }
    },
    "documentID": "7045010003019"
  },
  {
    "strekkode": 7029161111724,
    "nettovekt": 0.75,
    "navn": "brød-BRANN",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 1.1,
        "Karbohydrater": 39.6,
        "Mettet fett": 0.4,
        "Enumettet": 1.1,
        "Salt": 1,
        "Energi": 240,
        "Stivelse": -1,
        "Sukkerarter": 1.2,
        "Kostfiber": 5.2,
        "Kalorier": 1013,
        "Fett": 3.3,
        "Protein": 10.1
      }
    },
    "documentID": "7029161111724"
  },
  {
    "strekkode": 2382664409732,
    "nettovekt": 1,
    "navn": "Ost synnøve-Gouda-1K",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 10,
        "Karbohydrater": 0.1,
        "Mettet fett": 19,
        "Enumettet": 0,
        "Salt": 1.3,
        "Energi": 1515,
        "Stivelse": 0,
        "Sukkerarter": 0.1,
        "Kostfiber": 0,
        "Kalorier": 365,
        "Fett": 29,
        "Protein": 26
      }
    },
    "documentID": "2382664409732"
  },
  {
    "strekkode": 7037421061559,
    "nettovekt": 0.3,
    "navn": "Julekaker ",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 11,
        "Karbohydrater": 67.7,
        "Mettet fett": 12.5,
        "Enumettet": 0,
        "Salt": 0.88,
        "Energi": 500,
        "Stivelse": 0,
        "Sukkerarter": 33,
        "Kostfiber": 0,
        "Kalorier": 2100,
        "Fett": 23.5,
        "Protein": 4.6
      }
    },
    "documentID": "7037421061559"
  },
  {
    "strekkode": 101010108165,
    "nettovekt": 0,
    "navn": "PoseLukker",
    "matvare": false,
    "info": " ",
    "documentID": "VGkn3RmCHcllcFn0iOqe"
  },
  {
    "strekkode": 6414300084983,
    "nettovekt": 0,
    "navn": "Tørkepapir Serla",
    "matvare": false,
    "info": " ",
    "documentID": "6414300084983"
  },
  {
    "strekkode": 7046110009239,
    "nettovekt": 0.5,
    "navn": "Jif-Kjøkken-Oven",
    "matvare": false,
    "info": " ",
    "documentID": "7046110009239"
  },
  {
    "strekkode": 7032069716076,
    "nettovekt": 0,
    "navn": "Bakepapir",
    "matvare": false,
    "info": " ",
    "documentID": "7032069716076"
  },
  {
    "strekkode": 7038010028441,
    "nettovekt": 1,
    "navn": "Brunost-Original-1kg",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 9,
        "Karbohydrater": 35,
        "Mettet fett": 19,
        "Enumettet": 0,
        "Salt": 0.7,
        "Energi": 1835,
        "Stivelse": 0,
        "Sukkerarter": 30,
        "Kostfiber": 0,
        "Kalorier": 441,
        "Fett": 28,
        "Protein": 10
      }
    },
    "documentID": "7038010028441"
  },
  {
    "strekkode": 3086121601019,
    "nettovekt": null,
    "navn": "brev-sporring",
    "matvare": false,
    "info": " ",
    "documentID": "3086121601019"
  },
  {
    "strekkode": 101010102972,
    "nettovekt": 0,
    "navn": "Penn",
    "matvare": false,
    "info": " ",
    "documentID": "ZctxD3sCjSnOtRvrRWtC"
  },
  {
    "strekkode": null,
    "nettovekt": null,
    "navn": "Såpe-Håndsåpe",
    "matvare": false,
    "info": " ",
    "documentID": "J8K1OhNZSQppLWzGI9oP"
  },
  {
    "strekkode": null,
    "nettovekt": null,
    "navn": "Barberblader",
    "matvare": false,
    "info": " ",
    "documentID": "JZ3bpZyqvDpG02nAxSCj"
  },
  {
    "strekkode": 5701390066731,
    "nettovekt": null,
    "navn": "Skål-store",
    "matvare": false,
    "info": " ",
    "documentID": "5701390066731"
  },
  {
    "strekkode": 5701390430488,
    "nettovekt": null,
    "navn": "Skål-små",
    "matvare": false,
    "info": " ",
    "documentID": "5701390430488"
  },
  {
    "strekkode": null,
    "nettovekt": null,
    "navn": "Tørkeruller",
    "matvare": false,
    "info": " ",
    "documentID": "42eQ7LRuiS2M4qiPNyYt"
  },
  {
    "strekkode": 4008321202710,
    "nettovekt": null,
    "navn": "Lyspære",
    "matvare": false,
    "info": " ",
    "documentID": "4008321202710"
  },
  {
    "strekkode": 101010102989,
    "nettovekt": 0,
    "navn": "Batteri-Klokke",
    "matvare": false,
    "info": " ",
    "documentID": "fBwxKR44XmJNvs2h91IL"
  },
  {
    "strekkode": 101010107724,
    "nettovekt": 0,
    "navn": "KjøptForAndre",
    "matvare": false,
    "info": " ",
    "documentID": "87UsRoroXvkfLQhionEg"
  },
  {
    "strekkode": 101010106895,
    "nettovekt": 0,
    "navn": "ukjent",
    "matvare": false,
    "info": " ",
    "documentID": "3PJMLKsAi7fp6oUIvwcU"
  },
  {
    "strekkode": 101010109179,
    "nettovekt": 1000,
    "navn": "Sko M/77 ",
    "matvare": false,
    "info": " ",
    "documentID": "hcYO0QLwfYiUrrXE4lnk"
  },
  {
    "strekkode": null,
    "nettovekt": null,
    "navn": "Shoe Polish ",
    "matvare": false,
    "info": " ",
    "documentID": "7VymTjOM04R4cssCnX2J"
  },
  {
    "strekkode": null,
    "nettovekt": null,
    "navn": "UniversalKult",
    "matvare": false,
    "info": " ",
    "documentID": "SwtPUMzLpFRreYnRJsio"
  },
  {
    "strekkode": 101010107960,
    "nettovekt": 0,
    "navn": "Jakke med hette",
    "matvare": false,
    "info": " ",
    "documentID": "Wnp1wDnep9gt5yaPWnbw"
  },
  {
    "strekkode": null,
    "nettovekt": null,
    "navn": "Tøyvask",
    "matvare": false,
    "info": " ",
    "documentID": "4EHpBRhZKxqMdg1jHwvB"
  },
  {
    "strekkode": 101010103863,
    "nettovekt": 0,
    "navn": "T-skjorte",
    "matvare": false,
    "info": " ",
    "documentID": "OAzaAG7Oh5HRfSWaCtGV"
  },
  {
    "strekkode": 101010108813,
    "nettovekt": 0,
    "navn": "TrådløsMus",
    "matvare": false,
    "info": " ",
    "documentID": "PblWCeeQSijUXQrgYLd9"
  },
  {
    "strekkode": null,
    "nettovekt": null,
    "navn": "Toalettrens ",
    "matvare": false,
    "info": " ",
    "documentID": "gQM2a4duq2YJvD7HeA18"
  },
  {
    "strekkode": null,
    "nettovekt": null,
    "navn": "Toalettpapir",
    "matvare": false,
    "info": " ",
    "documentID": "h7mi21cM59LmbSoppzZw"
  },
  {
    "strekkode": null,
    "nettovekt": null,
    "navn": "Tannkrem",
    "matvare": false,
    "info": " ",
    "documentID": "i7Z2fywdOpjel4HEix7e"
  },
  {
    "strekkode": null,
    "nettovekt": null,
    "navn": "Tannborste",
    "matvare": false,
    "info": " ",
    "documentID": "wyG67uYPhx4lkDpGsORP"
  },
  {
    "strekkode": null,
    "nettovekt": null,
    "navn": "SykkelSlange",
    "matvare": false,
    "info": " ",
    "documentID": "jVck6nxlijSqto1dMxls"
  },
  {
    "strekkode": 101010105331,
    "nettovekt": 0,
    "navn": "SykkelSadel",
    "matvare": false,
    "info": " ",
    "documentID": "XECfKQigOqZvibiZ9CVY"
  },
  {
    "strekkode": 101010102040,
    "nettovekt": 0,
    "navn": "Sykkelpumpa",
    "matvare": false,
    "info": " ",
    "documentID": "gZmUBQompqKKwwbd0iyK"
  },
  {
    "strekkode": 7311250013355,
    "nettovekt": null,
    "navn": "Snus General",
    "matvare": false,
    "info": " ",
    "documentID": "7311250013355"
  },
  {
    "strekkode": 7311250083976,
    "nettovekt": null,
    "navn": "Snus G4",
    "matvare": false,
    "info": " ",
    "documentID": "7311250083976"
  },
  {
    "strekkode": null,
    "nettovekt": null,
    "navn": "shoes'  Shine sponge",
    "matvare": false,
    "info": " ",
    "documentID": "ZRapwUHuS2C3jFcie9Bp"
  },
  {
    "strekkode": 7314571151003,
    "nettovekt": null,
    "navn": "Shampoo-Sport",
    "matvare": false,
    "info": " ",
    "documentID": "7314571151003"
  },
  {
    "strekkode": 101010105737,
    "nettovekt": 0,
    "navn": "RingeKlokke",
    "matvare": false,
    "info": " ",
    "documentID": "yT9Vd1G1AAc9SzErnv0u"
  },
  {
    "strekkode": 101010107335,
    "nettovekt": 0,
    "navn": "Ram + headset",
    "matvare": false,
    "info": " ",
    "documentID": "khpyaZ1bI1oJ30WVbBIS"
  },
  {
    "strekkode": 101010108462,
    "nettovekt": 0,
    "navn": "Pose",
    "matvare": false,
    "info": " ",
    "documentID": "alzmU8vv3SbAsDiaMlmr"
  },
  {
    "strekkode": 101010107052,
    "nettovekt": 0,
    "navn": "Oppvaskbørste",
    "matvare": false,
    "info": " ",
    "documentID": "Y1QIl3HTBXaSfQhhy8Wd"
  },
  {
    "strekkode": null,
    "nettovekt": null,
    "navn": "Munn væske",
    "matvare": false,
    "info": " ",
    "documentID": "uNuRgsjo8nxyfj6gDGJy"
  },
  {
    "strekkode": 101010106918,
    "nettovekt": 0,
    "navn": "Lås",
    "matvare": false,
    "info": " ",
    "documentID": "UvLKaEXyh7nGlARJJisx"
  },
  {
    "strekkode": null,
    "nettovekt": null,
    "navn": "Lynlim ",
    "matvare": false,
    "info": " ",
    "documentID": "HLyoK7UBaa8aylJUn05N"
  },
  {
    "strekkode": 101010102477,
    "nettovekt": 0,
    "navn": "Laptoplader",
    "matvare": false,
    "info": " ",
    "documentID": "gvDuuR35KXYZd5UkjmVz"
  },
  {
    "strekkode": 101010101029,
    "nettovekt": 0,
    "navn": "Konvolutt",
    "matvare": false,
    "info": " ",
    "documentID": "8bH8ZfnbTOU1AhE3e5N9"
  },
  {
    "strekkode": 101010102323,
    "nettovekt": 0,
    "navn": "Klatresko",
    "matvare": false,
    "info": " ",
    "documentID": "evHBVINEJTuPWVS0f39H"
  },
  {
    "strekkode": 101010103931,
    "nettovekt": 0,
    "navn": "Kjøkkenvekt",
    "matvare": false,
    "info": " ",
    "documentID": "TgeM0CYPN7kBQeBQl6av"
  },
  {
    "strekkode": 101010102699,
    "nettovekt": 0,
    "navn": "Kjevle",
    "matvare": false,
    "info": " ",
    "documentID": "bFXSST6dbtYAdRfcTLVR"
  },
  {
    "strekkode": null,
    "nettovekt": null,
    "navn": "Handsåpe",
    "matvare": false,
    "info": " ",
    "documentID": "47qUtl1CUHq6p73TfVQP"
  },
  {
    "strekkode": 101010105799,
    "nettovekt": 0,
    "navn": "Futballbukse",
    "matvare": false,
    "info": " ",
    "documentID": "hN8QtY5RT1mrtajUCJXW"
  },
  {
    "strekkode": 101010104785,
    "nettovekt": 0,
    "navn": "Fritak",
    "matvare": false,
    "info": " ",
    "documentID": "dzer1URthCx9XaaweH9K"
  },
  {
    "strekkode": null,
    "nettovekt": null,
    "navn": "Filterposer",
    "matvare": false,
    "info": " ",
    "documentID": "Xl1z78QoBR5E9P0hufjV"
  },
  {
    "strekkode": 101010109247,
    "nettovekt": 0,
    "navn": "Caps",
    "matvare": false,
    "info": " ",
    "documentID": "Li43iMXvpCDrjuZfObIr"
  },
  {
    "strekkode": null,
    "nettovekt": null,
    "navn": "Barber blade",
    "matvare": false,
    "info": " ",
    "documentID": "8fvqwGgaKFo8nzLPybC5"
  },
  {
    "strekkode": 7032069726600,
    "nettovekt": 0,
    "navn": "Bakeark",
    "matvare": false,
    "info": " ",
    "documentID": "ErL7PujeMYUwt6xvepLO"
  },
  {
    "strekkode": 101010101906,
    "nettovekt": 0,
    "navn": "avrunding",
    "matvare": false,
    "info": " ",
    "documentID": "ZN8EaAMkqhWx1iOYmVRc"
  },
  {
    "strekkode": 7038010045080,
    "nettovekt": 0.85,
    "navn": "Yoghurt-0,85K-vanilje",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 12,
        "Mettet fett": 2,
        "Enumettet": 0,
        "Salt": 0.1,
        "Energi": 379,
        "Stivelse": 0,
        "Sukkerarter": 12,
        "Kostfiber": 0,
        "Kalorier": 90,
        "Fett": 3,
        "Protein": 3.6
      }
    },
    "documentID": "7038010045080"
  },
  {
    "strekkode": 7038010045073,
    "nettovekt": 0.85,
    "navn": "Yoghurt-0,85K-naturell",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 5.6,
        "Mettet fett": 2.3,
        "Enumettet": 0,
        "Salt": 0.1,
        "Energi": 287,
        "Stivelse": 0,
        "Sukkerarter": 5.6,
        "Kostfiber": 0,
        "Kalorier": 69,
        "Fett": 3.4,
        "Protein": 4.1
      }
    },
    "documentID": "7038010045073"
  },
  {
    "strekkode": 7038010055676,
    "nettovekt": 0.5,
    "navn": "Yoghurt-0,5K-vanilje",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 12,
        "Mettet fett": 2,
        "Enumettet": 0,
        "Salt": 0.1,
        "Energi": 379,
        "Stivelse": 0,
        "Sukkerarter": 12,
        "Kostfiber": 0,
        "Kalorier": 90,
        "Fett": 3,
        "Protein": 3.6
      }
    },
    "documentID": "7038010055676"
  },
  {
    "strekkode": 7038010055690,
    "nettovekt": 0.5,
    "navn": "Yoghurt-0,5K-skogsbær",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 12,
        "Mettet fett": 2,
        "Enumettet": 0,
        "Salt": 0.1,
        "Energi": 381,
        "Stivelse": 0,
        "Sukkerarter": 12,
        "Kostfiber": 0,
        "Kalorier": 91,
        "Fett": 3.1,
        "Protein": 3.7
      }
    },
    "documentID": "7038010055690"
  },
  {
    "strekkode": 7038010055652,
    "nettovekt": 0.5,
    "navn": "Yoghurt-0,5K-naturell",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 5.6,
        "Mettet fett": 2.3,
        "Enumettet": 0,
        "Salt": 0.1,
        "Energi": 287,
        "Stivelse": 0,
        "Sukkerarter": 5.6,
        "Kostfiber": 0,
        "Kalorier": 69,
        "Fett": 3.4,
        "Protein": 4.1
      }
    },
    "documentID": "7038010055652"
  },
  {
    "strekkode": 7038010055683,
    "nettovekt": 0.5,
    "navn": "Yoghurt-0,5K-jordbær",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 12,
        "Mettet fett": 2,
        "Enumettet": 0,
        "Salt": 0.1,
        "Energi": 370,
        "Stivelse": 0,
        "Sukkerarter": 11,
        "Kostfiber": 0,
        "Kalorier": 88,
        "Fett": 3,
        "Protein": 3.7
      }
    },
    "documentID": "7038010055683"
  },
  {
    "strekkode": null,
    "nettovekt": 3,
    "navn": "Whey Protein-3K-Tri-Whey",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 6.6,
        "Mettet fett": 0,
        "Enumettet": 0,
        "Salt": 0,
        "Energi": 1570,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 374,
        "Fett": 4.9,
        "Protein": 76
      }
    },
    "documentID": "438tIJyY0SrNuAF845j4"
  },
  {
    "strekkode": 7032069714584,
    "nettovekt": 0.185,
    "navn": "Tunfisk i vann",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 3,
        "Mettet fett": 0,
        "Enumettet": 0,
        "Salt": 1,
        "Energi": 502,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 120,
        "Fett": 1,
        "Protein": 27
      }
    },
    "documentID": "7032069714584"
  },
  {
    "strekkode": 7032069719626,
    "nettovekt": 0.185,
    "navn": "Tunfisk i Solsikkeolje",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 3.7,
        "Karbohydrater": 0.5,
        "Mettet fett": 1,
        "Enumettet": 1.4,
        "Salt": 1,
        "Energi": 650,
        "Stivelse": 0,
        "Sukkerarter": 0.5,
        "Kostfiber": 0,
        "Kalorier": 155,
        "Fett": 6.5,
        "Protein": 24
      }
    },
    "documentID": "7032069719626"
  },
  {
    "strekkode": 7035620007637,
    "nettovekt": 0.25,
    "navn": "Tortelloni",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 1.5,
        "Karbohydrater": 40.8,
        "Mettet fett": 3.7,
        "Enumettet": 2.1,
        "Salt": 1.1,
        "Energi": 1147,
        "Stivelse": 37.5,
        "Sukkerarter": 3.3,
        "Kostfiber": 3,
        "Kalorier": 272,
        "Fett": 7.6,
        "Protein": 8.7
      }
    },
    "documentID": "7035620007637"
  },
  {
    "strekkode": 5319991692329,
    "nettovekt": 0.4,
    "navn": "Sterk saus",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 17,
        "Mettet fett": 0,
        "Enumettet": 0,
        "Salt": 0,
        "Energi": 313.65000000000003,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 75,
        "Fett": 14,
        "Protein": 2
      }
    },
    "documentID": "5319991692329"
  },
  {
    "strekkode": 7311041013519,
    "nettovekt": 1,
    "navn": "Spaghetti",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 75,
        "Mettet fett": 0.2,
        "Enumettet": 0,
        "Salt": 0.5,
        "Energi": 1546,
        "Stivelse": 72,
        "Sukkerarter": 3,
        "Kostfiber": 2.5,
        "Kalorier": 365,
        "Fett": 1.5,
        "Protein": 11.5
      }
    },
    "documentID": "7311041013519"
  },
  {
    "strekkode": 7021010001057,
    "nettovekt": 0.5,
    "navn": "Sjokoladepålegg-Nugatti",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 63,
        "Mettet fett": 3.4,
        "Enumettet": 0,
        "Salt": 0.2,
        "Energi": 2184,
        "Stivelse": 0,
        "Sukkerarter": 62,
        "Kostfiber": 0,
        "Kalorier": 522,
        "Fett": 28,
        "Protein": 4.2
      }
    },
    "documentID": "7021010001057"
  },
  {
    "strekkode": 7035620035821,
    "nettovekt": 0.4,
    "navn": "Sjokoladepålegg-FirstPrice-N",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 29.4,
        "Karbohydrater": 57.3,
        "Mettet fett": 0.8,
        "Enumettet": 0,
        "Salt": 0.1,
        "Energi": 2400,
        "Stivelse": 0,
        "Sukkerarter": 51.2,
        "Kostfiber": 1.9,
        "Kalorier": 580,
        "Fett": 37.4,
        "Protein": 1.6
      }
    },
    "documentID": "7035620035821"
  },
  {
    "strekkode": 7035620037177,
    "nettovekt": 0.4,
    "navn": "Sjokoladepålegg",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 55.1,
        "Mettet fett": 7.9,
        "Enumettet": 0,
        "Salt": 0.1,
        "Energi": 2360,
        "Stivelse": 0,
        "Sukkerarter": 53.5,
        "Kostfiber": 2.9,
        "Kalorier": 570,
        "Fett": 36.5,
        "Protein": 2.7
      }
    },
    "documentID": "7035620037177"
  },
  {
    "strekkode": 7032069722152,
    "nettovekt": 0.185,
    "navn": "Sjampinjong-prima",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 2.7,
        "Mettet fett": 0.1,
        "Enumettet": 0,
        "Salt": 0.9,
        "Energi": 140,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 2.4,
        "Kalorier": 34,
        "Fett": 0.7,
        "Protein": 2.9
      }
    },
    "documentID": "7032069722152"
  },
  {
    "strekkode": 5701027004259,
    "nettovekt": 1,
    "navn": "Salt-utenJod",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 0,
        "Mettet fett": 0,
        "Enumettet": 0,
        "Salt": 100,
        "Energi": 0,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 0,
        "Fett": 0,
        "Protein": 0
      }
    },
    "documentID": "5701027004259"
  },
  {
    "strekkode": 5701027004198,
    "nettovekt": 1,
    "navn": "Salt",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 0,
        "Mettet fett": 0,
        "Enumettet": 0,
        "Salt": 100,
        "Energi": 0,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 0,
        "Fett": 0,
        "Protein": 0
      }
    },
    "documentID": "5701027004198"
  },
  {
    "strekkode": 7038010004858,
    "nettovekt": 0.3,
    "navn": "Rømme-sete0,35",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 2.9,
        "Mettet fett": 22,
        "Enumettet": 0,
        "Salt": 0.1,
        "Energi": 1381,
        "Stivelse": 0,
        "Sukkerarter": 2.9,
        "Kostfiber": 0,
        "Kalorier": 335,
        "Fett": 35,
        "Protein": 2.2
      }
    },
    "documentID": "7038010004858"
  },
  {
    "strekkode": 7038010005459,
    "nettovekt": 0.3,
    "navn": "Rømme-lett0,18",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 3.7,
        "Mettet fett": 11,
        "Enumettet": 0,
        "Salt": 0.1,
        "Energi": 776,
        "Stivelse": 0,
        "Sukkerarter": 3.7,
        "Kostfiber": 0,
        "Kalorier": 188,
        "Fett": 18,
        "Protein": 2.8
      }
    },
    "documentID": "7038010005459"
  },
  {
    "strekkode": 7035620087301,
    "nettovekt": 0.4,
    "navn": "Reker-FirstPrice",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 0,
        "Mettet fett": 0.3,
        "Enumettet": 0,
        "Salt": 2.3,
        "Energi": 320,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 76,
        "Fett": 1.3,
        "Protein": 16
      }
    },
    "documentID": "7035620087301"
  },
  {
    "strekkode": 7035620035135,
    "nettovekt": 0.3,
    "navn": "Potetchips-FirstPrice",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 55,
        "Mettet fett": 2.7,
        "Enumettet": 0,
        "Salt": 1.4,
        "Energi": 2269,
        "Stivelse": 54.5,
        "Sukkerarter": 0.5,
        "Kostfiber": 4.4,
        "Kalorier": 554,
        "Fett": 33,
        "Protein": 4.6
      }
    },
    "documentID": "7035620035135"
  },
  {
    "strekkode": 7034284206103,
    "nettovekt": 0.18,
    "navn": "Pizzasaus-Peppes",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 9.6,
        "Mettet fett": 0,
        "Enumettet": 0,
        "Salt": 1.8,
        "Energi": 228,
        "Stivelse": 0,
        "Sukkerarter": 7.7,
        "Kostfiber": 0,
        "Kalorier": 54,
        "Fett": 0.2,
        "Protein": 2.4
      }
    },
    "documentID": "7034284206103"
  },
  {
    "strekkode": 7035620011146,
    "nettovekt": 0.18,
    "navn": "Pizzasaus-Eldorado",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 8.7,
        "Mettet fett": 0,
        "Enumettet": 0,
        "Salt": 0.2,
        "Energi": 196,
        "Stivelse": 6.3,
        "Sukkerarter": 2.4,
        "Kostfiber": 1.4,
        "Kalorier": 46,
        "Fett": 0.1,
        "Protein": 1.8
      }
    },
    "documentID": "7035620011146"
  },
  {
    "strekkode": 7020655050024,
    "nettovekt": 1,
    "navn": "Pizzamel",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0.6,
        "Karbohydrater": 69.6,
        "Mettet fett": 0.3,
        "Enumettet": 0.1,
        "Salt": 0,
        "Energi": 1433,
        "Stivelse": 0,
        "Sukkerarter": 0.8,
        "Kostfiber": 2.7,
        "Kalorier": 338,
        "Fett": 1.1,
        "Protein": 11.1
      }
    },
    "documentID": "7020655050024"
  },
  {
    "strekkode": 7020655521395,
    "nettovekt": 0.35,
    "navn": "Pizzabunn Fibra",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0.6,
        "Karbohydrater": 36.3,
        "Mettet fett": 0.4,
        "Enumettet": 0.3,
        "Salt": 0.9,
        "Energi": 862,
        "Stivelse": 0,
        "Sukkerarter": 2,
        "Kostfiber": 6.5,
        "Kalorier": 204,
        "Fett": 1.6,
        "Protein": 7.8
      }
    },
    "documentID": "7020655521395"
  },
  {
    "strekkode": 7035620004346,
    "nettovekt": 0.185,
    "navn": "Pesto rød- Eldorado",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 6.9,
        "Mettet fett": 18.3,
        "Enumettet": 0,
        "Salt": 3,
        "Energi": 1277,
        "Stivelse": 0,
        "Sukkerarter": 5.4,
        "Kostfiber": 4.8,
        "Kalorier": 309,
        "Fett": 26.9,
        "Protein": 7.4
      }
    },
    "documentID": "7035620004346"
  },
  {
    "strekkode": 7340011364306,
    "nettovekt": 0.19,
    "navn": "Pesto grønn-coop",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 4,
        "Mettet fett": 5.4,
        "Enumettet": 0,
        "Salt": 2.7,
        "Energi": 384,
        "Stivelse": 0,
        "Sukkerarter": 2.9,
        "Kostfiber": 0,
        "Kalorier": 1583,
        "Fett": 38,
        "Protein": 5.4
      }
    },
    "documentID": "7340011364306"
  },
  {
    "strekkode": 7311041029299,
    "nettovekt": 0.185,
    "navn": "Pesto grønn- Eldorado",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 3.7,
        "Mettet fett": 6.8,
        "Enumettet": 0,
        "Salt": 2.5,
        "Energi": 1719,
        "Stivelse": 1.6,
        "Sukkerarter": 2.1,
        "Kostfiber": 4,
        "Kalorier": 417,
        "Fett": 41.4,
        "Protein": 5.4
      }
    },
    "documentID": "7311041029299"
  },
  {
    "strekkode": 7032069714850,
    "nettovekt": 0.35,
    "navn": "PeanøttSmør-REMA 1000",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 19,
        "Karbohydrater": 14,
        "Mettet fett": 9,
        "Enumettet": 25,
        "Salt": 0.5,
        "Energi": 2697,
        "Stivelse": 0,
        "Sukkerarter": 4.7,
        "Kostfiber": 6.2,
        "Kalorier": 651,
        "Fett": 55,
        "Protein": 22
      }
    },
    "documentID": "7032069714850"
  },
  {
    "strekkode": 7036110008844,
    "nettovekt": 0.35,
    "navn": "PeanøttSmør-Mills",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 17,
        "Karbohydrater": 14,
        "Mettet fett": 9,
        "Enumettet": 23,
        "Salt": 0.6,
        "Energi": 2560,
        "Stivelse": 0,
        "Sukkerarter": 9,
        "Kostfiber": 8,
        "Kalorier": 620,
        "Fett": 50,
        "Protein": 24
      }
    },
    "documentID": "7036110008844"
  },
  {
    "strekkode": 7035620035678,
    "nettovekt": 0.275,
    "navn": "Peanøtter",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 16,
        "Mettet fett": 6,
        "Enumettet": 0,
        "Salt": 0.9,
        "Energi": 2517,
        "Stivelse": 10,
        "Sukkerarter": 6,
        "Kostfiber": 8,
        "Kalorier": 607,
        "Fett": 47,
        "Protein": 26
      }
    },
    "documentID": "7035620035678"
  },
  {
    "strekkode": 7034281131002,
    "nettovekt": 1,
    "navn": "Ost synnøve-1K",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 0.1,
        "Mettet fett": 17,
        "Enumettet": 0,
        "Salt": 1.3,
        "Energi": 1404,
        "Stivelse": 0,
        "Sukkerarter": 0.1,
        "Kostfiber": 0,
        "Kalorier": 338,
        "Fett": 26,
        "Protein": 26
      }
    },
    "documentID": "7034281131002"
  },
  {
    "strekkode": 7034281134003,
    "nettovekt": 0.48,
    "navn": "Ost synnøve-0,48K",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 0.1,
        "Mettet fett": 17,
        "Enumettet": 0,
        "Salt": 1.3,
        "Energi": 1404,
        "Stivelse": 0,
        "Sukkerarter": 0.1,
        "Kostfiber": 0,
        "Kalorier": 338,
        "Fett": 26,
        "Protein": 26
      }
    },
    "documentID": "7034281134003"
  },
  {
    "strekkode": 48327203421,
    "nettovekt": 0.5,
    "navn": "Olje-Oliven-Ybarra",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 0,
        "Mettet fett": 15,
        "Enumettet": 0,
        "Salt": 0,
        "Energi": 3700,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 900,
        "Fett": 100,
        "Protein": 0
      }
    },
    "documentID": "48327203421"
  },
  {
    "strekkode": 7311041019801,
    "nettovekt": 1,
    "navn": "Olje-Oliven-FirstPrice",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 9,
        "Karbohydrater": 0,
        "Mettet fett": 14,
        "Enumettet": 77,
        "Salt": 0,
        "Energi": 3700,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 900,
        "Fett": 100,
        "Protein": 0
      }
    },
    "documentID": "7311041019801"
  },
  {
    "strekkode": 7340011351825,
    "nettovekt": 0.9,
    "navn": "Oliven-0,9K-coop",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 0,
        "Mettet fett": 2.2,
        "Enumettet": 0,
        "Salt": 2,
        "Energi": 514,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 125,
        "Fett": 13,
        "Protein": 0.5
      }
    },
    "documentID": "7340011351825"
  },
  {
    "strekkode": 7311040640228,
    "nettovekt": 0.34,
    "navn": "Oliven-0,34K-sorte",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0.9,
        "Karbohydrater": 0,
        "Mettet fett": 2.2,
        "Enumettet": 9.3,
        "Salt": 2.8,
        "Energi": 537,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 3,
        "Kalorier": 131,
        "Fett": 13.6,
        "Protein": 0.5
      }
    },
    "documentID": "7311040640228"
  },
  {
    "strekkode": 7311041029350,
    "nettovekt": 0.34,
    "navn": "Oliven-0,34K-grønne",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 1.2,
        "Karbohydrater": 0,
        "Mettet fett": 2,
        "Enumettet": 8,
        "Salt": 5.7,
        "Energi": 473,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 2.6,
        "Kalorier": 115,
        "Fett": 12,
        "Protein": 1.1
      }
    },
    "documentID": "7311041029350"
  },
  {
    "strekkode": 7340011351795,
    "nettovekt": 0.235,
    "navn": "Oliven-0,34K-coop",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 0,
        "Mettet fett": 2.2,
        "Enumettet": 0,
        "Salt": 2,
        "Energi": 514,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 125,
        "Fett": 13,
        "Protein": 0.5
      }
    },
    "documentID": "7340011351795"
  },
  {
    "strekkode": 7041111124936,
    "nettovekt": 0.25,
    "navn": "NøtterTripple",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 11,
        "Karbohydrater": 22,
        "Mettet fett": 6,
        "Enumettet": 21,
        "Salt": 0.8,
        "Energi": 2426,
        "Stivelse": 0,
        "Sukkerarter": 17,
        "Kostfiber": 8,
        "Kalorier": 580,
        "Fett": 45,
        "Protein": 21
      }
    },
    "documentID": "7041111124936"
  },
  {
    "strekkode": 7311041048931,
    "nettovekt": 0.6,
    "navn": "NøtterMix",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 7.8,
        "Karbohydrater": 37.1,
        "Mettet fett": 6.3,
        "Enumettet": 18.2,
        "Salt": 0,
        "Energi": 2134,
        "Stivelse": 3.6,
        "Sukkerarter": 33.5,
        "Kostfiber": 4.3,
        "Kalorier": 512,
        "Fett": 32.3,
        "Protein": 16.1
      }
    },
    "documentID": "7311041048931"
  },
  {
    "strekkode": 7038010024375,
    "nettovekt": 1,
    "navn": "Norvegia-1K-flydig",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 0,
        "Mettet fett": 19,
        "Enumettet": 0,
        "Salt": 1.2,
        "Energi": 1535,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 370,
        "Fett": 30,
        "Protein": 25
      }
    },
    "documentID": "7038010024375"
  },
  {
    "strekkode": 2302148200006,
    "nettovekt": 1,
    "navn": "Norvegia-1K",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 0,
        "Mettet fett": 17,
        "Enumettet": 0,
        "Salt": 1.2,
        "Energi": 1458,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 351,
        "Fett": 27,
        "Protein": 27
      }
    },
    "documentID": "2302148200006"
  },
  {
    "strekkode": 7038010014604,
    "nettovekt": 0.5,
    "navn": "Norvegia-0,5K",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 0,
        "Mettet fett": 17,
        "Enumettet": 0,
        "Salt": 1.2,
        "Energi": 1458,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 351,
        "Fett": 27,
        "Protein": 27
      }
    },
    "documentID": "7038010014604"
  },
  {
    "strekkode": 7613035962965,
    "nettovekt": 0.1,
    "navn": "Nescafe-Gull",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 3.1,
        "Mettet fett": 0.1,
        "Enumettet": 0,
        "Salt": 0.25,
        "Energi": 484,
        "Stivelse": 0,
        "Sukkerarter": 3.1,
        "Kostfiber": 34.1,
        "Kalorier": 118,
        "Fett": 0.2,
        "Protein": 7.8
      }
    },
    "documentID": "7613035962965"
  },
  {
    "strekkode": 7032069715253,
    "nettovekt": 0.75,
    "navn": "MusliCrunchy-Rema1000",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 2.1,
        "Karbohydrater": 64,
        "Mettet fett": 1.3,
        "Enumettet": 8.5,
        "Salt": 0.08,
        "Energi": 1773,
        "Stivelse": 0,
        "Sukkerarter": 18,
        "Kostfiber": 12,
        "Kalorier": 422,
        "Fett": 12,
        "Protein": 8.5
      }
    },
    "documentID": "7032069715253"
  },
  {
    "strekkode": 7311041013441,
    "nettovekt": 0.75,
    "navn": "MusliCrunchy-FirstPrice",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 66.5,
        "Mettet fett": 3,
        "Enumettet": 0,
        "Salt": 0.1,
        "Energi": 1862,
        "Stivelse": 41,
        "Sukkerarter": 25.5,
        "Kostfiber": 6.7,
        "Kalorier": 443,
        "Fett": 14.1,
        "Protein": 9.2
      }
    },
    "documentID": "7311041013441"
  },
  {
    "strekkode": 7044416012564,
    "nettovekt": 1.2,
    "navn": "Mjøl-Hvete-regal",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 68,
        "Mettet fett": 0.3,
        "Enumettet": 0,
        "Salt": 0,
        "Energi": 1450,
        "Stivelse": 0,
        "Sukkerarter": 1.7,
        "Kostfiber": 3.3,
        "Kalorier": 350,
        "Fett": 2,
        "Protein": 12
      }
    },
    "documentID": "7044416012564"
  },
  {
    "strekkode": 7020650113205,
    "nettovekt": 1,
    "navn": "Mjøl-Hvete",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 1,
        "Karbohydrater": 67.9,
        "Mettet fett": 0.4,
        "Enumettet": 0.2,
        "Salt": 0,
        "Energi": 1433,
        "Stivelse": 0,
        "Sukkerarter": 2.7,
        "Kostfiber": 3.6,
        "Kalorier": 338,
        "Fett": 1.6,
        "Protein": 11.2
      }
    },
    "documentID": "7020650113205"
  },
  {
    "strekkode": 7020650711005,
    "nettovekt": 1,
    "navn": "Mjøl-Bygg",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0.5,
        "Karbohydrater": 65.1,
        "Mettet fett": 0.2,
        "Enumettet": 0.1,
        "Salt": 0,
        "Energi": 1377,
        "Stivelse": 0,
        "Sukkerarter": 0.8,
        "Kostfiber": 7.6,
        "Kalorier": 325,
        "Fett": 1.1,
        "Protein": 9.9
      }
    },
    "documentID": "7020650711005"
  },
  {
    "strekkode": 7038010000911,
    "nettovekt": 1.75,
    "navn": "Melk-stor-0,5-Tine",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 4.5,
        "Mettet fett": 0.3,
        "Enumettet": 0,
        "Salt": 0.1,
        "Energi": 155,
        "Stivelse": 0,
        "Sukkerarter": 4.5,
        "Kostfiber": 0,
        "Kalorier": 37,
        "Fett": 0.5,
        "Protein": 3.5
      }
    },
    "documentID": "7038010000911"
  },
  {
    "strekkode": 7048840081950,
    "nettovekt": 1.75,
    "navn": "Melk-stor-0,5-Q",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 4.5,
        "Mettet fett": 0.3,
        "Enumettet": 0,
        "Salt": 0.1,
        "Energi": 155,
        "Stivelse": 0,
        "Sukkerarter": 4.5,
        "Kostfiber": 0,
        "Kalorier": 37,
        "Fett": 0.5,
        "Protein": 3.5
      }
    },
    "documentID": "7048840081950"
  },
  {
    "strekkode": 7038010001918,
    "nettovekt": 1,
    "navn": "Melk-1L-0,5-Tine",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 4.5,
        "Mettet fett": 0.3,
        "Enumettet": 0,
        "Salt": 0.1,
        "Energi": 155,
        "Stivelse": 0,
        "Sukkerarter": 4.5,
        "Kostfiber": 0,
        "Kalorier": 37,
        "Fett": 0.5,
        "Protein": 3.5
      }
    },
    "documentID": "7038010001918"
  },
  {
    "strekkode": 7048840000500,
    "nettovekt": 1,
    "navn": "Melk-1L-0,5-Q",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 4.5,
        "Mettet fett": 0.3,
        "Enumettet": 0,
        "Salt": 0.1,
        "Energi": 155,
        "Stivelse": 0,
        "Sukkerarter": 4.5,
        "Kostfiber": 0,
        "Kalorier": 37,
        "Fett": 0.5,
        "Protein": 3.5
      }
    },
    "documentID": "7048840000500"
  },
  {
    "strekkode": 7340011461807,
    "nettovekt": 0.15,
    "navn": "MandlerAnglamark",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 6.2,
        "Mettet fett": 0,
        "Enumettet": 0,
        "Salt": 4.2,
        "Energi": 2654,
        "Stivelse": 0,
        "Sukkerarter": 4.4,
        "Kostfiber": 0,
        "Kalorier": 643,
        "Fett": 56,
        "Protein": 21
      }
    },
    "documentID": "7340011461807"
  },
  {
    "strekkode": 7040514501474,
    "nettovekt": 1,
    "navn": "Løk-FirstPrice",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 5.7,
        "Mettet fett": 0,
        "Enumettet": 0,
        "Salt": 0,
        "Energi": 135,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 32,
        "Fett": 0.1,
        "Protein": 1.1
      }
    },
    "documentID": "7040514501474"
  },
  {
    "strekkode": 7037421025858,
    "nettovekt": 0.22,
    "navn": "Lefsegodt-Kanel ",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 51.4,
        "Mettet fett": 7.7,
        "Enumettet": 0,
        "Salt": 1.1,
        "Energi": 1699,
        "Stivelse": 0,
        "Sukkerarter": 21.1,
        "Kostfiber": 0,
        "Kalorier": 391,
        "Fett": 23.6,
        "Protein": 4.6
      }
    },
    "documentID": "7037421025858"
  },
  {
    "strekkode": 7037421025780,
    "nettovekt": 0.22,
    "navn": "Lefsegodt ",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 49.5,
        "Mettet fett": 7.1,
        "Enumettet": 0,
        "Salt": 1,
        "Energi": 1699,
        "Stivelse": 0,
        "Sukkerarter": 0.7,
        "Kostfiber": 0,
        "Kalorier": 383,
        "Fett": 20.9,
        "Protein": 5
      }
    },
    "documentID": "7037421025780"
  },
  {
    "strekkode": 7038010000737,
    "nettovekt": 1,
    "navn": "KulturMelk",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 4,
        "Mettet fett": 2.3,
        "Enumettet": 0,
        "Salt": 0.1,
        "Energi": 254,
        "Stivelse": 0,
        "Sukkerarter": 4,
        "Kostfiber": 0,
        "Kalorier": 61,
        "Fett": 3.5,
        "Protein": 3.3
      }
    },
    "documentID": "7038010000737"
  },
  {
    "strekkode": 7311311016349,
    "nettovekt": 0.012,
    "navn": "Krydder-pizza-0,012",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 25.8,
        "Mettet fett": 2.1,
        "Enumettet": 0,
        "Salt": 0.1,
        "Energi": 1098,
        "Stivelse": 0,
        "Sukkerarter": 3.3,
        "Kostfiber": 41.3,
        "Kalorier": 265,
        "Fett": 5.6,
        "Protein": 9.9
      }
    },
    "documentID": "7311311016349"
  },
  {
    "strekkode": 7090007520765,
    "nettovekt": 0.065,
    "navn": "Krydder-pizza",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 25.8,
        "Mettet fett": 2.1,
        "Enumettet": 0,
        "Salt": 0.1,
        "Energi": 1098,
        "Stivelse": 0,
        "Sukkerarter": 3.3,
        "Kostfiber": 41.3,
        "Kalorier": 265,
        "Fett": 5.6,
        "Protein": 9.9
      }
    },
    "documentID": "7090007520765"
  },
  {
    "strekkode": 5710557161110,
    "nettovekt": 1,
    "navn": "Kjøtt-MB",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 7.3,
        "Mettet fett": 10.3,
        "Enumettet": 0,
        "Salt": 1.3,
        "Energi": 1300,
        "Stivelse": 0,
        "Sukkerarter": 1.1,
        "Kostfiber": 0,
        "Kalorier": 317,
        "Fett": 23.3,
        "Protein": 18.5
      }
    },
    "documentID": "5710557161110"
  },
  {
    "strekkode": 7040913334390,
    "nettovekt": 0.25,
    "navn": "Kaffe-0,25K",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 0,
        "Mettet fett": 0,
        "Enumettet": 0,
        "Salt": 0,
        "Energi": 5,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 2,
        "Fett": 0.1,
        "Protein": 0.3
      }
    },
    "documentID": "7040913334390"
  },
  {
    "strekkode": 7040514507650,
    "nettovekt": 0.25,
    "navn": "Hvitløk-utenFedd",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 18.6,
        "Mettet fett": 0.1,
        "Enumettet": 0,
        "Salt": 0,
        "Energi": 480,
        "Stivelse": 0,
        "Sukkerarter": 3.9,
        "Kostfiber": 1.7,
        "Kalorier": 115,
        "Fett": 0.6,
        "Protein": 7.9
      }
    },
    "documentID": "7040514507650"
  },
  {
    "strekkode": 7038080080882,
    "nettovekt": 0.06,
    "navn": "Gjær-PIZZA",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": null,
        "Karbohydrater": 42,
        "Mettet fett": 0,
        "Enumettet": null,
        "Salt": 0,
        "Energi": 1630,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 6,
        "Kalorier": 385,
        "Fett": 5,
        "Protein": 43
      }
    },
    "documentID": "7038080080882"
  },
  {
    "strekkode": 7311070347272,
    "nettovekt": 0.28,
    "navn": "Gifflar kanel (Kaker)",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 53,
        "Mettet fett": 3,
        "Enumettet": 0,
        "Salt": 0.7,
        "Energi": 1500,
        "Stivelse": 0,
        "Sukkerarter": 18,
        "Kostfiber": 0,
        "Kalorier": 370,
        "Fett": 14,
        "Protein": 7
      }
    },
    "documentID": "7311070347272"
  },
  {
    "strekkode": 7039010019767,
    "nettovekt": 0.505,
    "navn": "Frozen Pizza-GRANDIOSA",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 28,
        "Mettet fett": 5.2,
        "Enumettet": 0,
        "Salt": 0.7,
        "Energi": 1014,
        "Stivelse": 0,
        "Sukkerarter": 2.8,
        "Kostfiber": 0,
        "Kalorier": 242,
        "Fett": 8.9,
        "Protein": 12
      }
    },
    "documentID": "7039010019767"
  },
  {
    "strekkode": 7311041019757,
    "nettovekt": 0.155,
    "navn": "Formaggio",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 65.7,
        "Mettet fett": 3.1,
        "Enumettet": 0,
        "Salt": 3.7,
        "Energi": 1579,
        "Stivelse": 59.1,
        "Sukkerarter": 6.6,
        "Kostfiber": 2.9,
        "Kalorier": 374,
        "Fett": 5.7,
        "Protein": 13.4
      }
    },
    "documentID": "7311041019757"
  },
  {
    "strekkode": 7311041013557,
    "nettovekt": 0.75,
    "navn": "Fiskepinner-FirstPrice",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 19,
        "Mettet fett": 0.7,
        "Enumettet": 0,
        "Salt": 0.7,
        "Energi": 835,
        "Stivelse": 17.3,
        "Sukkerarter": 1.7,
        "Kostfiber": 1.5,
        "Kalorier": 199,
        "Fett": 8,
        "Protein": 12
      }
    },
    "documentID": "7311041013557"
  },
  {
    "strekkode": 7310500173467,
    "nettovekt": 0.75,
    "navn": "Fiskepinner-Findus-30",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 18,
        "Mettet fett": 0.7,
        "Enumettet": 0,
        "Salt": 0.8,
        "Energi": 855,
        "Stivelse": 0,
        "Sukkerarter": 0.3,
        "Kostfiber": 0.8,
        "Kalorier": 204,
        "Fett": 9.2,
        "Protein": 12
      }
    },
    "documentID": "7310500173467"
  },
  {
    "strekkode": 7035110121607,
    "nettovekt": 0.45,
    "navn": "Fiskepinner-Findus-15",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 18,
        "Mettet fett": 0.6,
        "Enumettet": 0,
        "Salt": 0.7,
        "Energi": 818,
        "Stivelse": 0,
        "Sukkerarter": 1.4,
        "Kostfiber": 1.7,
        "Kalorier": 195,
        "Fett": 7.7,
        "Protein": 12
      }
    },
    "documentID": "7035110121607"
  },
  {
    "strekkode": 7035620002342,
    "nettovekt": 0.35,
    "navn": "Egg-6",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 1.2,
        "Karbohydrater": 0.9,
        "Mettet fett": 2.9,
        "Enumettet": 4.2,
        "Salt": 0.3,
        "Energi": 582,
        "Stivelse": 0.9,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 140,
        "Fett": 9.8,
        "Protein": 12
      }
    },
    "documentID": "7035620002342"
  },
  {
    "strekkode": 7090026220592,
    "nettovekt": 1.5,
    "navn": "Egg-24",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 1.2,
        "Karbohydrater": 0.9,
        "Mettet fett": 2.9,
        "Enumettet": 4.2,
        "Salt": 0.3,
        "Energi": 582,
        "Stivelse": 0.9,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 140,
        "Fett": 9.8,
        "Protein": 12
      }
    },
    "documentID": "7090026220592"
  },
  {
    "strekkode": 7039610005849,
    "nettovekt": 1,
    "navn": "Egg-18",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 1.2,
        "Karbohydrater": 0.9,
        "Mettet fett": 2.9,
        "Enumettet": 4.2,
        "Salt": 0.3,
        "Energi": 582,
        "Stivelse": 0.9,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 140,
        "Fett": 9.8,
        "Protein": 12
      }
    },
    "documentID": "7039610005849"
  },
  {
    "strekkode": 7025110142771,
    "nettovekt": 0.75,
    "navn": "Egg-12-Solskinn",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 1.2,
        "Karbohydrater": 0.9,
        "Mettet fett": 2.9,
        "Enumettet": 4.2,
        "Salt": 0.3,
        "Energi": 582,
        "Stivelse": 0.9,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 140,
        "Fett": 9.8,
        "Protein": 12
      }
    },
    "documentID": "7025110142771"
  },
  {
    "strekkode": 7035620024221,
    "nettovekt": 0.75,
    "navn": "Egg-12-FirstPrice",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 1.2,
        "Karbohydrater": 0.9,
        "Mettet fett": 2.9,
        "Enumettet": 4.2,
        "Salt": 0.3,
        "Energi": 582,
        "Stivelse": 0.9,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 140,
        "Fett": 9.8,
        "Protein": 12
      }
    },
    "documentID": "7035620024221"
  },
  {
    "strekkode": 7039610000172,
    "nettovekt": 0.75,
    "navn": "Egg-12",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 1.2,
        "Karbohydrater": 0.9,
        "Mettet fett": 2.9,
        "Enumettet": 4.2,
        "Salt": 0.3,
        "Energi": 582,
        "Stivelse": 0.9,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 140,
        "Fett": 9.8,
        "Protein": 12
      }
    },
    "documentID": "7039610000172"
  },
  {
    "strekkode": 7050122131611,
    "nettovekt": 0.022,
    "navn": "Dipmix Garlic",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 62,
        "Mettet fett": 3.5,
        "Enumettet": 0,
        "Salt": 18,
        "Energi": 1410,
        "Stivelse": 0,
        "Sukkerarter": 44,
        "Kostfiber": 0,
        "Kalorier": 335,
        "Fett": 5.6,
        "Protein": 8.1
      }
    },
    "documentID": "7050122131611"
  },
  {
    "strekkode": 7311041013618,
    "nettovekt": 0.148,
    "navn": "Champignonskiver-0,148K",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 2.6,
        "Mettet fett": 0,
        "Enumettet": 0,
        "Salt": 0.9,
        "Energi": 88,
        "Stivelse": 2.6,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 21,
        "Fett": 0.3,
        "Protein": 1.9
      }
    },
    "documentID": "7311041013618"
  },
  {
    "strekkode": 7041111124929,
    "nettovekt": 0.28,
    "navn": "Cashewnøtter",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 10,
        "Karbohydrater": 25,
        "Mettet fett": 8,
        "Enumettet": 28,
        "Salt": 1,
        "Energi": 2474,
        "Stivelse": 0,
        "Sukkerarter": 5,
        "Kostfiber": 3,
        "Kalorier": 592,
        "Fett": 50,
        "Protein": 16
      }
    },
    "documentID": "7041111124929"
  },
  {
    "strekkode": 7020655860043,
    "nettovekt": 0.75,
    "navn": "Brød-SPLEISE",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 2.4,
        "Karbohydrater": 41.2,
        "Mettet fett": 0.6,
        "Enumettet": 0.8,
        "Salt": 0.9,
        "Energi": 1070,
        "Stivelse": 0,
        "Sukkerarter": 1.5,
        "Kostfiber": 5.8,
        "Kalorier": 254,
        "Fett": 4.5,
        "Protein": 9.3
      }
    },
    "documentID": "7020655860043"
  },
  {
    "strekkode": 7041611018124,
    "nettovekt": 0.75,
    "navn": "Brød-NORSK FJELLBRØD",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 42.5,
        "Mettet fett": 0.3,
        "Enumettet": 0,
        "Salt": 0.9,
        "Energi": 1029,
        "Stivelse": 0,
        "Sukkerarter": 0.8,
        "Kostfiber": 5.2,
        "Kalorier": 246,
        "Fett": 3.1,
        "Protein": 8.8
      }
    },
    "documentID": "7041611018124"
  },
  {
    "strekkode": 7020650444606,
    "nettovekt": 0.75,
    "navn": "Brød-Møllerens",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 2.8,
        "Karbohydrater": 38,
        "Mettet fett": 0.6,
        "Enumettet": 1.4,
        "Salt": 1.2,
        "Energi": 1083,
        "Stivelse": 0,
        "Sukkerarter": 2.3,
        "Kostfiber": 5.8,
        "Kalorier": 247,
        "Fett": 5.4,
        "Protein": 8.7
      }
    },
    "documentID": "7020650444606"
  },
  {
    "strekkode": 7029161124687,
    "nettovekt": 0.75,
    "navn": "Brød-KNEIPP-PRIMA",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0.8,
        "Karbohydrater": 40,
        "Mettet fett": 0.4,
        "Enumettet": 0.3,
        "Salt": 0.79,
        "Energi": 980,
        "Stivelse": 9,
        "Sukkerarter": 1.4,
        "Kostfiber": 7.4,
        "Kalorier": 232,
        "Fett": 1.9,
        "Protein": 10
      }
    },
    "documentID": "7029161124687"
  },
  {
    "strekkode": 7041614000867,
    "nettovekt": 0.75,
    "navn": "Brød-HVERDAGSGROVT",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 41.3,
        "Mettet fett": 0.4,
        "Enumettet": 0,
        "Salt": 1,
        "Energi": 1006,
        "Stivelse": 0,
        "Sukkerarter": 1.5,
        "Kostfiber": 5.8,
        "Kalorier": 240,
        "Fett": 3.3,
        "Protein": 8
      }
    },
    "documentID": "7041614000867"
  },
  {
    "strekkode": 7029161117139,
    "nettovekt": 0.75,
    "navn": "Brød- GRØVT&GODT",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0.6,
        "Karbohydrater": 38,
        "Mettet fett": 0.5,
        "Enumettet": 0.3,
        "Salt": 0.96,
        "Energi": 947,
        "Stivelse": 1,
        "Sukkerarter": 0,
        "Kostfiber": 5.8,
        "Kalorier": 224,
        "Fett": 1.7,
        "Protein": 11
      }
    },
    "documentID": "7029161117139"
  },
  {
    "strekkode": 7311041002544,
    "nettovekt": 0.3,
    "navn": "Baguett-Eldorado-6stk",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 43,
        "Mettet fett": 0.4,
        "Enumettet": 0.4,
        "Salt": 1,
        "Energi": 1005,
        "Stivelse": 0,
        "Sukkerarter": 4.8,
        "Kostfiber": 7,
        "Kalorier": 238,
        "Fett": 1.7,
        "Protein": 9.1
      }
    },
    "documentID": "7311041002544"
  },
  {
    "strekkode": 7038010007231,
    "nettovekt": 1,
    "navn": "appelsinjuice-Sunniva",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 9.1,
        "Mettet fett": 0,
        "Enumettet": 0,
        "Salt": 0,
        "Energi": 188,
        "Stivelse": 0,
        "Sukkerarter": 9.1,
        "Kostfiber": 0,
        "Kalorier": 44,
        "Fett": 0.2,
        "Protein": 0.7
      }
    },
    "documentID": "7038010007231"
  },
  {
    "strekkode": null,
    "nettovekt": 3,
    "navn": "Whey Protein-3K-PF",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 7.9,
        "Mettet fett": 2.2,
        "Enumettet": 0,
        "Salt": 0.3,
        "Energi": 1666,
        "Stivelse": 0,
        "Sukkerarter": 4,
        "Kostfiber": 6.3,
        "Kalorier": 392,
        "Fett": 8.1,
        "Protein": 71.8
      }
    },
    "documentID": "aytgBxgTXshE1fyushD2"
  },
  {
    "strekkode": null,
    "nettovekt": 3,
    "navn": "Whey Protein-3K-5-Phase",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 2.5,
        "Mettet fett": 0.7,
        "Enumettet": 0,
        "Salt": 0,
        "Energi": 1480,
        "Stivelse": 0,
        "Sukkerarter": 0.4,
        "Kostfiber": 1,
        "Kalorier": 352,
        "Fett": 1.6,
        "Protein": 80.5
      }
    },
    "documentID": "xBMjRZVtJ13PKO61BM8C"
  },
  {
    "strekkode": 7070646283320,
    "nettovekt": 1,
    "navn": "Whey Protein-1K-PF",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 5.9,
        "Karbohydrater": 7.9,
        "Mettet fett": 2.2,
        "Enumettet": 0,
        "Salt": 0.3,
        "Energi": 1666,
        "Stivelse": 0,
        "Sukkerarter": 4.0,
        "Kostfiber": 6.3,
        "Kalorier": 392,
        "Fett": 8.1,
        "Protein": 71.8
      }
    },
    "documentID": "gYPJMZvTE1ZMDq2uC3wc"
  },
  {
    "strekkode": null,
    "nettovekt": 1,
    "navn": "Whey Protein-1K-5-Phase",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 2.5,
        "Mettet fett": 0.7,
        "Enumettet": 0,
        "Salt": 0,
        "Energi": 1480,
        "Stivelse": 0,
        "Sukkerarter": 0.4,
        "Kostfiber": 1,
        "Kalorier": 352,
        "Fett": 1.6,
        "Protein": 80.5
      }
    },
    "documentID": "GrVVypCwWQ7GjfTDCqc1"
  },
  {
    "strekkode": 101010106949,
    "nettovekt": 1,
    "navn": "Tomater-løsvekt",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 2.5,
        "Mettet fett": 0,
        "Enumettet": 0,
        "Salt": 0,
        "Energi": 74,
        "Stivelse": 0,
        "Sukkerarter": 2.5,
        "Kostfiber": 1.5,
        "Kalorier": 18,
        "Fett": 0.2,
        "Protein": 0.7
      }
    },
    "documentID": "X0CWKFVB2YvVGWxTIvAL"
  },
  {
    "strekkode": 101010108233,
    "nettovekt": 1,
    "navn": "Sitron-løsvekt",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0.1,
        "Karbohydrater": 2.5,
        "Mettet fett": 0,
        "Enumettet": 0,
        "Salt": 0,
        "Energi": 95,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 2.8,
        "Kalorier": 23,
        "Fett": 0.3,
        "Protein": 1.1
      }
    },
    "documentID": "WOU9bpG7JHLF7T8Vm8aM"
  },
  {
    "strekkode": 101010104730,
    "nettovekt": 1,
    "navn": "poteter-løsvekt",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 17,
        "Mettet fett": 0,
        "Enumettet": 0,
        "Salt": 0,
        "Energi": 318,
        "Stivelse": 15,
        "Sukkerarter": 0.8,
        "Kostfiber": 1.7,
        "Kalorier": 76,
        "Fett": 0.1,
        "Protein": 2
      }
    },
    "documentID": "WtRG1y4kFflZpZU5Esrw"
  },
  {
    "strekkode": 101010109650,
    "nettovekt": 1,
    "navn": "Pizza-løsvekt",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 30,
        "Mettet fett": 5,
        "Enumettet": 0,
        "Salt": 2,
        "Energi": 1000,
        "Stivelse": 0,
        "Sukkerarter": 2,
        "Kostfiber": 0,
        "Kalorier": 225,
        "Fett": 10,
        "Protein": 10
      }
    },
    "documentID": "S222XFnMUBY2t5K5ppTA"
  },
  {
    "strekkode": 101010107205,
    "nettovekt": 0.12,
    "navn": "Paprika-1stk",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0.2,
        "Karbohydrater": 2.8,
        "Mettet fett": 0.1,
        "Enumettet": 0,
        "Salt": 0,
        "Energi": 88,
        "Stivelse": 0.1,
        "Sukkerarter": 0,
        "Kostfiber": 2,
        "Kalorier": 21,
        "Fett": 0.3,
        "Protein": 0.8
      }
    },
    "documentID": "C5skXrcuIoBbh1czly9n"
  },
  {
    "strekkode": 101010102019,
    "nettovekt": 1,
    "navn": "Løk-løsvekt",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 5.7,
        "Mettet fett": 0,
        "Enumettet": 0,
        "Salt": 0,
        "Energi": 135,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 32,
        "Fett": 0.1,
        "Protein": 1.1
      }
    },
    "documentID": "SJeGJDQlCAX7XmUe4q1M"
  },
  {
    "strekkode": 101010102712,
    "nettovekt": 1,
    "navn": "Lime-løsvekt",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 2,
        "Mettet fett": 0,
        "Enumettet": 0,
        "Salt": 0,
        "Energi": 70,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 3,
        "Kalorier": 17,
        "Fett": 1,
        "Protein": 1
      }
    },
    "documentID": "4KeSDukfltn25JH80ERO"
  },
  {
    "strekkode": 101010102309,
    "nettovekt": 1,
    "navn": "is-løsvekt",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 0,
        "Mettet fett": 0,
        "Enumettet": 0,
        "Salt": 0,
        "Energi": 0,
        "Stivelse": 0,
        "Sukkerarter": 0,
        "Kostfiber": 0,
        "Kalorier": 0,
        "Fett": 0,
        "Protein": 0
      }
    },
    "documentID": "QIcNxl4AMIV1VpMiJXXe"
  },
  {
    "strekkode": 101010103702,
    "nettovekt": 1,
    "navn": "Hvitløk-løsvekt",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0,
        "Karbohydrater": 18.6,
        "Mettet fett": 0.1,
        "Enumettet": 0,
        "Salt": 0,
        "Energi": 480,
        "Stivelse": 0,
        "Sukkerarter": 3.9,
        "Kostfiber": 1.7,
        "Kalorier": 115,
        "Fett": 0.6,
        "Protein": 7.9
      }
    },
    "documentID": "K0UOyr11TO0G6aTPx3hD"
  },
  {
    "strekkode": 101010107885,
    "nettovekt": 1,
    "navn": "appelsinjuice-Rema1000",
    "matvare": true,
    "info": {
      "naeringsinnhold": {
        "Flerumettet": 0.4,
        "Karbohydrater": 9.6,
        "Mettet fett": 0,
        "Enumettet": 0,
        "Salt": 0,
        "Energi": 206,
        "Stivelse": 0,
        "Sukkerarter": 9.6,
        "Kostfiber": 0,
        "Kalorier": 49,
        "Fett": 0.5,
        "Protein": 1
      }
    },
    "documentID": "GeGm5pAoi6x7QjWvmiZw"
  }
];
