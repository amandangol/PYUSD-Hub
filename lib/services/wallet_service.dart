// File: lib/services/wallet_service.dart
import 'dart:math';
import 'package:bip39/bip39.dart' as bip39;
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hex/hex.dart';
import 'package:pyusd_forensics/models/wallet.dart';
import 'package:web3dart/web3dart.dart';

class WalletService {
  static const String _walletAddressKey = 'wallet_address';
  static const String _walletPrivateKey = 'wallet_private_key';
  static const String _walletMnemonic = 'wallet_mnemonic';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Generate a new wallet
  Future<WalletModel> createWallet() async {
    // Generate a random mnemonic (seed phrase)
    final mnemonic = bip39.generateMnemonic(strength: 128); // 12 words
    return await _createWalletFromMnemonic(mnemonic);
  }

  // Import wallet using mnemonic
  Future<WalletModel> importWalletFromMnemonic(String mnemonic) async {
    if (!bip39.validateMnemonic(mnemonic)) {
      throw Exception('Invalid mnemonic phrase');
    }

    return await _createWalletFromMnemonic(mnemonic);
  }

  // Import wallet using private key
  Future<WalletModel> importWalletFromPrivateKey(String privateKey) async {
    if (privateKey.startsWith('0x')) {
      privateKey = privateKey.substring(2);
    }

    final credentials = EthPrivateKey.fromHex(privateKey);
    final address = await credentials.extractAddress();

    await _secureStorage.write(key: _walletAddressKey, value: address.hex);
    await _secureStorage.write(key: _walletPrivateKey, value: privateKey);

    return WalletModel(
      address: address.hex,
      privateKey: privateKey,
      mnemonic: '',
      credentials: credentials,
    );
  }

  // Create wallet from mnemonic and save securely
  Future<WalletModel> _createWalletFromMnemonic(String mnemonic) async {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final master = await ED25519_HD_KEY.getMasterKeyFromSeed(seed);
    final privateKey = HEX.encode(master.key);

    final credentials = EthPrivateKey.fromHex(privateKey);
    final address = await credentials.extractAddress();

    await _secureStorage.write(key: _walletAddressKey, value: address.hex);
    await _secureStorage.write(key: _walletPrivateKey, value: privateKey);
    await _secureStorage.write(key: _walletMnemonic, value: mnemonic);

    return WalletModel(
      address: address.hex,
      privateKey: privateKey,
      mnemonic: mnemonic,
      credentials: credentials,
    );
  }

  // Load wallet from secure storage
  Future<WalletModel?> loadWallet() async {
    final address = await _secureStorage.read(key: _walletAddressKey);
    final privateKey = await _secureStorage.read(key: _walletPrivateKey);
    final mnemonic = await _secureStorage.read(key: _walletMnemonic) ?? '';

    if (address == null || privateKey == null) {
      return null;
    }

    final credentials = EthPrivateKey.fromHex(privateKey);

    return WalletModel(
      address: address,
      privateKey: privateKey,
      mnemonic: mnemonic,
      credentials: credentials,
    );
  }

  // Delete wallet from secure storage
  Future<void> deleteWallet() async {
    await _secureStorage.delete(key: _walletAddressKey);
    await _secureStorage.delete(key: _walletPrivateKey);
    await _secureStorage.delete(key: _walletMnemonic);
  }

  // Check if wallet exists
  Future<bool> walletExists() async {
    final address = await _secureStorage.read(key: _walletAddressKey);
    return address != null;
  }
}
