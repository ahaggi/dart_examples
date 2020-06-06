import 'dart:math';
import 'dart:collection';

main(List<String> arguments) async {
  int nrOfSuggestions = 10;
  List<String> text = [
    "appelsinjuice-Rema1000",
    "Hvitløk-løsvekt",
    "is",
    "Lime-løsvekt",
    "Løk-løsvekt",
    "Paprika-løsvekt",
    "Pizza",
    "poteter-løsvekt",
    "Sitron-løsvekt",
    "Tomater-løsvekt",
    "Whey Protein-1K-5-Phase",
    "Whey Protein-1K-PF",
    "Whey Protein-3K-5-Phase",
    "Whey Protein-3K-PF",
    "appelsinjuice-Sunniva",
    "Baguett-Eldorado-6stk",
    "Brød- GRØVT&GODT",
    "Brød-HVERDAGSGROVT",
    "Brød-KNEIPP-PRIMA",
    "Brød-Møllerens",
    "Brød-NORSK FJELLBRØD",
    "Brød-SPLEISE",
    "BurgerBrød",
    "Cashewnøtter",
    "Champignonskiver-0,148K",
    "Dipmix",
    "Egg-12",
    "Egg-12-FirstPrice",
    "Egg-12-Solskinn",
    "Egg-18",
    "Egg-24",
    "Egg-6",
    "Fiskepinner-Findus-15",
    "Fiskepinner-Findus-30",
    "Fiskepinner-FirstPrice",
    "Formaggio",
    "Frozen Pizza-GRANDIOSA",
    "Gifflar kanel (Kaker)",
    "Gjær-PIZZA",
    "Hvitløk-utenFedd",
    "Kaffe-0,25K",
    "Kjøtt-MB",
    "Krydder-pizza",
    "Krydder-pizza-0,012",
    "KulturMelk",
    "Lefsegodt",
    "Lefsegodt-Kanel",
    "Løk-FirstPrice",
    "MandlerAnglamark",
    "Melk-1L-0,5-Q",
    "Melk-1L-0,5-Tine",
    "Melk-stor-0,5-Q",
    "Melk-stor-0,5-Tine",
    "Mjøl-Bygg",
    "Mjøl-Hvete",
    "Mjøl-Hvete-regal",
    "MusliCrunchy-FirstPrice",
    "MusliCrunchy-Rema1000",
    "Nescafe-Gull",
    "Norvegia-0,5K",
    "Norvegia-1K",
    "Norvegia-1K-flydig",
    "NøtterMix",
    "NøtterTripple",
    "Oliven-0,34K-coop",
    "Oliven-0,34K-grønne",
    "Oliven-0,34K-sorte",
    "Oliven-0,9K-coop",
    "Olje-Oliven-FirstPrice",
    "Olje-Oliven-Ybarra",
    "Ost synnøve-0,48K",
    "Ost synnøve-1K",
    "Peanøtter",
    "PeanøttSmør-Mills",
    "PeanøttSmør-REMA 1000",
    "Pesto grønn- Eldorado",
    "Pesto grønn-coop",
    "Pesto rød- Eldorado",
    "Pizzabunn Fibra",
    "Pizzamel",
    "Pizzasaus-Eldorado",
    "Pizzasaus-Peppes",
    "Potetchips-FirstPrice",
    "Reker-FirstPrice",
    "Rømme-lett0,18",
    "Rømme-sete0,35",
    "Salt",
    "Salt-utenJod",
    "Sjampinjong-prima",
    "Sjokoladepålegg",
    "Sjokoladepålegg-FirstPrice-N",
    "Sjokoladepålegg-Nugatti",
    "Spaghetti",
    "Sterk saus",
    "Tortelloni",
    "Tunfisk i Solsikkeolje",
    "Tunfisk i vann",
    "Whey Protein-1K-Tri-Whey",
    "Whey Protein-3K-Tri-Whey",
    "Yoghurt-0,5K-jordbær",
    "Yoghurt-0,5K-naturell",
    "Yoghurt-0,5K-skogsbær",
    "Yoghurt-0,5K-vanilje",
    "Yoghurt-0,85K-naturell",
    "Yoghurt-0,85K-vanilje"
  ];
  // "Vestibulum consectetur placerat leo , euismod vulputate nisi congue eget. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Nam id neque euismod, tincidunt dui in, hendrerit eros. Sed iaculis nibh vitae nibh sodales tincidunt. Morbi sodales sit amet eros ac ultrices. Morbi maximus sollicitudin metus at auctor. Sed malesuada maximus efficitur. Mauris commodo ante non purus faucibus, quis blandit erat euismod. Cras dignissim nunc et aliquam accumsan. Etiam sed fermentum erat. Nulla facilisi"
  //     .replaceAll(RegExp(r"[.,]"), "")
  //     .split(RegExp(r"[ ]"));

  String input = "brød";
  Map<String, int> allDistanceCosts = Map<String, int>();

  Stopwatch perf = new Stopwatch();
  perf.start();

  text.forEach((t) {
    allDistanceCosts[t] =
        calcWithTabulationDP(input.toLowerCase(), t.toLowerCase());
  });



  print("The costs are calculated in ${perf.elapsedMilliseconds}ms");


  allDistanceCosts.removeWhere((k, v) => v > COSTTRESHOLD);

  List<String> res = allDistanceCosts.keys.toList();

  res.sort(
      (elm1, elm2) => allDistanceCosts[elm1].compareTo(allDistanceCosts[elm2]));

  res.sublist(0, nrOfSuggestions < res.length ? nrOfSuggestions : res.length);
  res.forEach((elm) => print("$elm  ${allDistanceCosts[elm]}"));

  print("The whole proc is done in ${perf.elapsedMilliseconds}ms");

  perf.stop();
  
}

//TODO assign diffrent cost for each operation
num INSERTION_COST = 0;
num DELETION_COST = 1;
num SUBSTITUTION_COST = 2;
num COSTTRESHOLD = 1;

int calcDistanceRec(String x, String y) {
  // OBS "worst case" time complixity may end up doing O(3^m) operations, where m is min(str1.length , str2.length).  
  // The worst case happens when none of characters of two strings match.

  // This could be inhanced using dp memoization/tabulation


  // When one of the Strings is empty, then the edit distance between them is the length of the other String
  // Becuase the cost of:
  //          - if x isEmpty inserting rest of y charecters in x, is 1 for each char in y
  //          - if y isEmpty deleting  rest of x charecters,      is 1 for each char in x
  if (x.isEmpty) return y.length;

  if (y.isEmpty) return x.length;

  var char1 = x.substring(0, 1);
  var char2 = y.substring(0, 1);

  int substitutionCost = calcDistanceRec(x.substring(1), y.substring(1)) +
      costOfSubstitution(char1: char1, char2: char2);
  int insertionCost =
      calcDistanceRec(x, y.substring(1)) + 1; //insert next char from y in x
  int deletionCost =
      calcDistanceRec(x.substring(1), y) + 1; //delete currnet char from  x

  return [substitutionCost, insertionCost, deletionCost].reduce(min);
}

int costOfSubstitution({String char1, String char2}) {
  assert(char1.length == 1);
  assert(char2.length == 1);
  return char1 == char2 ? 0 : SUBSTITUTION_COST;
}


/************************************************************************************** */
/*************************************ALternativly************************************* */
/************************************************************************************** */

int calcWithTabulationDP(String str1, String str2) {
  List<List<int>> dp = List.generate(str1.length + 1, (int ndx) {
    return List<int>(str2.length + 1);
  });
  print("$str1 , $str2");


  for (int i = 0; i <= str1.length; i++) {
    for (int j = 0; j <= str2.length; j++) {

  //-------------------
  // When one of the Strings is empty, then the edit distance between them is the length of the other String
  // Becuase the cost of:
  //          - if x isEmpty inserting rest of y charecters in x, is 1 for each char in y
  //          - if y isEmpty deleting  rest of x charecters,      is 1 for each char in x

      if (i == 0) {
        dp[i][j] = j;
      } else if (j == 0) {
        dp[i][j] = i;
  //-------------------
      } else {
        var char1 = str1.substring(i - 1, i);
        var char2 = str2.substring(j - 1, j);

        dp[i][j] = [
          dp[i - 1][j - 1] + costOfSubstitution(char1: char1, char2: char2),
          dp[i - 1][j] + DELETION_COST, //cost of deleting a char from x
          dp[i][j - 1] + INSERTION_COST //cost of inserting a char in x from y
        ].reduce(min);
      }
    }
    print("${dp[i]}");
  }
  // List<int> t = List.generate(x.length + 1, (ind) {
  //   return dp[ind].reduce(min);
  // });

  return dp[str1.length][str2.length];
}
