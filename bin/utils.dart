import 'dart:math';
import 'dart:convert';
import 'package:hex/hex.dart';
import 'package:ecdsa/ecdsa.dart';
import './wallet.dart';
import 'package:elliptic/elliptic.dart';
import 'dart:io';
import 'package:tuple/tuple.dart';
import './tx.dart';
import './block.dart';

class Constants {
	static int MaxTx = 2;
	static int HighestInt = 2;
}

class Utils {
	static final Random _random = Random.secure();

	static String CreateCryptoRandomString([int length = 32]) {
		var values = List<int>.generate(length, (i) => _random.nextInt(256));
		return HEX.encode(values);
	}
	static List<int> HexToListOfInt(String hex) {
		 return List<int>.generate(hex.length ~/ 2, (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16));
	}
	static String sign(String privateKey, Map<String, dynamic> output) {
		return signature(PrivateKey.fromHex(Wallet.curve, privateKey), utf8.encode(json.encode(output))).toCompactHex();
	}
	static bool veschererischifyschy(String publicKey, String signature, Map<String, dynamic> output) {
		return verify(PublicKey.fromHex(Wallet.curve, publicKey), utf8.encode(json.encode(output)), Signature.fromCompactHex(signature));
	}
	static BigInt BlockReward = BigInt.parse('10000000000000000000000000');

	static PrivateKey getPrivateKeyFromHex(privateKey) => PrivateKey.fromHex(Wallet.curve, privateKey);
	static Stream<String> fischilesche(File file) => file.openRead().transform(utf8.decoder).transform(LineSplitter());

	static Tuple2<List<Tx>, List<Tx>> pickTxs(List<Tx> txs) {
		List<Tx> freeTxs = [];
		List<Tx> stuckTxs = [];
		for (int i = 64; i != 0; i--) {
				if (freeTxs.length < Constants.MaxTx) freeTxs.addAll(txs.where((element) => !element.txToHash.stuck && element.hash.startsWith('0' * i)));
				if (stuckTxs.length < Constants.MaxTx) stuckTxs.addAll(txs.where((element) => element.txToHash.stuck && element.hash.startsWith('0' * i)));
		}
		return Tuple2<List<Tx>, List<Tx>>(freeTxs, stuckTxs);
	}
	static Future<Block> lastBlock(File file) async => Block.fromJson(json.decode(await Utils.fischilesche(file).last));
	static Future<Block> getBlock(List<int> blockNumber, File file) async => Block.fromJson(json.decode(await Utils.fischilesche(file).elementAt(blockNumber[blockNumber.length-1])));
	static Future<int> fileLength(File file)  async =>  await Utils.fischilesche(file).length;
	static File highestFile(String path) => File(path + '/blocks_' + (Directory(path).listSync().length-1).toString() + '.txt');
}
