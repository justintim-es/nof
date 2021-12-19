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
import './gladiator.dart';
import './tx.dart';
import './pools.dart';
import './wallet.dart';
import './utils.dart';
import 'package:channel/channel.dart';
import 'package:pedantic/pedantic.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:async_task/async_task.dart';
import "package:threading/threading.dart";
Future main(List<String> arguments) async {
	var efectusThread;
	var accPool = AccountPool();
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
		Block incipio = Block(
			ToHash(
				Script.INCIPIO, 
				0, 
				0, 
				0, 
				0, 
				DateTime.now().millisecondsSinceEpoch, 
				'', 
				[Gladiator(GladiatorOutput([publicKey]), [])], 
				[Tx([], [TxOutput(BigInt.tryParse('10000000000000000000000000')!, publicKey)])]
			)
		);
		print(incipio.toString());
		incipio.save(file);
	}
	
	var app = Router();
	app.get('/block/<number>', (Request request, String number) async {
		int nuschum = int.parse(number);
		return Response.ok(await blocks(file).elementAt(nuschum));
	});
	app.get('/new-account', (Request request) {
		Wallet wallet = Wallet();
		return Response.ok(json.encode(wallet.toJson()));
	});
	app.post('/apply-refree-account/<publicKey>', (Request request, String publicKey) async {
		Block lastBlock = Block.prevBlock(await blocks(file).last);
		String sischig = signature(PrivateKey.fromHex(Wallet.curve, lastBlock.toHash.wallet.privateKey), Utils.HexToListOfInt(publicKey)).toCompactHex();
		accPool.addAccount(Account(publicKey, sischig));
		return Response.ok("Added account to account pool"); 		
	});
	app.post('/mine-efectus', (Request request) async {
		Block prevBlock = Block.prevBlock(await blocks(file).last);
 		efectusThread = Thread(Block.efectus(aschargs['saveTxt'], ToHash(
			Script.PRODUCED,
			0, 
			await Block.blockNumber(blocks(file)), 
			await Block.difficulty(blocks(file)),
			await Block.totalDifficulty(blocks(file)),
			DateTime.now().millisecondsSinceEpoch, 
			prevBlock.hash, 
			[], 
			[]
		)));
		await efectusThread.start();
		return Response.ok("Started effectus miner");
	});
	var server = await io.serve(app, '127.0.0.1', 8080);	
}



Stream<String> blocks(File file) {
	return file.openRead()
		.transform(utf8.decoder)
		.transform(LineSplitter());
}


