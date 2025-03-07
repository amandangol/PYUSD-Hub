// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../../../homescreen/widgets/custom_textfield.dart';

// class AmountInputCard extends StatelessWidget {
//   final TextEditingController amountController;
//   final String selectedAsset;
//   final double availableBalance;
//   final double maxSendableEth;
//   final double estimatedGasFee;
//   final Function(String) onAmountChanged;
//   final VoidCallback onMaxPressed;

//   const AmountInputCard({
//     Key? key,
//     required this.amountController,
//     required this.selectedAsset,
//     required this.availableBalance,
//     required this.maxSendableEth,
//     required this.estimatedGasFee,
//     required this.onAmountChanged,
//     required this.onMaxPressed,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Amount',
//                   style: theme.textTheme.titleMedium,
//                 ),
//                 _AssetTag(assetName: selectedAsset),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(
//                   child: CustomTextFiel