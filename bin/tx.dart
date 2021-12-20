~import './base.dart';
import 'package:hex/hex.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
class TxInput extends BaseInput {
	final String txId;
	TxInput(int idx, String signature, this.txId): super(idx, signature);
	TxInput.fromJson(Map<String, dynamic> json): txId = json['txId'], super(json['idx'], json['signature']);
	Map<String, dynamic> toJson() => {
		'txId': txId,
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
class Tx {
	final List<TxInput> inputs;
	final List<TxOutput> outputs;
	final String id;
	Tx(this.inputs, this.outputs): 
	id = HEX.encode(
		sha512.convert(
			utf8.encode(json.encode(inputs.map((x) => x.toJson()).toList())) + 
			utf8.encode(json.encode(outputs.map((x) => x.toJson()).toList()))
		).bytes
	);
	Tx.fromJson(Map<String, dynamic> json): 
	inputs = List<TxInput>.from(json['inputs'].map((x) => TxInput.fromJson(x))), 
	outputs = List<TxOutput>.from(json['outputs'].map((x) => TxOutput.fromJson(x))), 
	id = json['id'];
	Map<String, dynamic> toJson() => {
		'inputs': inputs.map((x) => x.toJson()).toList(),
		'outputs': outputs.map((x) => x.toJson()).toList(),
		'id': id
	};

}
