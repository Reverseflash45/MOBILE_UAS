import 'package:flutter/material.dart';

class TrackingTicketScreen extends StatelessWidget {
  const TrackingTicketScreen({super.key});

  int _getStatusStep(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 0;
      case 'assign':
        return 1;
      case 'in progress':
        return 2;
      case 'close':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final status = args?['status']?.toString() ?? 'open';
    final currentStep = _getStatusStep(status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Tiket'),
      ),
      body: Stepper(
        currentStep: currentStep,
        controlsBuilder: (context, details) => const SizedBox.shrink(),
        steps: [
          Step(
            title: const Text('Open'),
            content: const Text('Tiket telah dibuat oleh pengguna dan tersimpan di sistem.'),
            isActive: currentStep >= 0,
            state: currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Assign'),
            content: const Text('Admin telah menerima tiket dan bersiap untuk menugaskan Helpdesk.'),
            isActive: currentStep >= 1,
            state: currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('In Progress'),
            content: const Text('Helpdesk sedang mengerjakan perbaikan.'),
            isActive: currentStep >= 2,
            state: currentStep > 2 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Close'),
            content: const Text('Pekerjaan telah selesai dilakukan oleh Helpdesk.'),
            isActive: currentStep >= 3,
            state: currentStep >= 3 ? StepState.complete : StepState.indexed,
          ),
        ],
      ),
    );
  }
}