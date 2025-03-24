class EmptyStateUtils {
  static String getTransactionEmptyStateMessage(String filter) {
    switch (filter) {
      case 'All':
        return 'No transactions yet';
      case 'PYUSD':
        return 'No PYUSD transactions yet';
      case 'ETH':
        return 'No ETH transactions yet';
      default:
        return 'No transactions yet';
    }
  }
}
