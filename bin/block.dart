import './utils.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';
import 'package:hex/hex.dart';
import './gladiator.dart';
import './tx.dart';	
import './wallet.dart';
import 'package:pedantic/pedantic.dart';
import 'package:channel/channel.dart';
import 'package:async_task/async_task.dart';

enum Script {
	INCIPIO,
	PRODUCED,
	STABBED,
	REPRODUCED
}
extension ScriptEschex on Script {
	static fromJson(String name) {
		print(name);
		switch(name) {
			case 'INCIPIO': return Script.INCIPIO;
			case 'PRODUCED': return Script.PRODUCED;
			case 'STABBED': return Script.STABBED;
			case 'REPRODUCED': return Script.REPRODUCED;
		}
	}
}
class ToHash {
	final Script script;
	int nonce;
	final int blockNumber;
	final int difficulty;
	final int totalDifficulty;
	int timestamp;
	final String prevHash;
	final List<Gladiator> gladiators;
	final List<Tx> refreeTxs;
	final Wallet wallet;
	ToHash(
		this.script, 
		this.nonce, 
		this.blockNumber, 
		this.difficulty, 
		this.totalDifficulty,
		this.timestamp, 
		this.prevHash, 
		this.gladiators, 
		this.refreeTxs
	): wallet = Wallet();
	mine() {
		this.nonce += 1;
		this.timestamp = DateTime.now().millisecondsSinceEpoch;
	}
	ToHash.fromJson(Map<String, dynamic> json): 
		script = ScriptEschex.fromJson(json['script']), 
		nonce = json['nonce'], 
		blockNumber = json['blockNumber'], 
		difficulty = json['difficulty'], 
		totalDifficulty = json['totalDifficulty'],
		timestamp = json['timestamp'],
		prevHash = json['prevHash'],
		wallet =  Wallet.fromJson(json['wallet']),
		gladiators = List<Gladiator>.from(json['gladiators'].map((x) => Gladiator.fromJson(x))),
		refreeTxs = List<Tx>.from(json['refreeTxs'].map((x) => Tx.fromJson(x)));
	Map<String, dynamic> toJson() => {
		'script': script.name,
		'nonce': nonce,
		'blockNumber': blockNumber,
		'difficulty': difficulty,
		'totalDifficulty': totalDifficulty,
		'timestamp': timestamp,
		'prevHash': prevHash,
		'wallet': wallet.toJson(),
		'gladiators': gladiators.map((x) => x.toJson()).toList(),
		'refreeTxs': refreeTxs.map((x) => x.toJson()).toList()
	};	
}

class Block {
	final ToHash toHash;
	String hash;
	Block(this.toHash): hash = HEX.encode(sha512.convert(utf8.encode(json.encode(toHash.toJson()))).bytes); 	

	Map<String, dynamic> toJson() => {
		'toHash': toHash.toJson(),
		'hash': hash
	};

	Block.fromJson(Map<String, dynamic> json): toHash = ToHash.fromJson(json['toHash']), hash = json['hash'];
	Block.mined(this.hash, this.toHash);
	static Function efectus(fileName, toHash) {
		void efec() async {
			String hash = '';
			do {
				toHash.mine();
				hash = HEX.encode(sha512.convert(utf8.encode(json.encode(toHash.toJson()))).bytes);	
			} while (!hash.startsWith('0' * toHash.difficulty));
			Block bloschock = Block.mined(hash, toHash);
			File file = File(fileName);
			await file.writeAsString(json.encode(bloschock.toJson()) + '\n', mode: FileMode.append);	
		}
		return efec;
	
	}
	void save(File file) {
		var sink = file.openWrite(mode: FileMode.append);
		sink.write(json.encode(this.toJson()) + '\n');
		sink.close();
	}
	static Future<int> blockNumber(Stream<String> lines) async {
		return await lines.length;
	}	
	static Future<int> difficulty(Stream<String> lines) async {
		List<GladiatorInput> inputs = [];
		List<GladiatorOutput> outputs = [];
		List<Gladiator> gladiators = [];
		await for (String line in lines) {
			Block block = Block.fromJson(json.decode(line));
			gladiators.addAll(block.toHash.gladiators);
			for(Gladiator gladiator in block.toHash.gladiators) {
			 	inputs.addAll(gladiator.inputs);
			 	outputs.add(gladiator.output);		
			}
			for(GladiatorInput input in inputs) {
				for (Gladiator gladiator in gladiators) {				
					if (input.gladiatorId == gladiator.id) {
						outputs.remove(gladiator.output);
					}
				}
			}
			return outputs.length;
		}
		return 0;
	}
	static Future<int> totalDifficulty(Stream<String> lines) async {
		int totalDifficulty = 0;
		await for(String line in lines) {
			Block block = Block.fromJson(json.decode(line));
			totalDifficulty += block.toHash.difficulty;
		}
		return totalDifficulty;
	}
	Block.prevBlock(String last): toHash = Block.fromJson(json.decode(last)).toHash, hash = Block.fromJson(json.decode(last)).hash;
}
