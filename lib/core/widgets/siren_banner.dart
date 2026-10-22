import 'package:flutter/material.dart';

import '../services/siren_service.dart';

/// Red banner with a "Silence alarm" button, visible only while the siren rings.
class SirenBanner extends StatelessWidget {
  const SirenBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SirenService.instance,
      builder: (context, _) {
        if (!SirenService.instance.isPlaying) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFB3261E),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.campaign, color: Colors.white),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'NEW SOS ALERT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: SirenService.instance.stop,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                icon: const Icon(Icons.volume_off),
                label: const Text('Silence'),
              ),
            ],
          ),
        );
      },
    );
  }
}
