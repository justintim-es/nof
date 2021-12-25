import 'package:args/args.dart';
import 'package:tuple/tuple.dart';
import 'dart:io';
import './block.dart';
import 'dart:convert';
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
import './p2p.dart';
import 'dart:isolate';
// CONSTANTS
const int MAX_TX = 2;
Future main(List<String> arguments) async {
	try {
		AccountPool accPool = AccountPool();
		TxPool txPool = TxPool();
		var parser = ArgParser();
		parser.addOption('bootnode');
		parser.addOption('privateKey');
		parser.addOption('external-ip', mandatory: true);
		parser.addOption('internal-ip', mandatory: true);
		parser.addOption('port', mandatory: true);
		parser.addOption('rpc-port', mandatory: true);
		parser.addOption('saveFolder', mandatory: true);
		var aschargs = parser.parse(arguments);
		Directory(aschargs['saveFolder']).createSync( recursive: true );
		PeerServer peerServer =
		PeerServer(aschargs['saveFolder'], aschargs['internal-ip'], int.parse(aschargs['port']), txPool, Utils.highestFile(aschargs['saveFolder']));
		peerServer.bind();
		if (aschargs['bootnode'] != null) {
			peerServer.connect(aschargs['external-ip'], aschargs['bootnode']);
		}

		String? privateKey = aschargs['privateKey'];
		if (privateKey == null) {
			Wallet wallet = Wallet();
			print('Please store your new keypair');
			print(wallet.privateKey);
			print(wallet.publicKey);
			privateKey = wallet.privateKey;
		}
		PrivateKey signKey = PrivateKey.fromHex(Wallet.curve, privateKey!);
		String publicKey = signKey.publicKey.toString();
		File(aschargs['saveFolder'] + '/blocks_0.txt').createSync();
		final file = Utils.highestFile(aschargs['saveFolder']);
		if(await Utils.fileLength(file) == 0 && aschargs['bootnode'] == null) {
			Block incipio = await Block.incipio(
					ToHash(
						Script.INCIPIO,
						0,
						DateTime.now().millisecondsSinceEpoch,
						BigInt.zero,
						BigInt.zero,
						publicKey,
						'',
						await Block.blockNumber(aschargs['saveFolder']),
						[Gladiator(GladiatorOutput([publicKey]), null)],
						[Tx('', TxToHash(false, 0, [], [TxOutput(BigInt.parse('10000000000000000000000000'), publicKey)]))],
						[],
					)
			);
			print(Utils.highestFile(aschargs['saveFolder']));
			await incipio.save(aschargs['saveFolder']);
		}

		var app = Router();
		app.get('/block/<number>', (Request request, String number) async {
			int nuschum = int.parse(number);
			return Response.ok(await Utils.fischilesche(file).elementAt(nuschum));
		});
		app.get('/new-account', (Request request) {
			Wallet wallet = Wallet();
			return Response.ok(json.encode(wallet.toJson()));
		});
		app.get('/defences/<gladiatorId>', (Request request, String gladiatorId) async {
			String defences = await Wallet.getDefences(gladiatorId, file);
			return Response.ok(json.encode(defences));
		});
		app.get('/sockets', (Request request) async {
			List<String> sockets = peerServer.getSockets();
			return Response.ok(json.encode(sockets));
		});
		app.get('/refree-tx-pool', (Request request) async {
			return Response.ok(json.encode(txPool.toJson(false)));
		});
		app.post('/create-refree-transaction', (Request request) async {
			var body = json.decode(await request.readAsString());
			if (body['privateKey'] == null || body['to'] == null || body['value'] == null || body['zeros'] == null) {
				return Response.forbidden(json.encode({"message": "Insufficient parameters"}));
			}
			TxToHash txToHash = await Wallet.newTx(false, body['privateKey'], body['to'], BigInt.parse(body['value']), file, txPool);
			final receivePort = ReceivePort();
			final isolate = await Isolate.spawn(Tx.doHash, [receivePort.sendPort, int.parse(body['zeros']), txToHash]);
			receivePort.listen((tx) {
				txPool.txs.add(tx);
				peerServer.syncTxs();
			});
			return Response.ok(json.encode(txToHash.toJson()));
		});
		app.post('/create-stuck-transactions', (Request request) async {
			var body = json.decode(await request.readAsString());
			if (body['privateKey'] == null || body['to'] == null || body['value'] == null || body['zeros'] == null) {
				return Response.forbidden(json.encode({"message": "Insufficient parameters"}));
			}
			TxToHash txToHash = await Wallet.newTx(true, body['privateKey'], body['to'], BigInt.parse(body['value']), file, txPool);
			// Tx.doHash(body['zeros'], txToHash).then((txHashed) => peerServer.txPool.txs.add(txHashed));
			return Response.ok(json.encode(txToHash.toJson()));
		});
//	app.post('/apply-refree-account/<publicKey>', (Request request, String publicKey) async {
//		Block lastBlock = Block.prevBlock(await Utils.fischilesche(file).last);
//		accPool.addAccount(Account(publicKey, List<String>.from([sischig])));
//		return Response.ok(json.encode({ "message": "Added account to account pool" }));
//	});
		app.post('/mine-efectus', (Request request) async {
			try {
				Block prevBlock = Block.prevBlock(await Utils.fischilesche(file).last);
				Tuple2<List<Tx>, List<Tx>> txs = Utils.pickTxs(txPool.txs);
				txs.item1.add(Tx('', TxToHash(false, 0, [], [TxOutput(BigInt.parse('10000000000000000000000000'), publicKey)])));
				final ToHash toHash = ToHash(
						Script.EFECTUS,
						0,
						DateTime.now().millisecondsSinceEpoch,
						BigInt.zero,
						BigInt.zero,
						publicKey,
						prevBlock.hash,
						await Block.blockNumber(aschargs['saveFolder']),
						(accPool.getAccounts().isNotEmpty) ? [Gladiator(GladiatorOutput(accPool.getAccounts().map((a) => a.publicKey).toList()), null)] : [],
						txs.item1,
						txs.item2
				);
				final recievePort = ReceivePort();
				final isolate = await Isolate.spawn(Block.efectus, [recievePort.sendPort, toHash]);
				recievePort.listen((block) {
					block.save(aschargs['saveFolder']);
					peerServer.broadcastBlock(block);
					txPool.txs.removeWhere((element) => txs.item1.contains(element) || txs.item2.contains(element));
				});
				return Response.ok(json.encode({ "message": "Started effectus miner" }));
			} catch (e, s) {
				print(e);
				print(s);
			}

		});
		app.post('/mine-confossus/<gladiatorId>', (Request request, String gladiatorId) async {
			Block prevBlock = Block.prevBlock(await Utils.fischilesche(file).last);
			Tuple2<List<Tx>, List<Tx>> txs = Utils.pickTxs(txPool.txs);
			Block.confossus(
					privateKey!,
					gladiatorId,
					ToHash(
						Script.CONFOSSUS,
						await Block.difficulty(aschargs['saveFolder']),
						DateTime.now().millisecondsSinceEpoch,
						BigInt.zero,
						await Block.totalDifficulty(aschargs['saveFolder']),
						publicKey,
						prevBlock.hash,
						await Block.blockNumber(aschargs['saveFolder']),
						accPool.getAccounts().isNotEmpty ? [Gladiator(GladiatorOutput(accPool.getAccounts().map((a) => a.publicKey).toList()), null)] : [],
						txs.item1,
						txs.item2,
					),
					file
			).then((block)  {
				block.save(aschargs['saveFolder']);
				txPool.txs = [];
				accPool.clear();
			}).catchError((onError) => print(onError));
			return Response.ok(json.encode({ "message": "Started confossus miner"}));
		});
		var server = await io.serve(app, '127.0.0.1', int.parse(aschargs['rpc-port']));
	} catch (e, s) {
		print(e);
		print(s);
	}

}

	
