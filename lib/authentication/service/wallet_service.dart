import 'dart:convert';
import 'package:bip39/bip39.dart' as bip39;
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hex/hex.dart';
import 'package:web3dart/web3dart.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

import '../model/wallet.dart';

class WalletService {
  static const String _walletAddressKey = 'wallet_address';
  static const String _encryptedPrivateKey = 'encrypted_private_key';
  static const String _encryptedMnemonic = 'encrypted_mnemonic';
  static const String _walletIV = 'wallet_iv';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Generate a new wallet
  Future<WalletModel> createWallet() async {
    // Generate a random mnemonic (seed phrase)
    final mnemonic = bip39.generateMnemonic(strength: 128); // 12 words
    return _createWalletFromMnemonic(mnemonic);
  }

  // Import wallet using mnemonic
  Future<WalletModel> importWalletFromMnemonic(String mnemonic) async {
    if (!bip39.validateMnemonic(mnemonic)) {
      throw Exception('Invalid mnemonic phrase');
    }

    return _createWalletFromMnemonic(mnemonic);
  }

  // Import wallet using private key
  Future<WalletModel> importWalletFromPrivateKey(String privateKey) async {
    if (privateKey.startsWith('0x')) {
      privateKey = privateKey.substring(2);
    }

    final credentials = EthPrivateKey.fromHex(privateKey);
    final address = await credentials.extractAddress();

    // Store only the address in plaintext
    await _secureStorage.write(key: _walletAddressKey, value: address.hex);

    return WalletModel(
      address: address.hex,
      privateKey: privateKey,
      mnemonic: '',
      credentials: credentials,
    );
  }

  // Create wallet from mnemonic
  Future<WalletModel> _createWalletFromMnemonic(String mnemonic) async {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final master = await ED25519_HD_KEY.getMasterKeyFromSeed(seed);
    final privateKey = HEX.encode(master.key);

    final credentials = EthPrivateKey.fromHex(privateKey);
    final address = credentials.address.hex;

    // Store only the address in plaintext
    _secureStorage.write(key: _walletAddressKey, value: address);

    return WalletModel(
      address: address,
      privateKey: privateKey,
      mnemonic: mnemonic,
      credentials: credentials,
    );
  }

  // Encrypt and store wallet data
  Future<void> encryptAndStoreWallet(WalletModel wallet, String pin) async {
    // Create encryption key from PIN (using PIN as key derivation material)
    final key = _deriveKeyFromPin(pin);

    // Generate random IV
    final iv = encrypt.IV.fromSecureRandom(16);

    // Create encrypter
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    // Encrypt private key and mnemonic
    final encryptedPrivateKey = encrypter.encrypt(wallet.privateKey, iv: iv);
    final encryptedMnemonic = wallet.mnemonic.isNotEmpty
        ? encrypter.encrypt(wallet.mnemonic, iv: iv)
        : null;

    // Store encrypted data and IV
    await _secureStorage.write(key: _walletAddressKey, value: wallet.address);
    await _secureStorage.write(
        key: _encryptedPrivateKey, value: encryptedPrivateKey.base64);
    if (encryptedMnemonic != null) {
      await _secureStorage.write(
          key: _encryptedMnemonic, value: encryptedMnemonic.base64);
    }
    await _secureStorage.write(key: _walletIV, value: iv.base64);
  }

  // Decrypt and load wallet
  // Decrypt and load wallet
  Future<WalletModel?> decryptAndLoadWallet(String pin) async {
    final address = await _secureStorage.read(key: _walletAddressKey);
    final encryptedPrivateKey =
        await _secureStorage.read(key: _encryptedPrivateKey);
    final encryptedMnemonic =
        await _secureStorage.read(key: _encryptedMnemonic);
    final ivString = await _secureStorage.read(key: _walletIV);

    if (address == null || encryptedPrivateKey == null || ivString == null) {
      return null;
    }

    // Derive key from PIN
    final key = _deriveKeyFromPin(pin);

    // Parse IV
    final iv = encrypt.IV.fromBase64(ivString);

    // Create decrypter
    final decrypter = encrypt.Encrypter(encrypt.AES(key));

    try {
      // Decrypt private key
      final privateKey = decrypter.decrypt64(encryptedPrivateKey, iv: iv);

      // Decrypt mnemonic if available
      String mnemonic = '';
      if (encryptedMnemonic != null) {
        mnemonic = decrypter.decrypt64(encryptedMnemonic, iv: iv);
      }

      // Create credentials
      final credentials = EthPrivateKey.fromHex(privateKey);

      return WalletModel(
        address: address,
        privateKey: privateKey,
        mnemonic: mnemonic,
        credentials: credentials,
      );
    } catch (e) {
      throw Exception('Failed to decrypt wallet: Invalid PIN');
    }
  }

  // Decrypt with key from biometric storage
  Future<WalletModel?> decryptAndLoadWalletWithKey(String secretKey) async {
    // The secretKey here is actually the PIN that was stored securely with biometric protection
    return decryptAndLoadWallet(secretKey);
  }

  // Load wallet metadata (address only)
  Future<WalletModel?> loadWalletMetadata() async {
    final address = await _secureStorage.read(key: _walletAddressKey);

    if (address == null) {
      return null;
    }

    return WalletModel(
      address: address,
      privateKey: '', // Empty for security
      mnemonic: '', // Empty for security
      credentials: EthPrivateKey.fromHex('0' * 64), // Placeholder credentials
    );
  }

  // Delete wallet from secure storage
  Future<void> deleteWallet() async {
    await _secureStorage.delete(key: _walletAddressKey);
    await _secureStorage.delete(key: _encryptedPrivateKey);
    await _secureStorage.delete(key: _encryptedMnemonic);
    await _secureStorage.delete(key: _walletIV);
  }

  // Check if wallet exists
  Future<bool> walletExists() async {
    final address = await _secureStorage.read(key: _walletAddressKey);
    return address != null;
  }

  // Helper method to derive encryption key from PIN
  encrypt.Key _deriveKeyFromPin(String pin) {
    // Using SHA-256 to derive a 32-byte key from the PIN
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return encrypt.Key.fromBase16(digest.toString());
  }
}
