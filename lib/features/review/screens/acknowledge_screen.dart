import 'package:flutter/material.dart';

import 'owner_review_screen.dart';

class AcknowledgeScreen extends StatelessWidget {
  const AcknowledgeScreen({super.key, required this.auditId});

  final String auditId;

  @override
  Widget build(BuildContext context) {
    return OwnerReviewScreen(auditId: auditId);
  }
}
