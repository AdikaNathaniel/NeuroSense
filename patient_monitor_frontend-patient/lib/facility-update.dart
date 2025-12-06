import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

// Only import dart:io on non-web platforms
import 'dart:io' as io show File;

class UpdateFacilityPage extends StatefulWidget {
  const UpdateFacilityPage({Key? key}) : super(key: key);

  @override
  _UpdateFacilityPageState createState() => _UpdateFacilityPageState();
}

class _UpdateFacilityPageState extends State<UpdateFacilityPage> {
  final _formKey = GlobalKey<FormState>();
  
  // For mobile platforms
  io.File? _imageFile;
  
  // For web platform
  Uint8List? _webImage;
  String? _imageName;
  
  // Track whether user wants to upload image or provide URL
  bool _useImageUrl = false;
  
  final picker = ImagePicker();

  // Controllers
  final facilityNameController = TextEditingController();
  final imageUrlController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final countryController = TextEditingController();
  final descriptionController = TextEditingController();
  final websiteController = TextEditingController();
  final establishedYearController = TextEditingController();

  // Track which fields user wants to update
  final Map<String, bool> _fieldsToUpdate = {
    'image': false,
    'email': false,
    'phoneNumber': false,
    'address': false,
    'city': false,
    'state': false,
    'country': false,
    'description': false,
    'website': false,
    'establishedYear': false,
    'isActive': false,
  };

  bool? _isActive;
  bool isSubmitting = false;
  bool isSearching = false;

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
          _imageName = pickedFile.name;
          _useImageUrl = false;
          _fieldsToUpdate['image'] = true;
        });
      } else {
        setState(() {
          _imageFile = io.File(pickedFile.path);
          _useImageUrl = false;
          _fieldsToUpdate['image'] = true;
        });
      }
    }
  }

  Future<void> _searchFacility() async {
    if (facilityNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a facility name to search'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isSearching = true);

    try {
      final searchQuery = Uri.encodeComponent(facilityNameController.text.trim());
      final response = await http.get(
        Uri.parse('https://neurosense-palsy.fly.dev/api/v1/facilities/search?q=$searchQuery'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final facilities = data['result'] as List<dynamic>;
        
        if (facilities.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No facility found with that name'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (facilities.length == 1) {
          _showConfirmDialog(facilities[0]);
        } else {
          _showMultipleFacilitiesDialog(facilities);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Facility not found (Status: ${response.statusCode})'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching facility: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isSearching = false);
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
                    _showConfirmDialog(facility);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(Map<String, dynamic> facility) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Facility'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You are about to update:'),
            const SizedBox(height: 12),
            Text(
              facility['facilityName'] ?? 'N/A',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${facility['location']?['city'] ?? 'N/A'}, ${facility['location']?['country'] ?? 'N/A'}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Facility found! Select fields to update below.'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if at least one field is selected for update
    if (!_fieldsToUpdate.values.any((element) => element)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one field to update'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final facilityName = Uri.encodeComponent(facilityNameController.text.trim());
      final uri = Uri.parse('https://neurosense-palsy.fly.dev/api/v1/facilities/$facilityName');
      
      // Build update payload with only selected fields
      Map<String, dynamic> updateData = {};

      if (_fieldsToUpdate['image'] == true) {
        if (_useImageUrl && imageUrlController.text.isNotEmpty) {
          updateData['image'] = imageUrlController.text.trim();
        }
        // Note: For file upload in update, you'd need multipart - keeping URL for simplicity
      }

      if (_fieldsToUpdate['email'] == true && emailController.text.isNotEmpty) {
        updateData['email'] = emailController.text.trim();
      }

      if (_fieldsToUpdate['phoneNumber'] == true && phoneController.text.isNotEmpty) {
        updateData['phoneNumber'] = phoneController.text.trim();
      }

      if (_fieldsToUpdate['description'] == true && descriptionController.text.isNotEmpty) {
        updateData['description'] = descriptionController.text.trim();
      }

      if (_fieldsToUpdate['website'] == true && websiteController.text.isNotEmpty) {
        updateData['website'] = websiteController.text.trim();
      }

      if (_fieldsToUpdate['establishedYear'] == true && establishedYearController.text.isNotEmpty) {
        updateData['establishedYear'] = int.tryParse(establishedYearController.text.trim());
      }

      if (_fieldsToUpdate['isActive'] == true && _isActive != null) {
        updateData['isActive'] = _isActive;
      }

      // Handle location updates
      Map<String, String> location = {};
      if (_fieldsToUpdate['address'] == true && addressController.text.isNotEmpty) {
        location['address'] = addressController.text.trim();
      }
      if (_fieldsToUpdate['city'] == true && cityController.text.isNotEmpty) {
        location['city'] = cityController.text.trim();
      }
      if (_fieldsToUpdate['state'] == true && stateController.text.isNotEmpty) {
        location['state'] = stateController.text.trim();
      }
      if (_fieldsToUpdate['country'] == true && countryController.text.isNotEmpty) {
        location['country'] = countryController.text.trim();
      }

      if (location.isNotEmpty) {
        updateData['location'] = location;
      }

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        await _showSuccessDialog();
        _resetForm();
      } else {
        final responseBody = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${responseBody['message'] ?? 'Update failed'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _showSuccessDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Icon(Icons.check_circle, color: Colors.green, size: 60),
                SizedBox(height: 20),
                Text('Facility updated successfully!'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    facilityNameController.clear();
    imageUrlController.clear();
    emailController.clear();
    phoneController.clear();
    addressController.clear();
    cityController.clear();
    stateController.clear();
    countryController.clear();
    descriptionController.clear();
    websiteController.clear();
    establishedYearController.clear();
    
    setState(() {
      _imageFile = null;
      _webImage = null;
      _imageName = null;
      _useImageUrl = false;
      _isActive = null;
      _fieldsToUpdate.updateAll((key, value) => false);
    });
  }

  Widget _buildImageWidget() {
    if (_useImageUrl) {
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.green[100],
        child: const Icon(Icons.link, size: 40, color: Colors.green),
      );
    }
    
    if (kIsWeb && _webImage != null) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: MemoryImage(_webImage!),
      );
    } else if (!kIsWeb && _imageFile != null) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: FileImage(_imageFile!),
      );
    } else {
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.grey[300],
        child: const Icon(Icons.business, size: 60, color: Colors.grey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Facility'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Section
              Card(
                elevation: 3,
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.search, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Step 1: Find Facility',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: facilityNameController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.business),
                          labelText: 'Facility Name',
                          hintText: 'Enter facility name to search',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) => 
                            value == null || value.isEmpty ? 'This field is required' : null,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isSearching ? null : _searchFacility,
                          icon: isSearching 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search),
                          label: Text(isSearching ? 'Searching...' : 'Search Facility'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Update Fields Section
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.edit, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Step 2: Select Fields to Update',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check the boxes for fields you want to update',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Image Update
                      _buildUpdateCheckbox('image', 'Update Image'),
                      if (_fieldsToUpdate['image'] == true) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: Stack(
                            children: [
                              _buildImageWidget(),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                                    onPressed: _pickImage,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ChoiceChip(
                                label: const Text('Upload Image'),
                                selected: !_useImageUrl,
                                onSelected: (selected) {
                                  setState(() => _useImageUrl = !selected);
                                },
                                selectedColor: Colors.green[100],
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('Use Image URL'),
                                selected: _useImageUrl,
                                onSelected: (selected) {
                                  setState(() => _useImageUrl = selected);
                                },
                                selectedColor: Colors.green[100],
                              ),
                            ],
                          ),
                        ),
                        if (_useImageUrl) ...[
                          const SizedBox(height: 12),
                          _buildTextField(
                            imageUrlController,
                            "Image URL",
                            Icons.link,
                            keyboardType: TextInputType.url,
                            hintText: 'https://example.com/image.jpg',
                            isOptional: true,
                          ),
                        ],
                      ],
                      
                      const Divider(height: 32),
                      
                      // Email
                      _buildUpdateCheckbox('email', 'Update Email'),
                      if (_fieldsToUpdate['email'] == true)
                        _buildTextField(
                          emailController,
                          "Email",
                          Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          isOptional: true,
                        ),
                      
                      // Phone
                      _buildUpdateCheckbox('phoneNumber', 'Update Phone Number'),
                      if (_fieldsToUpdate['phoneNumber'] == true)
                        _buildTextField(
                          phoneController,
                          "Phone Number",
                          Icons.phone,
                          keyboardType: TextInputType.phone,
                          isOptional: true,
                        ),
                      
                      const Divider(height: 32),
                      
                      // Location Section
                      const Text(
                        'Location Updates',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      _buildUpdateCheckbox('address', 'Update Address'),
                      if (_fieldsToUpdate['address'] == true)
                        _buildTextField(
                          addressController,
                          "Address",
                          Icons.location_on,
                          isOptional: true,
                        ),
                      
                      _buildUpdateCheckbox('city', 'Update City'),
                      if (_fieldsToUpdate['city'] == true)
                        _buildTextField(
                          cityController,
                          "City",
                          Icons.location_city,
                          isOptional: true,
                        ),
                      
                      _buildUpdateCheckbox('state', 'Update State/Region'),
                      if (_fieldsToUpdate['state'] == true)
                        _buildTextField(
                          stateController,
                          "State/Region",
                          Icons.map,
                          isOptional: true,
                        ),
                      
                      _buildUpdateCheckbox('country', 'Update Country'),
                      if (_fieldsToUpdate['country'] == true)
                        _buildTextField(
                          countryController,
                          "Country",
                          Icons.public,
                          isOptional: true,
                        ),
                      
                      const Divider(height: 32),
                      
                      // Other Fields
                      _buildUpdateCheckbox('description', 'Update Description'),
                      if (_fieldsToUpdate['description'] == true)
                        _buildTextField(
                          descriptionController,
                          "Description",
                          Icons.description,
                          maxLines: 3,
                          keyboardType: TextInputType.multiline,
                          isOptional: true,
                        ),
                      
                      _buildUpdateCheckbox('website', 'Update Website'),
                      if (_fieldsToUpdate['website'] == true)
                        _buildTextField(
                          websiteController,
                          "Website",
                          Icons.language,
                          keyboardType: TextInputType.url,
                          hintText: 'https://example.com',
                          isOptional: true,
                        ),
                      
                      _buildUpdateCheckbox('establishedYear', 'Update Established Year'),
                      if (_fieldsToUpdate['establishedYear'] == true)
                        _buildTextField(
                          establishedYearController,
                          "Year Established",
                          Icons.calendar_today,
                          keyboardType: TextInputType.number,
                          hintText: 'e.g., 2012',
                          isOptional: true,
                        ),
                      
                      const Divider(height: 32),
                      
                      // Active Status
                      _buildUpdateCheckbox('isActive', 'Update Active Status'),
                      if (_fieldsToUpdate['isActive'] == true) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.power_settings_new),
                                  const SizedBox(width: 12),
                                  const Text('Facility Status:'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    ChoiceChip(
                                      label: const Text('Active'),
                                      selected: _isActive == true,
                                      onSelected: (selected) {
                                        setState(() => _isActive = true);
                                      },
                                      selectedColor: Colors.green[100],
                                    ),
                                    const SizedBox(width: 8),
                                    ChoiceChip(
                                      label: const Text('Inactive'),
                                      selected: _isActive == false,
                                      onSelected: (selected) {
                                        setState(() => _isActive = false);
                                      },
                                      selectedColor: Colors.red[100],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Submit Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isSubmitting ? null : _submitForm,
                icon: isSubmitting 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.update),
                label: Text(isSubmitting ? 'Updating...' : 'Update Facility'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateCheckbox(String field, String label) {
    return CheckboxListTile(
      value: _fieldsToUpdate[field],
      onChanged: (value) {
        setState(() {
          _fieldsToUpdate[field] = value ?? false;
        });
      },
      title: Text(label),
      activeColor: Colors.green,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hintText,
    bool isOptional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.green, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: isOptional
            ? null
            : (value) => value == null || value.isEmpty ? 'This field is required' : null,
      ),
    );
  }

  @override
  void dispose() {
    facilityNameController.dispose();
    imageUrlController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    countryController.dispose();
    descriptionController.dispose();
    websiteController.dispose();
    establishedYearController.dispose();
    super.dispose();
  }
}