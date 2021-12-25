import './tx.dart';
import 'p2p.dart';
class Account {
	final String publicKey;
	final List<String> signature;
	Account(this.publicKey, this.signature);
}

class AccountPool {
	List<Account> accounts = [];

	void addAccount(Account account) {
		accounts.add(account);
	}
	List<Account> getAccounts() {
		return accounts;
	}
	void clear() {
		accounts = [];
	}
}
class TxPool {
	List<Tx> txs = [];
	TxPool();
	Map<String, dynamic> toJson(bool stuck) => {
		'txs': txs.where((element) => element.txToHash.stuck == stuck).toList()
	};
	TxPool.fromJson(Map<String, dynamic> json): txs = json['txs'].map((tx) => Tx.fromJson(tx));
}
