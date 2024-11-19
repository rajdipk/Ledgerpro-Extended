import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        backgroundColor: Colors.teal[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms and Conditions for LedgerPro',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            const Text(
              '1. Acceptance of Terms\n'
              'By accessing and using LedgerPro, you accept and agree to be bound by the terms and provisions of this agreement.\n\n'
              '2. Use License\n'
              'Permission is granted to use LedgerPro for business accounting and ledger management purposes subject to the following conditions:\n'
              '- The software shall be used solely for authorized business purposes\n'
              '- You shall not copy or modify the software\n'
              '- You shall not reverse engineer the software\n\n'
              '3. Data Privacy\n'
              'We are committed to protecting your data. All business information entered into LedgerPro is encrypted and stored securely.\n\n'
              '4. User Responsibilities\n'
              'Users are responsible for:\n'
              '- Maintaining the confidentiality of their account\n'
              '- All activities that occur under their account\n'
              '- Ensuring their data is accurate and up-to-date\n\n'
              '5. Software Updates\n'
              'LedgerPro may automatically download and install updates. These updates are designed to improve, enhance and further develop the software.\n\n'
              '6. Termination\n'
              'We reserve the right to terminate or suspend access to our software for any reason, including breach of these terms.\n\n'
              '7. Limitation of Liability\n'
              'LedgerPro shall not be liable for any indirect, incidental, special, consequential or punitive damages resulting from your use of the software.\n\n'
              '8. Changes to Terms\n'
              'We reserve the right to modify these terms at any time. We will notify users of any changes by updating the date at the top of this agreement.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
