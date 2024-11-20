import 'package:flutter/material.dart';

class EULAScreen extends StatelessWidget {
  const EULAScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('End User License Agreement'),
        backgroundColor: Colors.teal[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'End User License Agreement (EULA)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            const Text(
              'This End User License Agreement ("Agreement") is a legal agreement between you and LedgerPro.\n\n'
              '1. Grant of License\n'
              'LedgerPro grants you a revocable, non-exclusive, non-transferable, limited license to download, install and use the application strictly in accordance with the terms of this Agreement.\n\n'
              '2. Restrictions\n'
              'You agree not to, and you will not permit others to:\n'
              '- License, sell, rent, lease, assign, distribute, transmit, host, outsource, disclose or otherwise commercially exploit the application\n'
              '- Modify, make derivative works of, disassemble, decrypt, reverse compile or reverse engineer any part of the application\n\n'
              '3. Intellectual Property Rights\n'
              'LedgerPro and its entire contents, features, and functionality are owned by us and are protected by international copyright, trademark, patent, trade secret, and other intellectual property or proprietary rights laws.\n\n'
              '4. Third-Party Services\n'
              'The application may display, include or make available third-party content or provide links to third-party websites or services.\n\n'
              '5. Updates to Application\n'
              'LedgerPro may from time to time provide enhancements or improvements to the features/functionality of the application, which may include patches, bug fixes, updates, upgrades and other modifications.\n\n'
              '6. Term and Termination\n'
              'This Agreement shall remain in effect until terminated by you or LedgerPro. We may, in its sole discretion, at any time and for any or no reason, suspend or terminate this Agreement with or without prior notice.\n\n'
              '7. Severability\n'
              'If any provision of this Agreement is held to be unenforceable or invalid, such provision will be changed and interpreted to accomplish the objectives of such provision to the greatest extent possible under applicable law and the remaining provisions will continue in full force and effect.\n\n'
              '8. Amendments to this Agreement\n'
              'LedgerPro reserves the right, at its sole discretion, to modify or replace this Agreement at any time.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
