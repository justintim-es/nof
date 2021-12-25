import 'package:elliptic/elliptic.dart';
import 'package:ecdsa/ecdsa.dart';
import 'package:tuple/tuple.dart';
import './tx.dart';
import './block.dart';
import 'dart:convert';
import './utils.dart';
import 'dart:io';
import './pools.dart';


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
	static Future<String> getDefences(String gladiatorId, File file) async {
			List<String> blockHashes = [];
			List<Tx> txs = [];
			Map<String, BigInt> bids = Map();
			List<String> defences = [];
			List<Block> blocks = [];
			List<String> publicKeys = [];
			await for (var line in Utils.fischilesche(file)) {
				Block block = Block.fromJson(json.decode(line));
				if (block.toHash.gladiators.any((element) => element.id == gladiatorId)) {
					publicKeys = block.toHash.gladiators.singleWhere((element) => element.id == gladiatorId).output!.publicKeys;
				}
				blocks.add(block);
				txs.addAll(block.toHash.freeTxs);
				blockHashes.add(block.hash);
			}
			for (Tx tx in txs) {
				for (TxOutput output in tx.txToHash.outputs) {
					if (blockHashes.contains(output.publicKey)) {
							for(Tx ttxx in txs) {
								if (tx.txToHash.inputs[0].txId == ttxx.txToHash.id) {
									for (TxOutput oschout in ttxx.txToHash.outputs) {
										if (verify(
												PublicKey.fromHex(Wallet.curve, oschout.publicKey),
												utf8.encode(json.encode(oschout.toJson())),
												Signature.fromCompactHex(tx.txToHash.inputs[0].signature))) {
											if (publicKeys.contains(oschout.publicKey)) {
												if (bids[output.publicKey] == null) {
													bids[output.publicKey] = output.value;
												}
												else {
													final BigInt? prevBidValue = bids[output.publicKey];
													bids[output.publicKey] = (output.value + prevBidValue!);
												}
											}
										}
									}
								}
							}
					}
				}
			}
			for (var key in bids.keys) {
				BigInt totalBid = BigInt.parse('0');
				for(Tx tx in txs) {
						for (TxOutput output in tx.txToHash.outputs.where((element) => element.publicKey == key)) {
							totalBid += output.value;
						}
				}
				if (bids[key]! > BigInt.parse((totalBid / BigInt.two).round().toString())) {
						defences.add(blocks.singleWhere((element) => element.hash == key).toHash.defence);
				}
			}
			String oneDefence = '';
			for (String defence in defences) {
				oneDefence + defence;
			}
			return oneDefence;
	}
	static Future<List<Tuple3<int, String, TxOutput>>> unspendOutputs(bool stuck, String publicKey, File file) async {
		List<Tuple3<int, String, TxOutput>> outputs = [];
		List<TxInput> inputs = [];
		List<Tx> txs = [];
		await for (var line in Utils.fischilesche(file)) {
			Block block = Block.fromJson(json.decode(line));
			List<Tx> innerTxs = stuck ? block.toHash.stuckTxs : block.toHash.freeTxs;
			txs.addAll(innerTxs);
			for (Tx tx in innerTxs) {
				for (int i = 0; i < tx.txToHash.outputs.length; i++) {
					if (tx.txToHash.outputs[i].publicKey == publicKey) {
						outputs.add(Tuple3<int, String, TxOutput>(i, tx.txToHash.id, tx.txToHash.outputs[i]));
					}
				}
				inputs.addAll(tx.txToHash.inputs);
			}
		}
		outputs.removeWhere((oschout) => inputs.any((ischin) => ischin.txId == oschout.item2));
		return outputs;
	}
	// unit testen eentje van 7 nullen zonder opgenomen te worden en eentje van 2 nullen
	// the solution incoming txs from other nodes
	//nee want er zijn validaties die nog getyped moeten worden
	// voor ieder incomingblock worden de transacties geverifvireerd of die wel kunnen
	// en mocht je het op deze manier proberen te hacken dan is het block corrupt
		static Future<TxToHash> newTx(bool stuck, String privateKey, String to, BigInt value, File file, TxPool txPool) async {
				String publicKey = PrivateKey.fromHex(Wallet.curve, privateKey).publicKey.toString();
				List<Tuple3<int, String, TxOutput>> outputs = await Wallet.unspendOutputs(stuck, publicKey, file);
				for (Tx tx in txPool.txs.where((element) => element.txToHash.stuck == stuck)) {
						outputs.removeWhere((oschout) => tx.txToHash.inputs.any((ischin) => Utils.veschererischifyschy(publicKey, ischin.signature, oschout.item3.toJson())));
						for (int i = 0; i < tx.txToHash.outputs.length; i++) {
							if (tx.txToHash.outputs[i].publicKey == publicKey) {
								outputs.add(Tuple3<int, String, TxOutput>(i, tx.txToHash.id, tx.txToHash.outputs[i]));
							}
						}
				}
				BigInt balance = BigInt.parse('0');
				for (Tuple3<int, String, TxOutput> output in outputs) {
					balance += output.item3.value;
				}
				if (balance < (stuck ? value : (value * BigInt.two))) {
						throw("Insufficient funds");
				}
				List<TxInput> toAddInputs = [];
				List<TxOutput> toAddOutputs = [];
				BigInt toFulfill = value;
				for (Tuple3<int, String, TxOutput> output in outputs) {
					if (output.item3.value < toFulfill) {
							toAddInputs.add(TxInput(output.item1, Utils.sign(privateKey, output.item3.toJson()), output.item2));
							toAddOutputs.add(TxOutput(output.item3.value, to));
							toFulfill -= output.item3.value;
					} else if (output.item3.value > toFulfill) {
							toAddInputs.add(TxInput(output.item1, Utils.sign(privateKey, output.item3.toJson()), output.item2));
							toAddOutputs.add(TxOutput(output.item3.value - toFulfill, publicKey));
							toAddOutputs.add(TxOutput(toFulfill, to));
							break;
					} else  {
							toAddInputs.add(TxInput(output.item1, Utils.sign(privateKey, output.item3.toJson()), output.item2));
							toAddOutputs.add(TxOutput(toFulfill, to));
							 break;
					}
				}
				return TxToHash(stuck, 0, toAddInputs, toAddOutputs);
	}
}
