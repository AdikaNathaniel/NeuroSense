import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DeleteFacilityPage extends StatefulWidget {
  const DeleteFacilityPage({super.key});

  @override
  State<DeleteFacilityPage> createState() => _DeleteFacilityPageState();
}

class _DeleteFacilityPageState extends State<DeleteFacilityPage> {
  final TextEditingController _nameController = TextEditingController();
  bool isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _deleteFacility(String facilityName) async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // URL encode the facility name to handle spaces and special characters
      final encodedName = Uri.encodeComponent(facilityName);
      final url = Uri.parse("https://neurosense-palsy.fly.dev/api/v1/facilities/$encodedName");
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _nameController.clear(); 
        _showSuccessDialog(facilityName);
      } else if (response.statusCode == 404) {
        _showErrorDialog("Facility '$facilityName' not found");
      } else {
        _showErrorDialog("Failed to delete facility. Status: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorDialog("Error: ${e.toString()}");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showConfirmDialog(String facilityName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Facility?"),
        content: Text("Are you sure you want to delete the facility '$facilityName'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(); // Close confirmation dialog
              _deleteFacility(facilityName);
            },
            icon: const Icon(Icons.delete),
            label: const Text("Delete Facility"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String facilityName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 10),
            Text(
              "Facility Deleted Successfully!",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "'$facilityName' has been removed from the system.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _onDeletePressed() {
    if (!_formKey.currentState!.validate()) return;
    
    final facilityName = _nameController.text.trim();
    if (facilityName.isEmpty) {
      _showErrorDialog("Please enter a Facility Name.");
    } else {
      _showConfirmDialog(facilityName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Delete Facility"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.business,
                        size: 48,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Delete Facility by Name',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Facility Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                          hintText: 'e.g Cerebral Center',
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter a facility name' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _onDeletePressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            disabledBackgroundColor: Colors.green.withOpacity(0.5),
                          ),
                          child: isLoading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text('Deleting...'),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete Facility',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (isLoading)
                        const Text(
                          'Deleting facility... Please wait.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            //   const SizedBox(height: 20),
              // FIXED: Removed const from Container and Row
            //   Container(
            //     padding: const EdgeInsets.all(12),
            //     decoration: BoxDecoration(
            //       color: Colors.green[50],
            //       borderRadius: BorderRadius.circular(8),
            //       border: Border.all(color: Colors.green[100] ?? Colors.green.shade100),
            //     ),
            //     child: Row(
            //       children: [
            //         const Icon(Icons.warning, color: Colors.green, size: 20),
            //         const SizedBox(width: 8),
            //         Expanded(
            //           child: Text(
            //             'This action is permanent and cannot be undone.',
            //             style: TextStyle(
            //               fontSize: 12,
            //               color: Colors.green[800] ?? Colors.green.shade800,
            //             ),
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}