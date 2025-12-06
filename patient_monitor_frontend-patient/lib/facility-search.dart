import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class FacilitySearchPage extends StatefulWidget {
  const FacilitySearchPage({super.key});

  @override
  State<FacilitySearchPage> createState() => _FacilitySearchPageState();
}

class _FacilitySearchPageState extends State<FacilitySearchPage> {
  final TextEditingController _nameController = TextEditingController();
  bool isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      return DateFormat('MMM d, yyyy \'at\' h:mm a').format(DateTime.parse(dateString));
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _launchURL(String url) async {
    if (url.isEmpty || url == 'N/A') return;
    
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  Future<void> _searchFacility() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final searchQuery = Uri.encodeComponent(_nameController.text.trim());
      final response = await http.get(
        Uri.parse('https://neurosense-palsy.fly.dev/api/v1/facilities/search?q=$searchQuery'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final facilities = data['result'] as List<dynamic>;
        
        if (facilities.isEmpty) {
          _showErrorDialog('No facility found with that name');
        } else if (facilities.length == 1) {
          // If only one result, show it directly
          _showFacilityDialog(facilities[0]);
        } else {
          // If multiple results, let user choose
          _showMultipleFacilitiesDialog(facilities);
        }
      } else {
        _showErrorDialog('Facility not found (Status: ${response.statusCode})');
      }
    } catch (e) {
      _showErrorDialog('Error searching facility: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showMultipleFacilitiesDialog(List<dynamic> facilities) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Found ${facilities.length} Facilities'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: facilities.length,
            itemBuilder: (context, index) {
              final facility = facilities[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    facility['facilityName'] ?? 'N/A',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${facility['location']?['city'] ?? 'N/A'}, ${facility['location']?['country'] ?? 'N/A'}',
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showFacilityDialog(facility);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFacilityDialog(Map<String, dynamic> facility) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.apartment, color: Colors.green),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Facility Details',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Facility Image
              if (facility['image'] != null && facility['image'].toString().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    facility['image'],
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 50),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              
              // Facility Name
              _buildDetailRow('Name:', facility['facilityName'] ?? 'N/A'),
              const Divider(),
              
              // Description
              if (facility['description'] != null)
                _buildDetailRow('Description:', facility['description']),
              if (facility['description'] != null) const Divider(),
              
              // Email
              _buildClickableRow(
                'Email:',
                facility['email'] ?? 'N/A',
                icon: Icons.email,
                onTap: () => _launchURL('mailto:${facility['email']}'),
              ),
              const Divider(),
              
              // Phone
              _buildClickableRow(
                'Phone:',
                facility['phoneNumber'] ?? 'N/A',
                icon: Icons.phone,
                onTap: () => _launchURL('tel:${facility['phoneNumber']}'),
              ),
              const Divider(),
              
              // Website
              if (facility['website'] != null)
                _buildClickableRow(
                  'Website:',
                  facility['website'],
                  icon: Icons.language,
                  onTap: () => _launchURL(facility['website']),
                ),
              if (facility['website'] != null) const Divider(),
              
              // Location Section
              _buildSectionHeader('Location'),
              _buildDetailRow('Address:', facility['location']?['address'] ?? 'N/A'),
              _buildDetailRow('City:', facility['location']?['city'] ?? 'N/A'),
              _buildDetailRow('State:', facility['location']?['state'] ?? 'N/A'),
              _buildDetailRow('Country:', facility['location']?['country'] ?? 'N/A'),
              const Divider(),
              
              // Established Year
              if (facility['establishedYear'] != null)
                _buildDetailRow('Established:', facility['establishedYear'].toString()),
              if (facility['establishedYear'] != null) const Divider(),
              
              // Status
              _buildStatusRow(
                'Status:',
                facility['isActive'] == true ? 'Active' : 'Inactive',
                facility['isActive'] == true ? Colors.green : Colors.red,
              ),
              const Divider(),
              
              // Timestamps
              _buildDetailRow('Created:', _formatDate(facility['createdAt'])),
              _buildDetailRow('Updated:', _formatDate(facility['updatedAt'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    ).then((_) {
      // Clear the field after dialog is closed
      _nameController.clear();
    });
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableRow(String label, String value, {IconData? icon, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        color: onTap != null ? Colors.blue : Colors.black,
                        decoration: onTap != null ? TextDecoration.underline : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Icon(
            value == 'Active' ? Icons.check_circle : Icons.cancel,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Facility by Name'),
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
                        Icons.search,
                        size: 48,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Search for a Facility',
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
                          prefixIcon: Icon(Icons.apartment),
                          hintText: 'e.g., Centre for Learning',
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter a facility name' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _searchFacility,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Search Facility',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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