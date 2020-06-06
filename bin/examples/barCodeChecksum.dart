import 'dart:math';

main(List<String> arguments) async {
  int _fakeBarcodeWithLastDigitAszero = generateFakeBarcode();

  int _fakeBarcode = generateFakeBarcode();
  bool valid = isBarcodeValid(_fakeBarcode);
  print("The number $_fakeBarcode is${valid ? '' : 'n\'t'} a valid barcode ");
}

int generateRandomBetween100and999() {
  double dbl = Random().nextDouble();
  for (var i = 0; i < 4 && dbl < 100; i++) {
    dbl *= 10;
  }
  // print(dbl);
  // print(dbl.toInt() % 1000);
  return dbl.toInt();
}

num generateFakeBarcode() {
  int _rndm3Digits = generateRandomBetween100and999();
  int _fakeBarcodeWithLastDigitAszero = (10101010 * 1000 + _rndm3Digits) * 10;

  int _fakeBarcode = _fakeBarcodeWithLastDigitAszero +
      calculateThecheckDigit(_fakeBarcodeWithLastDigitAszero);

  return _fakeBarcode;
}

bool isBarcodeValid(int _barcode) {

// It's the truncating division operator. It is equevalent to int/int and taking the floor of the result i.e. floor(5/2) = 2  or  floor(7/5) = 1.

  if (_barcode is int && _barcode != -1 && _barcode > pow(10, 6)) {
    num _barcodeWithLastDigitAszero = (_barcode ~/ 10) * 10;
    num _barcodeLastDigit = _barcode - _barcodeWithLastDigitAszero;
    return _barcodeLastDigit ==
        calculateThecheckDigit(_barcodeWithLastDigitAszero);
  } else
    return false;
}

num calculateThecheckDigit(int _barcodeWithLastDigitAszero) {
  // Tested for GTIN , GSIN and SSCC

  // The algorithm to calculate a check digit manually
  //   - Create an int array with size of 18 elem.
  //   - Fill the most signi. digits of the barcode with 0. e.i. the most sig. numbers of a GTIN-12 will be six zeros.
  //   - Fill the array with the barcode digits.
  //   - Multiply each elem in the array (except the last one) with:
  // 		  - The first elem with 3, the 2nd with 1, the 3rd with 3, .. and the 17th with 3.
  //   - Add all the elements in the array together to create sum.
  //   - Subtract the sum from nearest equal or higher multiple of ten. for ex. 77 nearest equal or higher multiple of ten is 80 => 80 -77  and for 40 is 40 => 40-40
  //   - The result must be equal to the least sig. digit of the barcode.
  int numOfCells = 18;
  List<int> checkSumList = List.generate(numOfCells, (ind) {
    num exponent = numOfCells - 1 - ind;
    num digit = (_barcodeWithLastDigitAszero ~/ pow(10, exponent)) % 10;
    num n = pow(3, ((ind + 1) % 2));
    num sum = digit * n;
    print(" $digit X $n = $sum");
    return sum;
  });
  num theTotalSum = checkSumList.fold(0, (prev, element) => prev + element);

  num checkDigit = (theTotalSum / 10).ceil() * 10 - theTotalSum;
  //or
  // num checkDigit = (theTotalSum ~/ 10) * 10;
  // checkDigit = checkDigit < theTotalSum ? checkDigit + 10 : checkDigit;
  // checkDigit -= theTotalSum;

  print("TotalSum = $theTotalSum, and the last digit is $checkDigit.");
  return checkDigit;
}
