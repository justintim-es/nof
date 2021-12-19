class Account {
	final String publicKey;
	final String signature;
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
}
