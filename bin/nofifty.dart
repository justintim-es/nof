import 'package:args/args.dart';
import 'dart:io';
import './block.dart';
import 'dart:convert';
import 'package:ecdsa/ecdsa.dart';
import 'package:elliptic/elliptic.dart';
import 'dart:async';
import 'dart:core';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

Future main(List<String> arguments) async {
	var parser = ArgParser();
	parser.addOption('publicKey');
	parser.addOption('bootnode');
	parser.addOption('saveTxt', mandatory: true);
	var aschargs = parser.parse(arguments);
	String? publicKey = aschargs['publicKey'];
	if (publicKey == null) {
		var ec = getP256();
	  	var priv = ec.generatePrivateKey();
	 	publicKey = priv.publicKey.toString();		
	}
	final file = File(aschargs['saveTxt']);
	if(!await file.exists()) {
		Block incipio = Block(ToHash(Script.INCIPIO, 0, 0, 0, 0, '', [Gladiator([], [GladiatorOutput(publicKey)])], [Tx([], [TxOutput(publicKey, BigInt.tryParse('10000000000000000000000000')!)])]));
		print(incipio.toString());
		incipio.save(aschargs['saveTxt']);
	} else {
		Stream<String> lines = blocks(file);
		try {
			await for (var line in lines) {
				print(Block.fromJson(json.decode(line)));
			}
		} catch(e, st) {
			print(e);
			print(st);
		} 
	}
	var app = Router();
	app.get('/block/<number>', (Request request, String number) async {
		int nuschum = int.parse(number);
		return Response.ok(await blocks(file).elementAt(nuschum));
	});
	var server = await io.serve(app, '127.0.0.1', 8080);
	
}
Stream<String> blocks(File file) {
	return file.openRead()
		.transform(utf8.decoder)
		.transform(LineSplitter());
}



