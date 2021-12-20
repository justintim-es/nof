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
Future main(List<String> arguments) async {
	var accPool = AccountPool();
	var parser = ArgParser();
	parser.addOption('bootnode');
	parser.addOption('publicKey');
	parser.addOption('saveTxt', mandatory: true);
	var aschargs = parser.parse(arguments);
	String? publicKey = aschargs['publicKey'];
	if (publicKey == null) {
		Wallet wallet = Wallet();		
		print('Please store your new keypair');
	 	print(wallet.privateKey);
	 	print(wallet.publicKey);
	 	publicKey = wallet.publicKey;
	}
	final file = File(aschargs['saveTxt']);
	if(!await file.exists()) {
		Block incipio = await Block.incipio(
			ToHash(
				Script.INCIPIO, 
				0, 
				0, 
				0, 
				0, 
				DateTime.now().millisecondsSinceEpoch, 
				'', 
				[Gladiator(GladiatorOutput([publicKey!]), [])], 
				[Tx([], [TxOutput(BigInt.tryParse('10000000000000000000000000')!, publicKey!)])]
			)
		);
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
	app.post('/create-transaction', (Request, request) {
		
	})
	app.post('/apply-refree-account/<publicKey>', (Request request, String publicKey) async {
		Block lastBlock = Block.prevBlock(await blocks(file).last);
		String sischig = signature(PrivateKey.fromHex(Wallet.curve, lastBlock.toHash.wallet.privateKey), Utils.HexToListOfInt(publicKey)).toCompactHex();
		accPool.addAccount(Account(publicKey, sischig));
		return Response.ok("Added account to account pool"); 		
	});
	app.post('/mine-efectus', (Request request) async {
		Block prevBlock = Block.prevBlock(await blocks(file).last);
 		Block.efectus(
 			ToHash(
				Script.PRODUCED,
				0, 
				await Block.blockNumber(blocks(file)), 
				await Block.difficulty(blocks(file)),
				await Block.totalDifficulty(blocks(file)),
				DateTime.now().millisecondsSinceEpoch, 
				prevBlock.hash, 
				[Gladiator(GladiatorOutput(accPool.getAccounts().map((a) => a.publicKey).toList()), [])], 
				[]
			)
		).then((block) => block.save(file));
		return Response.ok("Started effectus miner");
	});
	var server = await io.serve(app, '127.0.0.1', 8080);	
}



Stream<String> blocks(File file) {
	return file.openRead()
		.transform(utf8.decoder)
		.transform(LineSplitter());
}

	
