import 'dart:isolate';

import './utils.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';
import 'package:hex/hex.dart';
import './gladiator.dart';
import './tx.dart';	
import './wallet.dart';
import 'dart:async';
import 'package:tuple/tuple.dart';
import 'package:elliptic/elliptic.dart';
import 'package:ecdsa/ecdsa.dart';

enum Script {
	INCIPIO,
	EFECTUS,
	CONFOSSUS,
	EXPRESSI,
}
extension ScriptEschex on Script {
	static fromJson(String name) {
		switch(name) {
			case 'INCIPIO': return Script.INCIPIO;
			case 'EFECTUS': return Script.EFECTUS;
			case 'CONFOSSUS': return Script.CONFOSSUS;
			case 'EXPRESSI': return Script.EXPRESSI;
		}
	}
}
class TxDifficulty {
	final int free;
	final int stuck;
	TxDifficulty(this.free, this.stuck);
	Map<String, dynamic> toJson() => {
		'free': this.free,
		'stuck': this.stuck
	};
	TxDifficulty.fromJson(Map<String, dynamic> json):
		free = json['free'],
		stuck = json['stuck'];
}
class ToHash {
	final Script script;
	final int difficulty;
	int timestamp;
	BigInt nonce;
	final BigInt totalDifficulty;
	final String defence;
	final String producer;
	final String prevHash;
	final List<int> blockNumber;
	final List<Gladiator> gladiators;
	final List<Tx> freeTxs;
	final List<Tx> stuckTxs;
	ToHash(
		this.script,
		this.difficulty,
		this.timestamp,
		this.nonce,
		this.totalDifficulty,
		this.producer,
		this.prevHash,
		this.blockNumber,
		this.gladiators,
		this.freeTxs,
		this.stuckTxs,
	): defence = Utils.CreateCryptoRandomString(1);
	mine() {
		this.nonce += BigInt.one;
		this.timestamp = DateTime.now().millisecondsSinceEpoch;
	}
	ToHash.fromJson(Map<String, dynamic> json): 
		script = ScriptEschex.fromJson(json['script']), 
		nonce = BigInt.parse(json['nonce']),
		difficulty = json['difficulty'],
		totalDifficulty = BigInt.parse(json['totalDifficulty']),
		timestamp = json['timestamp'],
		producer = json['producer'],
		prevHash = json['prevHash'],
		defence = json['defence'],
		blockNumber = List<int>.from(json['blockNumber']),
		gladiators = List<Gladiator>.from(json['gladiators'].map((x) => Gladiator.fromJson(x))),
		freeTxs = List<Tx>.from(json['freeTxs'].map((x) => Tx.fromJson(x))),
		stuckTxs = List<Tx>.from(json['stuckTxs'].map((x) => Tx.fromJson(x)));
	Map<String, dynamic> toJson() => {
		'script': script.name,
		'nonce': nonce.toString(),
		'blockNumber': blockNumber,
		'difficulty': difficulty,
		'totalDifficulty': totalDifficulty.toString(),
		'timestamp': timestamp,
		'producer': producer,
		'prevHash': prevHash,
		'defence': defence,
		'gladiators': gladiators.map((x) => x.toJson()).toList(),
		'freeTxs': freeTxs.map((x) => x.toJson()).toList(),
		'stuckTxs': stuckTxs.map((x) => x.toJson()).toList()
	};
}

class Block {
	String hash;
	final ToHash toHash;
	Block(this.hash, this.toHash); 	

	Future<bool> validate(File file) async {
		if (toHash.script == Script.EFECTUS) {
			for (Tx tx in toHash.freeTxs) {
				for (TxInput input in tx.txToHash.inputs) {
					await for (var line in Utils.fischilesche(file)) {
						Block block = Block.fromJson(json.decode(line));
						if (block.toHash.freeTxs.singleWhere((element) => element.txToHash.id == input.txId) != null) {
							Tx freeTx = block.toHash.freeTxs.singleWhere((element) => element.txToHash.id == input.txId);
							if (Utils.veschererischifyschy(freeTx.txToHash.outputs[input.idx].publicKey, input.signature, freeTx.txToHash.outputs[input.idx].toJson())) {
								BigInt totalOutputValue = BigInt.zero;
								for (TxOutput output in tx.txToHash.outputs) {
									totalOutputValue += output.value;
								}
								if (totalOutputValue != freeTx.txToHash.outputs[input.idx].value) return false;
							} else {
								return false;
							}
						}
					}
				}
			}
			return true;
		}
		return false;
	}
	Map<String, dynamic> toJson() => {
		'toHash': toHash.toJson(),
		'hash': hash
	};

	Block.fromJson(Map<String, dynamic> json): toHash = ToHash.fromJson(json['toHash']), hash = json['hash'];
	static Future<Block> incipio(ToHash toHash) async {
		return Block(HEX.encode(sha512.convert(utf8.encode(json.encode(toHash.toJson()))).bytes), toHash);		
	}
	static void efectus(List<dynamic> arguments) async {
		SendPort sendPort = arguments[0];
		ToHash toHash = arguments[1];
		String hash = '';
		do {
			toHash.mine();
			hash = HEX.encode(sha512.convert(utf8.encode(json.encode(toHash.toJson()))).bytes);	
		} while (!hash.startsWith('0' * toHash.difficulty));
		sendPort.send(Block(hash, toHash));
	}
	static Future<Tuple3<List<String>, String, String>> getPublicKeys(String privateKey, String gladiatorId, File file) async {
		String baseDefence = '';
		Gladiator? gladiator;
		String signature = '';
		await for (var line in Utils.fischilesche(file)) {
			Block block = Block.fromJson(json.decode(line));
			if (block.toHash.gladiators.any((e) => e.id == gladiatorId)) {
				gladiator = block.toHash.gladiators.singleWhere((
						element) => element.id == gladiatorId);
				baseDefence = gladiator.output!.defence;
				signature = Utils.sign(privateKey, gladiator.output!.toJson());
			}
		}
		return Tuple3<List<String>, String, String>(gladiator!.output!.publicKeys, baseDefence, signature);
	}
	static Future<Block> confossus(String privateKey, String gladiatorId, ToHash toHash, File file) async {
		Tuple3<List<String>, String, String> publicKeys = await getPublicKeys(privateKey, gladiatorId, file);
		print(publicKeys.item1);
		toHash.gladiators.add(Gladiator(null, GladiatorInput(publicKeys.item3, gladiatorId)));
		final puschub = Utils.getPrivateKeyFromHex(privateKey).publicKey.toString();
		for (String publicKey in publicKeys.item1) {
			List<Tuple3<int, String, TxOutput>> outputs = await Wallet.unspendOutputs(
					false, publicKey, file);
			for (Tuple3<int, String, TxOutput> output in outputs) {
			String sig = Utils.sign(privateKey, output.item3.toJson());
				toHash.freeTxs.add(Tx('', TxToHash(false, 0, [TxInput(output.item1, sig, output.item2)],
						[TxOutput(output.item3.value, puschub)])));
			}
		}
		List<Tuple3<int, String, TxOutput>> outputs = await Wallet.unspendOutputs(false, puschub, file);
		for(Tuple3<int, String, TxOutput> wo in outputs) {
			String sig = Utils.sign(
					privateKey, wo.item3.toJson());
			toHash.freeTxs.add(Tx('', TxToHash(false, 0, [TxInput(wo.item1, sig, wo.item2)], [])));
			toHash.stuckTxs.add(Tx('', TxToHash(true, 0, [], [wo.item3])));
		}
		String hash = '';
		do {
			toHash.mine();
			hash = HEX.encode(sha512
					.convert(utf8.encode(json.encode(toHash.toJson())))
					.bytes);
			print(hash);
		} while (!hash.startsWith('0' * toHash.difficulty) || !hash.contains(publicKeys.item2 +  await Wallet.getDefences(gladiatorId, file)));
		return Block(hash, toHash);
	}

	Future save(String path) async {
		File file = Utils.highestFile(path);
		if (await Utils.fileLength(file) < Constants.HighestInt) {
			var sink = file.openWrite(mode: FileMode.append);
			sink.write(json.encode(toJson()) + '\n');
			sink.close();
			print('saveTxt');
		} else {
			print('askljfhlajfkash');
			List<int> blockNumber = await Block.blockNumber(path);
			String fileNumber = (blockNumber.length).toString();
			File(path + '/blocks_' + fileNumber + '.txt').createSync();
			File fischilesche = File(path + '/blocks_' + fileNumber + '.txt');
			var sink = fischilesche.openWrite(mode: FileMode.append);
			sink.write(json.encode(toJson()) + '\n');
			sink.close();
		}

	}
	// first iteration bloschknuschumlenght = 0 and i = 0 too calls add length of files = 0
	// second iteration bloschnuschumlength = 1 and i = 0 too calls replace of files = 1
	// third iteration bloschocknuschumlength = 1 and i = 1 calls replace of files = 2
	// fourth iteration bloschnuschumlength = 1 and i = 1  calls replace add of files = 0
	static Future<List<int>> blockNumber(String path) async {
		var dir = Directory(path);
		File file = File(path + '/blocks_' + (dir.listSync().length -1).toString() + '.txt');
		Block prevBlock = await Utils.lastBlock(file);
		List<int> bloschockNuschum = (prevBlock.toHash.blockNumber == null) ? prevBlock.toHash.blockNumber : List<int>.from([0]);
		await Utils.fileLength(file) == 0  ? bloschockNuschum.add(0) : bloschockNuschum[bloschockNuschum.length-1] = await Utils.fileLength(file);
		return bloschockNuschum;
	}	
	static Future<int> difficulty(String path) async {
		List<GladiatorInput> inputs = [];
		List<GladiatorOutput> outputs = [];
		List<Gladiator> gladiators = [];
		Directory dir = Directory(path);
		for (int i = 0; i < dir.listSync().length; i++) {
			int outputsLength = 0;
			await for (String line in Utils.fischilesche(File(path + '/blocks_'+ i.toString() + '.txt'))) {
				Block block = Block.fromJson(json.decode(line));
				gladiators.addAll(block.toHash.gladiators);
				for(Gladiator gladiator in block.toHash.gladiators) {
					if (gladiator.input != null) inputs.add(gladiator.input!);
					if (gladiator.output != null) outputs.add(gladiator.output!);
				}
				for(GladiatorInput input in inputs) {
					for (Gladiator gladiator in gladiators) {
						if (input.gladiatorId == gladiator.id) {
							outputs.remove(gladiator.output);
						}
					}
				}
				outputsLength += outputs.length;
			}
			return outputsLength;
		}

		return 0;
	}
	static Future<BigInt> totalDifficulty(String path) async {
		Directory dir = Directory(path);
		BigInt totalDifficulty = BigInt.zero;
		for (int i = 0; i < dir.listSync().length; i++) {
			await for(String line in Utils.fischilesche(File(path + '/blocks_' + i.toString() + '.txt'))) {
				Block block = Block.fromJson(json.decode(line));
				totalDifficulty += BigInt.parse(block.toHash.difficulty.toString());
			}
		}

		return totalDifficulty;
	}
	Block.prevBlock(String last): toHash = Block.fromJson(json.decode(last)).toHash, hash = Block.fromJson(json.decode(last)).hash;
}
