
main(List<String> arguments) async {
    // mapToEntries(); //Kan brukes til å implementere "ExpansionTiles" i Flutter
}

/*************************REFACTORE****************************** */


//Kan brukes til å implementere "ExpansionTiles" i Flutter

// void mapToEntries() {
//   var _n = {
//     "ni": {
//       "energi": 0, //kj
//       "kalorier": 0, //kcal
//       "fett": {
//         "totalt": 0.0, //g
//         "mettetFett": 0.0, //g
//         "enumettetFett": 0.0, //g
//         "flerumettetFett": 0.0 //g
//       },
//       "karbohydrater": {
//         "totalt": 0.0, //g
//         "sukkerarter": 0, //g
//       },
//       "kostfiber": 0, //g
//       "protein": 0, //g
//       "salt": 0, //g
//     }
//   };

//   var list = getentriesList(_n);
//   printEntry(list[0]);
// }

// List<Entry> getentriesList(Map<dynamic, dynamic> node) {
//   List<Entry> entriesList = <Entry>[];

//   node.forEach((k, v) {
//     List<Entry> _children = [];
//     var _value = v;
//     if (v is Map) {
//       _children = getentriesList(v);
//       _value = null;
//     }

//     var entry = Entry(title: k, value: _value, children: _children);
//     entriesList.add(entry);
//   });

//   return entriesList;
// }

// class Entry {
//   Entry({this.title, this.value, this.children: const <Entry>[]});

//   final String title;
//   final dynamic value;
//   final List<Entry> children;
// }

// void printEntry(Entry e, {String s = ""}) {
//   print("$s${e.title}: ${e.value != null ? e.value : ''}");
//   e.children.forEach((ce) => printEntry(ce, s: s + "\t"));
// }