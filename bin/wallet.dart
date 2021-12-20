import 'package:elliptic/elliptic.dart';
import 'package:tuple/tuple.dart';
import './tx.dart';
import './block.dart';
import 'dart:convert';

class OutputData {
	final String txId;
	final int idx;
	OutputData(this.txId, this.idx);
}
class Wallet {
	static final curve = getP256();
	dynamic privateKey;
	String? publicKey;
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

	static Future<List<Tuple2<TxOutput, OutputData>>> refreeOutputs(String publicKey, Stream<String> txt) async {
		List<Tuple2<TxOutput, OutputData>> outputs = [];
		List<TxInput> inputs = [];
		List<Tx> txs = [];
		await for (var line in txt) {
			Block block = Block.fromJson(json.decode(line));
			txs.addAll(block.toHash.refreeTxs);
			for (Tx tx in block.toHash.refreeTxs) {
					outputs.addAll(tx.outputs.where((element) => element.publicKey == publicKey).map((e) => Tuple2<TxOutput, OutputData>(e, OutputData(tx.id, e))));
					inputs.addAll(tx.inputs);
			}
		}
		for(TxInput input in inputs) {
				Tx tx = txs.firstWhere((tx) => tx.id == input.txId);
				if (outputs.where((element) => element.item2 == tx.id).isNotEmpty) {
						outputs.remove(Tuple2<TxOutput, String>(tx.outputs[input.idx], tx.id));
				}
		}
		return outputs;
	}
	static Future<Tx> newTx(String privateKey, String to, BigInt value, Stream<String> txt) async {
				String publicKey = PrivateKey.fromHex(Wallet.curve, privateKey).publicKey.toString();
				List<Tuple2<TxOutput, String>> outputs = await Wallet.refreeOutputs(publicKey, txt);
				BigInt balance = BigInt.parse('0');
				for (Tuple2<TxOutput, String> output in outputs) {
					balance += output.item1.value;
				}
				if (balance < value) {
						throw("Insufficient funds");
				}
				List<TxInput> inputs = [];
				List<TxOutput> outputs = [];
				BigInt toFulfill = value;
				for (Tuple2<TxOutput, String> output in outputs) {
					if (output.item1.value < toFulfill) {
							inputs.add(TxInput())
					}
				}
	}
}
