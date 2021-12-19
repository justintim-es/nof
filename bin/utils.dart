import 'dart:math';
import 'dart:convert';
import 'package:hex/hex.dart';
class Utils {
	static final Random _random = Random.secure();

	static String CreateCryptoRandomString([int length = 32]) {
		var values = List<int>.generate(length, (i) => _random.nextInt(256));
		return HEX.encode(values);
	}
	static List<int> HexToListOfInt(String hex) {
		 return List<int>.generate(hex.length ~/ 2, (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16));
	}
}
