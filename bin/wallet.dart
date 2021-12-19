import 'package:ecdsa/ecdsa.dart';
import 'package:elliptic/elliptic.dart';

class Wallet {
	static final curve = getP256();
	var privateKey;
	var publicKey;
	Wallet() {
		privateKey = curve.generatePrivateKey();
		publicKey = privateKey.publicKey.toString();
		privateKey = privateKey.toString();
	}
	
	Map<String, dynamic> toJson() => {
		'privateKey': privateKey,
		'publicKey': publicKey
	};
	Wallet.fromJson(Map<String, dynamic> json): privateKey = json['privateKey'], publicKey = json['publicKey'];
}
