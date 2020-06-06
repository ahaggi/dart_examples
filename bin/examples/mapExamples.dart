main(List<String> arguments) async {
  removeWhere();

/******************************************* */
  // nestedMap_TypeProblem();

/******************************************* */

// var orderedMap = SplayTreeMap<String, dynamic>.from( naeringsinnhold, (a, b) => a.compareTo(b));

/******************************************* */
// var someMap={"x": "somevalue"};
//(someMap ?? {})["x"] != null ? someMap["x"] : ""
}

void removeWhere() {
  Map varerState = new Map();
  varerState.addAll({"1": 1});
  varerState.addAll({"5": 1});
  varerState.addAll({"6": 1});

  Map txtCtrlMap = new Map();
  txtCtrlMap.addAll({"1": 1});
  txtCtrlMap.addAll({"2totalPris": 1});
  txtCtrlMap.addAll({"2pris": 1});
  txtCtrlMap.addAll({"3pris": 1});
  txtCtrlMap.addAll({"3totalPris": 1});
  txtCtrlMap.addAll({"4pris": 1});
  txtCtrlMap.addAll({"5": 1});
  txtCtrlMap.addAll({"6pris": 1});
  txtCtrlMap.addAll({"6totalPris": 1});

  txtCtrlMap.removeWhere((k, v) {
    if (!k.toLowerCase().contains("pris")) return false;

    int p = k.indexOf("totalPris");
    p = p == -1 ? k.indexOf("pris") : p;

    String vID = k.substring(0, p);

    return !varerState.containsKey(vID);
  });
  print(txtCtrlMap);
}










void nestedMap_TypeProblem() {
  Map<String, dynamic> noe = {
    "x": null,
    "y": {"yy": null},
    "z": {
      "zz": {"zzz": null}
    }
  };

  // Map<String, dynamic> noe = {
  //   "x": null,
  //   "y": Map<String, dynamic>()..addAll({"yy": null}),
  //   "z": {
  //     "zz": Map<String, dynamic>()..addAll({"zzz": null})
  //   }
  // };

  var _x_value;
  var _y_value;
  var _z_value;

  noe["x"] = "xValue";
  _x_value = noe["x"]; //OK

  try {
    noe["y"]["yy"] =
        "yValue"; //type 'String' is not a subtype of type 'Null' of 'value'
    _y_value = noe["y"]["yy"];
  } catch (e) {
    _y_value = '_y_value = ${e.message}';
  }

  try {
    noe["z"]["zz"]["zzz"] =
        "zValue"; //type 'String' is not a subtype of type 'Null' of 'value'
    _z_value = noe["z"]["zz"]["zzz"];
  } catch (e) {
    _z_value = '_z_value = ${e.message}';
  }

  print(_x_value);
  print(_y_value);
  print(_z_value);
}
