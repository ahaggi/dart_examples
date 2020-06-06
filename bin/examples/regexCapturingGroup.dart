main(List<String> arguments) async {
  // regexCapturingGroupInDartExample();
  regexCapturingGroupInDartExample2();
}

void regexCasesensitive() {
  print('Dartisans'.indexOf(new RegExp(r'aRT', caseSensitive: false))); // -1
}

void regexCapturingGroupInDartExample() {
  // se  https://stackoverflow.com/a/3513858

  RegExp exp = new RegExp(r"(https?|ftp)://([^/\r\n]+)(/[^\r\n]*)?",
      caseSensitive: false); //trim the spaces in the first group of each match
  String str =
      "ftp://stackoverflow.com/questions/tagged/regex https://stackoverflow2.com/questions2/tagged2/regex2";

  var m = exp.firstMatch(str);
  print(
      "************     Extract all the  groups from The FIRST matched    ************");
  print(
      "******The FIRST matched  is ftp://stackoverflow.com/questions/tagged/regex ********\n");

  for (int i = 0; i <= m.groupCount; i++) {
    print(m.group(i));
  }

  print("\n");
  print("****************   This will give the same result   ****************");
  print(
      "****************        OBS m[i] = m.group[i]       ****************\n");

  print(m[0]); //ftp://stackoverflow.com/questions/tagged/regex
  print(m[1]); //ftp
  print(m[2]); //stackoverflow.com
  print(m[3]);

  ///questions/tagged/regex

  print("\n");

  print("**************************************************************");
  print("**************************************************************");

  Iterable<Match> matches = exp.allMatches(str);
  for (Match m in matches) {
    print(
        '\n\n*********Starting printing all the groups in "a match"***********');

    for (int i = 0; i <= m.groupCount; i++) {
      print(m.group(i));
    }

    print("********************");
  }
}

void regexCapturingGroupInDartExample2() {
  RegExp exp = new RegExp(r"(\w* ?\w*) (\d+,?\d*) ([kj|kcal|g]*){1}");
  String str =
      "Energi 188 kj Kalorier 44 kcal   Fett 0,22  Mettet fett 0 g Karbohydrater 9,1 g Sukkerarter 9,1 g Protein 0,7 g Salt 0 mg";

  Map<String, dynamic> info = Map<String, dynamic>()
    ..addAll({
      "energi": 0,
      "kalorier": 0,
      "fett": Map<String, dynamic>()
        ..addAll({
          "enumettetFett": 0,
          "flerumettetFett": 0,
          "mettetFett": 0,
          "totalt": 0
        }),
      "karbohydrater": Map<String, dynamic>()
        ..addAll({"stivelse": 0, "sukkerarter": 0, "totalt": 0}),
      "kostfiber": 0,
      "protein": 0,
      "salt": 0
    });

  Map<String, dynamic> scannedInfo = {};
  Iterable<Match> matches = exp.allMatches(str);
  for (Match m in matches) {
    //TODO finn bedre løsning med lookbehind
    if (m.group(3).isEmpty)
      continue; // for å se bort fra næringsinnholder som ikke har (kcal , kj eller g) benevninger. for eks   Salt 0 mg

    String key = m.group(1).toLowerCase(); //TODO trim the whitespace from "key"

    // karbohydrater   1
    scannedInfo[key] = m.group(2);
    print(
        '\n\n********* Starting printing all the groups in "a match" ***********');

    // m.group(i) Returns the string matched by the given group.  If group is 0, returns the match of the pattern.

    for (int i = 0; i <= m.groupCount; i++) {
      print(m.group(i) + "   $i");
    }

    print("********************");
  }
  info.forEach((k, v) {
    if (v is Map)
      v.forEach((k2, v2) {
        if (k2 == "totalt")
          info[k][k2] = scannedInfo[k];
        else
          info[k][k2] = scannedInfo[k2];
      });
    else {
      info[k] = scannedInfo[k];
    }
  });

  print("\n\n\n");
  print(info);
}

// naeringsinnhold.forEach((k, v) {
//   String k1 = k;
//   if (scannedInfo[k] == null) {
//     k1 =
//         scannedInfo.keys.firstWhere((str) => str.startsWith(k), orElse: () {
//       scannedInfo[k1] = naeringsinnhold[k];
//       return k;
//     });
//   }
//   naeringsinnhold[k] = scannedInfo[k1];
// });
