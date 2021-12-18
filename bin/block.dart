import './utils.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';
import 'package:hex/hex.dart';

class Input {
	final int idx;
	final String signature;
	Input(this.idx, this.signature);
}
class Output {
	final String publicKey;
	Output(this.publicKey);
}
class Input {
	final int idx;
	final String signature;
	Input(this.idx, this.signature);
}
class Output {
	final String publicKey;
	Output(this.publicKey);
}


class GladiatorInput extends Input {
	final String gladiatorId;
	GladiatorInput(int idx, String signature, this.gladiatorId): super(idx, signature);
	GladiatorInput.fromJson(Map<String, dynamic> json): gladiatorId = json['gladiatorId'], super(json['idx'], json['signature']);
	Map<String, dynamic> toJson() => {
		'idx': idx,
		'signature': signature,
		'gladiatorId': gladiatorId
	};
}
class GladiatorOutput extends Output {
	final String defence;
	GladiatorOutput(String publicKey): defence = Utils.CreateCryptoRandomString(2), super(publicKey);
	GladiatorOutput.fromJson(Map<String, dynamic> json): defence = json['defence'], super(json['publicKey']);
	Map<String, dynamic> toJson() => {
		'publicKey': publicKey,
		'defence': defence
	};
}

class Gladiator {
	final List<GladiatorInput> inputs;
	final List<GladiatorOutput> outputs;
	final String id;
	Gladiator(this.inputs, this.outputs): 
	id = HEX.encode(
		sha512.convert(
			utf8.encode(inputs.map((x) => x.toJson()).toString())
		 + utf8.encode(outputs.map((x) => x.toJson()).toString())
		 ).bytes
	);

	Gladiator.fromJson(Map<String, dynamic> json): 
	inputs = List<GladiatorInput>.from(json['inputs'].map((x) => GladiatorInput.fromJson(x))), 
	outputs = List<GladiatorOutput>.from(json['outputs'].map((x) => GladiatorOutput.fromJson(x))),
	id = json['id'];
	
	Map<String, dynamic> toJson() => {
		'inputs': inputs.map((x) => x.toJson()).toList(),
		'outputs': outputs.map((x) => x.toJson()).toList(),
		'id': id
	};
}
class TxInput extends Input {
	final String txId;
	TxInput(int idx, String signature, this.txId): super(idx, signature);
	TxInput.fromJson(Map<String, dynamic> json): txId = json['txId'], super(json['idx'], json['signature']);
	Map<String, dynamic> toJson() => {
		'txId': txId,
		'signature': signature,
		'txId': txId
	};
}
class TxOutput extends Output {
	final BigInt value;
	TxOutput(String publicKey, this.value): super(publicKey);
	TxOutput.fromJson(Map<String, dynamic> json): value = BigInt.parse(json['value']), super(json['publicKey']);
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
			utf8.encode(inputs.map((x) => x.toJson()).toString()) + 
			utf8.encode(outputs.map((x) => x.toJson()).toString())
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
	final int nonce;
	final int blockNumber;
	final int difficulty;
	final int totalDifficulty;
	final String prevHash;
	final List<Gladiator> gladiators;
	final List<Tx> refreeTxs;
	ToHash(
		this.script, 
		this.nonce, 
		this.blockNumber, 
		this.difficulty, 
		this.totalDifficulty, 
		this.prevHash, 
		this.gladiators, 
		this.refreeTxs
	);
	ToHash.fromJson(Map<String, dynamic> json): 
		script = ScriptEschex.fromJson(json['script']), 
		nonce = json['nonce'], 
		blockNumber = json['blockNumber'], 
		difficulty = json['difficulty'], 
		totalDifficulty = json['totalDifficulty'],
		prevHash = json['prevHash'],
		gladiators = List<Gladiator>.from(json['gladiators'].map((x) => Gladiator.fromJson(x))),
		refreeTxs = List<Tx>.from(json['refreeTxs'].map((x) => Tx.fromJson(x)));
	Map<String, dynamic> toJson() => {
		'script': script.name,
		'nonce': nonce,
		'blockNumber': blockNumber,
		'difficulty': difficulty,
		'totalDifficulty': totalDifficulty,
		'prevHash': prevHash,
		'gladiators': gladiators.map((x) => x.toJson()).toList(),
		'refreeTxs': refreeTxs.map((x) => x.toJson()).toList()
	};	
}

class Block {
	final ToHash toHash;
	final String hash;
	Block(this.toHash): hash = HEX.encode(sha512.convert(utf8.encode(toHash.toJson().toString())).bytes); 	

	Map<String, dynamic> toJson() => {
		'toHash': toHash.toJson(),
		'hash': hash
	};
	Block.fromJson(Map<String, dynamic> json): toHash = ToHash.fromJson(json['toHash']), hash = json['hash'];

	void save(txt) {
		var file = File(txt);
		var sink = file.openWrite();
		var jsoschon = this.toJson();
		sink.write(json.encode(jsoschon) + '\n');
		sink.close();
	}
	static int blockNumber(lines) async {
		return await lines.length;
	}	
	static int difficulty(lines) async {
		List<GladiatorInput> inputs = [];
		List<GladiatorOutput> outputs = [];
		await for (String line in lines) {
			Block block = Block.fromJson(json.decode(line));
			for(Gladiator gladiator in block.toHash.gladiators) {
			 	inputs.addAll(gladiator.inputs);
			 	outputs.addAll(gladiator.outputs);		
			}
		}
		for(GladiatorOutput output in outputs) {
			for(GladiatorInput input in inputs) {
				if (output.gladiatorId)
			}
		}
	}
}
