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
  
  // Store the uploaded image URL
  String? _uploadedImageUrl;
  
  // Track whether user wants to upload image or provide URL
  bool _useImageUrl = false;
  
  // Track if image is being uploaded
  bool _isUploadingImage = false;
  
  final picker = ImagePicker();

  // ImgBB API Key - You need to get this from https://api.imgbb.com/



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
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _isUploadingImage = true;
        });

        // Read the image bytes
        final bytes = await pickedFile.readAsBytes();
        
        // Upload to ImgBB and get URL
        final imageUrl = await _uploadImageToImgBB(bytes, pickedFile.name);
        
        if (imageUrl != null) {
          setState(() {
            if (kIsWeb) {
              _webImage = bytes;
              _imageName = pickedFile.name;
            } else {
              _imageFile = io.File(pickedFile.path);
            }
            _uploadedImageUrl = imageUrl;
            _useImageUrl = false;
            _isUploadingImage = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image uploaded successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          setState(() {
            _isUploadingImage = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to upload image. Please try again or use Image URL.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImageToImgBB(Uint8List imageBytes, String fileName) async {
    try {
      // Convert image bytes to base64
      final base64Image = base64Encode(imageBytes);
      
      // ImgBB upload endpoint
      final uri = Uri.parse('https://api.imgbb.com/1/upload');
      
      final response = await http.post(
        uri,
        body: {
          'key': _imgbbApiKey,
          'image': base64Image,
          'name': fileName,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Return the direct image URL
          return data['data']['url'] as String;
        }
      }
      
      print('ImgBB upload failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Error uploading to ImgBB: $e');
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate that we have an image (either uploaded or URL provided)
    String? finalImageUrl;
    
    if (_useImageUrl) {
      // User provided URL directly
      if (imageUrlController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide an image URL'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      finalImageUrl = imageUrlController.text.trim();
    } else {
      // User uploaded image
      if (_uploadedImageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload an image first'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      finalImageUrl = _uploadedImageUrl;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final uri = Uri.parse('https://neurosense-palsy.fly.dev/api/v1/facilities');
      
      // Validate and parse established year
      int? establishedYear;
      if (establishedYearController.text.trim().isNotEmpty) {
        establishedYear = int.tryParse(establishedYearController.text.trim());
        if (establishedYear == null) {
          throw Exception('Invalid year format');
        }
      }
      
      // Prepare the JSON body exactly as the API expects
      final Map<String, dynamic> body = {
        'facilityName': facilityNameController.text.trim(),
        'image': finalImageUrl,
        'email': emailController.text.trim(),
        'phoneNumber': phoneController.text.trim(),
        'location': {
          'address': addressController.text.trim(),
          'city': cityController.text.trim(),
          'state': stateController.text.trim(),
          'country': countryController.text.trim(),
        },
        'description': descriptionController.text.trim(),
        'website': websiteController.text.trim(),
      };

      // Only add establishedYear if it's valid
      if (establishedYear != null) {
        body['establishedYear'] = establishedYear;
      }

      print('Sending request to: $uri');
      print('Request body: ${jsonEncode(body)}');

      // Send as JSON with proper headers
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Parse response
        final responseData = jsonDecode(response.body);
        
        // Show success dialog
        if (mounted) {
          await _showSuccessDialog(responseData);
          _resetForm();
        }
      } else {
        // Try to parse error message
        String errorMessage = 'Error: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'].toString();
          }
        } catch (e) {
          errorMessage += ' - ${response.body}';
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('Exception occurred: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  Future<void> _showSuccessDialog(Map<String, dynamic>? responseData) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Icon(Icons.check_circle, color: Colors.green, size: 60),
                const SizedBox(height: 20),
                const Text('Facility Profile Successfully submitted!'),
                if (responseData != null && responseData['result'] != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Facility ID: ${responseData['result']['_id']}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
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
      _uploadedImageUrl = null;
      _useImageUrl = false;
    });
  }

  Widget _buildImageWidget() {
    // Show loading indicator when uploading
    if (_isUploadingImage) {
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.grey[300],
        child: const CircularProgressIndicator(strokeWidth: 3),
      );
    }

    // If user uploaded image, show it
    if (!_useImageUrl && _uploadedImageUrl != null) {
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
      }
    }
    
    // If user provided URL and has entered one, try to show preview
    if (_useImageUrl && imageUrlController.text.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.grey[300],
        child: ClipOval(
          child: Image.network(
            imageUrlController.text.trim(),
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.link, size: 40, color: Colors.orange);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            },
          ),
        ),
      );
    }
    
    // Default placeholder
    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.grey[300],
      child: const Icon(Icons.business, size: 60, color: Colors.grey),
    );
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
                            if (!_useImageUrl && !_isUploadingImage)
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
                      
                      // Toggle between image upload and URL
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
                              selectedColor: Colors.orange[100],
                            ),
                          ],
                        ),
                      ),
                      
                      // Only show URL field if user selects "Use Image URL"
                      if (_useImageUrl) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: imageUrlController,
                          keyboardType: TextInputType.url,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.link),
                            labelText: 'Image URL *',
                            hintText: 'https://example.com/image.jpg',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.orange, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.orange[50],
                          ),
                          validator: (value) {
                            if (_useImageUrl) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Image URL is required';
                              }
                              if (!value.trim().startsWith('http')) {
                                return 'Please enter a valid URL starting with http:// or https://';
                              }
                            }
                            return null;
                          },
                          onChanged: (value) {
                            // Trigger rebuild to show image preview
                            setState(() {});
                          },
                        ),
                      ],
                      
                      // Helper text
                      const SizedBox(height: 12),
                      Text(
                        _useImageUrl 
                          ? 'Paste a direct link to your facility image'
                          : _uploadedImageUrl != null
                              ? '✓ Image uploaded successfully'
                              : 'Click the camera button to upload an image',
                        style: TextStyle(
                          color: _uploadedImageUrl != null ? Colors.green : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: _uploadedImageUrl != null ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      if (_isUploadingImage) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Uploading image...',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Facility Information Fields
              _buildTextField(
                facilityNameController, 
                "Facility Name", 
                Icons.business,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Facility name is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Facility name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              
              _buildTextField(
                emailController, 
                "Email", 
                Icons.email, 
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              
              _buildTextField(
                phoneController, 
                "Phone Number", 
                Icons.phone, 
                keyboardType: TextInputType.phone,
                hintText: '+233200000000',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  if (value.trim().length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              
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
              
              _buildTextField(
                descriptionController, 
                "Description", 
                Icons.description,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),
              
              _buildTextField(
                websiteController, 
                "Website", 
                Icons.language,
                keyboardType: TextInputType.url,
                hintText: 'https://example.com',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Website is required';
                  }
                  if (!value.trim().startsWith('http')) {
                    return 'Website must start with http:// or https://';
                  }
                  return null;
                },
              ),
              
              _buildTextField(
                establishedYearController, 
                "Year Established", 
                Icons.calendar_today,
                keyboardType: TextInputType.number,
                hintText: 'e.g., 2012',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Year is required';
                  }
                  final year = int.tryParse(value.trim());
                  if (year == null) {
                    return 'Please enter a valid year';
                  }
                  if (year < 1900 || year > DateTime.now().year) {
                    return 'Please enter a valid year between 1900 and ${DateTime.now().year}';
                  }
                  return null;
                },
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
                onPressed: (isSubmitting || _isUploadingImage) ? null : _submitForm,
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Submit Profile",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
      String? Function(String?)? validator,
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
        validator: validator ?? (value) {
          if (value == null || value.trim().isEmpty) {
            return 'This field is required';
          }
          return null;
        },
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