import 'dart:io';
import 'dart:convert';
import './tx.dart';
import './pools.dart';
import './block.dart';
import './utils.dart';

class RequestBlock {
  final List<int> blockNumber;
  RequestBlock(this.blockNumber);
  Map<String, dynamic> toJson() => {
    'blockNumber': blockNumber
  };
  RequestBlock.fromJson(Map<String, dynamic> json): blockNumber = List<int>.from(json['blockNumber']);
}
class BroadcastBlock {
  final Block block;
  BroadcastBlock(this.block);
  Map<String, dynamic> toJson() => {
    'block': block
  };
  BroadcastBlock.fromJson(Map<String, dynamic> json):
      block = Block.fromJson(json['block']);
}

class PeerMessage {
  TxsPeer? txsPeer;
  RequestSocket? requestSocket;
  BroadcastBlock? broadcastBlock;
  RequestBlock? requestBlock;
  PeerMessage();
  PeerMessage.txsPeer(this.txsPeer);
  PeerMessage.requestSocket(this.requestSocket);
  PeerMessage.broadcastBlock(this.broadcastBlock);
  PeerMessage.requestBlock(this.requestBlock);
  Map<String, dynamic> toJson() => {
    'txsPeer': txsPeer?.toJson(),
    'requestSocket': requestSocket?.toJson(),
    'requestBroadcastBlock': broadcastBlock?.toJson()
  };
  PeerMessage.fromJson(Map<String, dynamic> json):
    txsPeer = (json['txsPeer'] != null) ? TxsPeer.fromJson(json['txsPeer']) : null,
    requestSocket = (json['requestSocket'] != null) ? RequestSocket.fromJson(json['requestSocket']) : null,
    broadcastBlock = (json['requestBroadcastBlock'] != null) ? BroadcastBlock.fromJson(json['requestBroadcastBlock']) : null;
}
class TxsPeer {
  final List<Tx> txs;
  TxsPeer(this.txs);
  Map<String, dynamic> toJson() => {
    'txs': txs.toList()
  };
  TxsPeer.fromJson(Map<String, dynamic> jsoschon): txs = List<Tx>.from(jsoschon['txs'].map((x) => Tx.fromJson(x)));
}

class RequestSocket {
  final List<String> sockets;
  RequestSocket(this.sockets);
  Map<String, dynamic> toJson() => {
      'sockets': sockets
  };
  RequestSocket.fromJson(Map<String, dynamic> json): sockets = List<String>.from(json['sockets']);
}
class PeerServer {
    final String path;
    final String host;
    final int port;
    final TxPool txPool;
    final File file;
    ServerSocket? serverSocket;
    Socket? socket;
    List<String> sockets = [];
    PeerServer(this.path, this.host, this.port, this.txPool, this.file) {
      sockets.add(host + ':' + port.toString());
    }


    void bind() async {
      serverSocket = await ServerSocket.bind(host, port);
      serverSocket!.listen((socket) {
        socket = socket;
        socket.listen((data) async {
          PeerMessage daschat = PeerMessage.fromJson(json.decode(utf8.decode(data)));
          if (daschat.requestSocket != null) {
              sockets.addAll(daschat.requestSocket!.sockets.where((element) => !sockets.contains(element)));
              socket.write(json.encode(PeerMessage.requestSocket(RequestSocket(sockets)).toJson()));
          } else if(daschat.txsPeer != null) {
             txPool.txs.addAll(daschat.txsPeer!.txs.where((element) => !txPool.txs.any((eschel) => eschel.txToHash.id == element.txToHash.id)));
          } else if (daschat.broadcastBlock != null) {
              Block lastBlock = await Utils.lastBlock(file);
              //if (
              //(lastBlock.toHash.blockNumber![lastBlock.toHash.blockNumber!.length - 1] + 1) == daschat.broadcastBlock!.block.toHash.blockNumber) {
                //  daschat.broadcastBlock!.block.validate(file);
                  //daschat.broadcastBlock!.block.save(path);
              //} else {
               // socket.write(json.encode(PeerMessage.requestBlock(RequestBlock(lastBlock.toHash.blockNumber)).toJson()));
             // }
          } else if (daschat.requestBlock != null) {

          }
        });
      });
    }
    List<String> getSockets() {
      return sockets;
    }
    
    void errorHandler(error, stackTrace) {
      print(error);
    }
    void connect(String externalIp, String bootNode) async {
      List<String> splitted = bootNode.split(':');
      Socket socket = await Socket.connect(splitted[0], int.parse(splitted[1]));
      socket.write(json.encode(PeerMessage.requestSocket(RequestSocket(List<String>.from([externalIp + ':' + port.toString()]))).toJson()));
    }
    void syncTxs() async {
      for (String soschock in sockets) {
        List<String> splitted = soschock.split(':');
        Socket cuschur = await Socket.connect(splitted[0], int.parse(splitted[1]));
        cuschur.write(json.encode(PeerMessage.txsPeer(TxsPeer(txPool.txs)).toJson()));
      }
    }
    void broadcastBlock(Block block) async {
      for (String soschock in sockets) {
        List<String> splitted = soschock.split(':');
        Socket cuschur = await Socket.connect(splitted[0], int.parse(splitted[1]));
       // cuschur.write(json.encode(PeerMessage.broadcastBlock(BroadcastBlock(block)).toJson()));
      }
    }
    void doneHandler() {
      socket!.destroy();
    }
}
