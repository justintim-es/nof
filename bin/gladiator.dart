import './base.dart';
import 'package:hex/hex.dart';
import 'dart:convert';
import './utils.dart';
import 'package:crypto/crypto.dart';
class GladiatorInput extends BaseInput {
	final String gladiatorId;
	GladiatorInput(int idx, String signature, this.gladiatorId): super(idx, signature);
	GladiatorInput.fromJson(Map<String, dynamic> json): gladiatorId = json['gladiatorId'], super(json['idx'], json['signature']);
	Map<String, dynamic> toJson() => {
		'idx': idx,
		'signature': signature,
		'gladiatorId': gladiatorId
	};
}
class GladiatorOutput {
	final List<String> publicKeys;
	final String defence;
	GladiatorOutput(this.publicKeys): defence = Utils.CreateCryptoRandomString(2);
	GladiatorOutput.fromJson(Map<String, dynamic> json): defence = json['defence'], publicKeys = List<String>.from(json['publicKeys']);
	Map<String, dynamic> toJson() => {
		'publicKeys': publicKeys,
		'defence': defence
	};
}

class Gladiator {
	final GladiatorOutput output;
	final List<GladiatorInput> inputs;
	final String id;
	Gladiator(this.output, this.inputs): 
	id = HEX.encode(
		sha512.convert(
			utf8.encode(json.encode(inputs.map((x) => x.toJson()).toList()))
		 + utf8.encode(json.encode(output.toJson()))
		 ).bytes
	);

	Gladiator.fromJson(Map<String, dynamic> json): 
		inputs = List<GladiatorInput>.from(json['inputs'].map((x) => GladiatorInput.fromJson(x))), 
		output = GladiatorOutput.fromJson(json['output']),
		id = json['id'];
	
	Map<String, dynamic> toJson() => {
		'inputs': inputs.map((x) => x.toJson()).toList(),
		'output': output.toJson(),
		'id': id
	};
}
