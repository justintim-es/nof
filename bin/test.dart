import 'dart:async';
import 'dart:convert';
import 'dart:io';
class Daschart extends ContentType {
  final String eschex;
  Daschart(this.eschex);
  
  static Daschart load(String base) {
    return Daschart.parse(utf8.decode(base64Url.decode(base)));
  }
}
main(List<String> args) async {
  Daschart d = Daschart('fsfsadf');
  String b = base64Url.encode(utf8.encode(d.toString()));
  Daschart l = Daschart.load(b);
  print(l.eschex);
}
