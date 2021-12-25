import './base.dart';
import 'package:hex/hex.dart';
import 'dart:convert';
import './utils.dart';
import 'package:crypto/crypto.dart';
class GladiatorInput extends BaseInput {
	final String gladiatorId;
	GladiatorInput(String signature, this.gladiatorId): super(signature);
	GladiatorInput.fromJson(Map<String, dynamic> json): gladiatorId = json['gladiatorId'], super(json['signature']);
	Map<String, dynamic> toJson() => {
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
	final GladiatorOutput? output;
	final GladiatorInput? input;
	final String id;
	Gladiator(this.output, this.input):
	id = HEX.encode(
		sha512.convert(
			utf8.encode(json.encode(input?.toJson()))
		 + utf8.encode(json.encode(output?.toJson()))
		 ).bytes
	);

	Gladiator.fromJson(Map<String, dynamic> json): 
		input = json['input'] != null ? GladiatorInput.fromJson(json['input'])  : null,
		output = json['output'] != null  ? GladiatorOutput.fromJson(json['output']) : null,
		id = json['id'];
	
	Map<String, dynamic> toJson() => {
		'input': input?.toJson(),
		'output': output?.toJson(),
		'id': id
	};
}
