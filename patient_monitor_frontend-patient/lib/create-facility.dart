import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

// Only import dart:io on non-web platforms
import 'dart:io' as io show File;

class FacilityProfilePage extends StatefulWidget {
  const FacilityProfilePage({Key? key}) : super(key: key);

  @override
  _FacilityProfilePageState createState() => _FacilityProfilePageState();
}

class _FacilityProfilePageState extends State<FacilityProfilePage> {
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

  bool isSubmitting = false;

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      if (kIsWeb) {
        // For web platform
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
          _imageName = pickedFile.name;
          _useImageUrl = false; // Switch to image upload mode
        });
      } else {
        // For mobile platforms
        setState(() {
          _imageFile = io.File(pickedFile.path);
          _useImageUrl = false; // Switch to image upload mode
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final uri = Uri.parse('https://neurosense-palsy.fly.dev/api/v1/facilities');
      final request = http.MultipartRequest('POST', uri);

      String? imageUrl;
      
      // Handle image - either upload file or use provided URL
      if (!_useImageUrl && ((kIsWeb && _webImage != null) || (!kIsWeb && _imageFile != null))) {
        // Upload image file
        if (kIsWeb && _webImage != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              _webImage!,
              filename: _imageName ?? 'facility_image.jpg',
            ),
          );
        } else if (!kIsWeb && _imageFile != null) {
          request.files.add(
            await http.MultipartFile.fromPath('image', _imageFile!.path),
          );
        }
      } else if (_useImageUrl && imageUrlController.text.isNotEmpty) {
        // Use provided URL
        request.fields['image'] = imageUrlController.text.trim();
      }

      // Prepare location object
      final location = {
        'address': addressController.text.trim(),
        'city': cityController.text.trim(),
        'state': stateController.text.trim(),
        'country': countryController.text.trim(),
      };

      // Add form fields
      request.fields.addAll({
        'facilityName': facilityNameController.text.trim(),
        'email': emailController.text.trim(),
        'phoneNumber': phoneController.text.trim(),
        'description': descriptionController.text.trim(),
        'website': websiteController.text.trim(),
        'establishedYear': establishedYearController.text.trim(),
        'location[address]': location['address']!,
        'location[city]': location['city']!,
        'location[state]': location['state']!,
        'location[country]': location['country']!,
      });

      final response = await request.send();
      
      if (response.statusCode == 201) {
        // Show success dialog
        await _showSuccessDialog();
        _resetForm();
      } else {
        final responseBody = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response.statusCode} - $responseBody'),
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
                Text('Facility Profile Successfully submitted!'),
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
    });
  }

  Widget _buildImageWidget() {
    // If user wants to use URL, show placeholder
    if (_useImageUrl) {
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.green[100],
        child: const Icon(Icons.link, size: 40, color: Colors.green),
      );
    }
    
    // Show uploaded image
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
      // Default placeholder
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
        title: const Text('Create Facility Profile'),
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
              // Image upload section
              Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Image preview
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
                      
                      const SizedBox(height: 16),
                      
                      // Toggle between image upload and URL - Fixed overflow
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ChoiceChip(
                              label: const Text('Upload Image'),
                              selected: !_useImageUrl,
                              onSelected: (selected) {
                                setState(() {
                                  _useImageUrl = !selected;
                                });
                              },
                              selectedColor: Colors.green[100],
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Use Image URL'),
                              selected: _useImageUrl,
                              onSelected: (selected) {
                                setState(() {
                                  _useImageUrl = selected;
                                });
                              },
                              selectedColor: Colors.green[100],
                            ),
                          ],
                        ),
                      ),
                      
                      // Image URL field (only shown when using URL)
                      if (_useImageUrl) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: imageUrlController,
                          keyboardType: TextInputType.url,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.link),
                            labelText: 'Image URL',
                            hintText: 'https://example.com/image.jpg',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.green, width: 2),
                            ),
                          ),
                          validator: _useImageUrl ? (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please provide an image URL';
                            }
                            if (!value.startsWith('http')) {
                              return 'Please enter a valid URL';
                            }
                            return null;
                          } : null,
                        ),
                      ],
                      
                      // Helper text
                      const SizedBox(height: 8),
                      Text(
                        _useImageUrl 
                          ? 'Provide a direct link to your facility image'
                          : 'Upload a photo of your facility',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Facility Information Fields
              _buildTextField(facilityNameController, "Facility Name", Icons.business),
              _buildTextField(emailController, "Email", Icons.email, keyboardType: TextInputType.emailAddress),
              _buildTextField(phoneController, "Phone Number", Icons.phone, keyboardType: TextInputType.phone),
              
              // Location Section
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Location Details",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(addressController, "Address", Icons.location_on),
                      _buildTextField(cityController, "City", Icons.location_city),
                      _buildTextField(stateController, "State/Region", Icons.map),
                      _buildTextField(countryController, "Country", Icons.public),
                    ],
                  ),
                ),
              ),
              
              _buildTextField(descriptionController, "Description", Icons.description,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),
              
              _buildTextField(websiteController, "Website", Icons.language,
                keyboardType: TextInputType.url,
                hintText: 'https://example.com',
              ),
              
              _buildTextField(establishedYearController, "Year Established", Icons.calendar_today,
                keyboardType: TextInputType.number,
                hintText: 'e.g., 2012',
              ),
              
              const SizedBox(height: 24),
              
              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isSubmitting ? null : _submitForm,
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Submit Profile"
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, 
    {
      TextInputType? keyboardType,
      int maxLines = 1,
      String? hintText,
    }
  ) {
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
        validator: (value) => value == null || value.isEmpty ? 'This field is required' : null,
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


// Link For CLCD-Ghana...Remove Ashaley Botwe,Ghana to just Ashaley Botwe

// https://images.squarespace-cdn.com/content/v1/5b297397b40b9d28eb5b78cf/1757646763275-WH6XJ70NZ1FKUG8QPFGB/DSC_0129ccclllcd.jpg?format=1500w