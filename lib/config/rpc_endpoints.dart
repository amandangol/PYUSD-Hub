class RpcEndpoints {
  static const String mainnetHttpRpcUrl =
      'https://blockchain.googleapis.com/v1/projects/oceanic-impact-451616-f5/locations/us-central1/endpoints/ethereum-mainnet/rpc?key=AIzaSyAnZZi8DTOXLn3zcRKoGYtRgMl-YQnIo1Q';

  static const String mainnetWssRpcUrl =
      'wss://blockchain.googleapis.com/v1/projects/oceanic-impact-451616-f5/locations/us-central1/endpoints/ethereum-mainnet/rpc?key=AIzaSyAnZZi8DTOXLn3zcRKoGYtRgMl-YQnIo1Q';

  static const String sepoliaTestnetHttpRpcUrl =
      'https://blockchain.googleapis.com/v1/projects/oceanic-impact-451616-f5/locations/us-central1/endpoints/ethereum-sepolia/rpc?key=AIzaSyAnZZi8DTOXLn3zcRKoGYtRgMl-YQnIo1Q';

  static const String sepoliaTestnetWssRpcUrl =
      'wss://blockchain.googleapis.com/v1/projects/oceanic-impact-451616-f5/locations/us-central1/endpoints/ethereum-sepolia/rpc?key=AIzaSyAnZZi8DTOXLn3zcRKoGYtRgMl-YQnIo1Q';

  static const String getBlockByNumber = 'eth_getBlockByNumber';
  static const String getTransactionByHash = 'eth_getTransactionByHash';
  static const String getTransactionReceipt = 'eth_getTransactionReceipt';
  static const String getBalance = 'eth_getBalance';
  static const String getBlockNumber = 'eth_blockNumber';
  static const String call = 'eth_call';
  static const String estimateGas = 'eth_estimateGas';
  static const String gasPrice = 'eth_gasPrice';
  static const String sendRawTransaction = 'eth_sendRawTransaction';

  static const String latest = 'latest';
  static const String pending = 'pending';
  static const String earliest = 'earliest';
}
