import './base.dart';
import 'package:hex/hex.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import './utils.dart';
import 'p2p.dart';
import 'pools.dart';
import './block.dart';
import 'dart:io';
import 'dart:isolate';
class TxInput extends BaseInput {
	final String txId;
	final int idx;
	TxInput(this.idx, String signature, this.txId): super(signature);
	TxInput.fromJson(Map<String, dynamic> json):idx = json['idx'],  txId = json['txId'], super(json['signature']);
	Map<String, dynamic> toJson() => {
		'idx': idx,
		'signature': signature,
		'txId': txId
	};
}
class TxOutput {
	final BigInt value;
	final String publicKey;
	TxOutput(this.value, this.publicKey);
	TxOutput.fromJson(Map<String, dynamic> json): value = BigInt.parse(json['value']), publicKey = json['publicKey'];
	Map<String, dynamic> toJson() => {
		'publicKey': publicKey,
		'value': value.toString()
	};
}
class TxToHash {
	bool stuck;
 	int nonce;
	final List<TxInput> inputs;
	final List<TxOutput> outputs;
	final String id;
	final String random;
	TxToHash(this.stuck, this.nonce, this.inputs, this.outputs):
			id = HEX.encode(
				sha512.convert(
					utf8.encode(json.encode(inputs.map((x) => x.toJson()).toList())) +
					utf8.encode(json.encode(outputs.map((x) => x.toJson()).toList()))
				).bytes
			),
		random = Utils.CreateCryptoRandomString(51);
	TxToHash.fromJson(Map<String, dynamic> json):
			stuck = json['stuck'],
			nonce = json['nonce'],
			inputs = List<TxInput>.from(json['inputs'].map((x) => TxInput.fromJson(x))),
			outputs = List<TxOutput>.from(json['outputs'].map((x) => TxOutput.fromJson(x))),
			id = json['id'],
			random = json['random'];
	Map<String, dynamic> toJson() => {
		'stuck': stuck,
		'nonce': nonce,
		'inputs': inputs.map((x) => x.toJson()).toList(),
		'outputs': outputs.map((x) => x.toJson()).toList(),
		'id': id,
		'random': random,
	};
}
class Tx {
	final String hash;
	final TxToHash txToHash;
	Tx(this.hash, this.txToHash);
	static void doHash(List<dynamic> arguments) async {
		SendPort sendPort = arguments[0];
		int zeros = arguments[1];
		TxToHash txToHash = arguments[2];
		String hash = '';
		do {
			txToHash.nonce += 1;
			hash = HEX.encode(sha256.convert(utf8.encode(json.encode(txToHash.toJson()))).bytes);
		} while(!hash.startsWith('0' * zeros));
		sendPort.send(Tx(hash, txToHash));
	}
	Map<String, dynamic> toJson() => {
			'txToHash': txToHash.toJson(),
		  'hash': hash
	};
	Tx.fromJson(Map<String, dynamic> json):
			hash = json['hash'],
			txToHash = TxToHash.fromJson(json['txToHash']);
}
