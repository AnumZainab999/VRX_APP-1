
import 'package:flutter/material.dart';

class ErrorDialog {
  static const Map<String, Map<String, String>> _errorData = {
    'VRX-001': {
      'name': 'Camera Access Denied',
      'message': 'Please allow camera access to scan the medicine.',
    },
    'VRX-002': {
      'name': 'Invalid QR Code / Barcode',
      'message': 'Invalid code. Please scan a valid medicine label.',
    },
    'VRX-003': {
      'name': 'No Code Detected',
      'message': 'No code detected. Try scanning again with better focus.',
    },
    'VRX-004': {
      'name': 'Medicine Not Found in Database',
      'message': 'Medicine not found. It may be counterfeit or unregistered.',
    },
    'VRX-005': {
      'name': 'Medicine Expired',
      'message': 'Warning: This medicine has expired. Please do not use it.',
    },
    'VRX-006': {
      'name': 'Duplicate Serial Number',
      'message': 'Duplicate detected. This medicine might be fake.',
    },
    'VRX-007': {
      'name': 'Network Error',
      'message': 'Network error. Please check your internet connection.',
    },
    'VRX-008': {
      'name': 'Server Timeout',
      'message': 'Server not responding. Please try again later.',
    },
    'VRX-009': {
      'name': 'Session Timeout',
      'message': 'Your session has expired. Please log in again.',
    },
    'VRX-010': {
      'name': 'Corrupted Image Input',
      'message': 'Image unclear. Please take a clearer picture.',
    },
    'VRX-011': {
      'name': 'App Update Required',
      'message': 'Please update VRX to continue scanning medicines.',
    },
    'VRX-012': {
      'name': 'Database Synchronization Failed',
      'message': 'Sync failed. Try refreshing or check connection.',
    },
    'VRX-013': {
      'name': 'User Not Logged In',
      'message': 'Please log in to use this feature.',
    },
    'VRX-014': {
      'name': 'Unregistered Manufacturer',
      'message': 'This product’s manufacturer is not recognized. Beware of counterfeit.',
    },
    'VRX-015': {
      'name': 'Tampered Code Detected',
      'message': 'Tampering detected. This product might be fake.',
    },
    'VRX-016': {
      'name': 'Permission Error (Storage/Location)',
      'message': 'App needs additional permissions. Please enable in settings.',
    },
  };

  // Public getter for _errorData
  static Map<String, Map<String, String>> get errorData => _errorData;

  static void showByCode(BuildContext context, String errorCode) {
    final error = _errorData[errorCode];
    if (error == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.fromARGB(255, 228, 242, 255),
                ),
                padding: const EdgeInsets.all(16),
                child: const Icon(
                  Icons.notifications_none_outlined,
                  size: 40,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                error['name']!,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                error['message']!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Center(
                child: SizedBox(
                  width: 160,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Ok',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

