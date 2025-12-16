import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isSubmitting = false;

  // Pricing
  double _priceMin = 100;
  double _priceMax = 1000;
  String _currency = 'GHS';

  // Categories
  final List<String> _categories = [
    'Plumbing', 'Electrical', 'Carpentry', 'Painting', 'Cleaning', 'Gardening',
    'Hairdressing', 'Tailoring', 'Tutoring', 'Photography', 'Catering', 'Baking',
    'IT Support', 'Mechanic', 'Graphic Design', 'Web Development', 'Mobile App Development',
    'Event Planning', 'Interior Design', 'Fitness Training', 'Massage Therapy',
    'Pet Care', 'Housekeeping', 'Delivery Services',
  ];
  String? _selectedCategory;

  // Images
  List<Map<String, dynamic>> _images = []; // {'file': File, 'uploading': bool, 'url': ''}

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // Pick image
  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    final file = File(picked.path);

    setState(() {
      _images.add({'file': file, 'uploading': true, 'url': ''});
    });

    _uploadImage(_images.length - 1);
  }

  // Upload image to Firebase Storage
  Future<void> _uploadImage(int index) async {
    try {
      final file = _images[index]['file'] as File;
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('posts/$fileName');
      final uploadTask = ref.putFile(file);

      uploadTask.snapshotEvents.listen((event) {
        setState(() {
          _images[index]['progress'] =
              event.totalBytes > 0 ? event.bytesTransferred / event.totalBytes : 0;
        });
      });

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();

      setState(() {
        _images[index]['url'] = url;
        _images[index]['uploading'] = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
      setState(() => _images.removeAt(index));
    }
  }

  // Submit post
  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    if (_images.isEmpty || _images.any((img) => img['uploading'] == true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all images first')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('createPost');

      final pricingRange = '$_currency ${_priceMin.toInt()} - ${_priceMax.toInt()}';

      final result = await callable.call(<String, dynamic>{
        'serviceCategory': _selectedCategory!.trim(),
        'description': _descriptionController.text.trim(),
        'pricing': pricingRange,
        'images': _images.map((e) => {'url': e['url'], 'label': ''}).toList(),
      });

      if (result.data['success'] == true) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      // Handle artisan role error and other errors gracefully
      String message = e.message ?? 'Something went wrong';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create post: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Service Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(value: category, child: Text(category));
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedCategory = value),
                        validator: (value) =>
                            value == null ? 'Please select a category' : null,
                      ),
                      SizedBox(height: 2.h),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        maxLines: 3,
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter description' : null,
                      ),
                      SizedBox(height: 2.h),

                      // Pricing
                      Text('Pricing ($_currency): ${_priceMin.toInt()} - ${_priceMax.toInt()}'),
                      RangeSlider(
                        values: RangeValues(_priceMin, _priceMax),
                        min: 0,
                        max: 10000,
                        divisions: 100,
                        labels: RangeLabels(
                          _priceMin.toInt().toString(),
                          _priceMax.toInt().toString(),
                        ),
                        onChanged: (values) {
                          setState(() {
                            _priceMin = values.start;
                            _priceMax = values.end;
                          });
                        },
                      ),
                      Row(
                        children: [
                          const Text('Currency:'),
                          SizedBox(width: 4.w),
                          DropdownButton<String>(
                            value: _currency,
                            items: <String>['GHS', 'USD', 'EUR']
                                .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                                .toList(),
                            onChanged: (value) => setState(() => _currency = value!),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),

                      // Images Grid
                      Wrap(
                        spacing: 2.w,
                        runSpacing: 2.w,
                        children: [
                          ..._images.map((img) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    img['file'],
                                    width: 30.w,
                                    height: 30.w,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                if (img['uploading'])
                                  Container(
                                    width: 30.w,
                                    height: 30.w,
                                    color: Colors.black38,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: img['progress'],
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _images.remove(img)),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 30.w,
                              height: 30.w,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add_a_photo, size: 32, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitPost,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isSubmitting
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Post', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
