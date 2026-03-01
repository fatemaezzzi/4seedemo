import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/shared_widgets.dart';

enum UserRole { student, teacher, admin }

class EditPersonalInfoPage extends StatefulWidget {
  final UserRole role;
  const EditPersonalInfoPage({required this.role, super.key});

  @override
  State<EditPersonalInfoPage> createState() => _EditPersonalInfoPageState();
}

class _EditPersonalInfoPageState extends State<EditPersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();

  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = _fieldsForRole().map(
          (key, value) => MapEntry(key, TextEditingController(text: value)),
    );
  }

  Map<String, String> _fieldsForRole() {
    switch (widget.role) {
      case UserRole.student:
        return {
          'Full Name': 'Rohan Sharma',
          'Date of Birth': '11/02/2007',
          'Phone Number': '+91 98765 43210',
          'Email': 'rohan.sharma@school.edu',
          "Mother's Name": 'Sunita Sharma',
          "Father's Name": 'Ramesh Sharma',
          'Address': '12, MG Road, Mumbai',
          'Emergency Contact': '+91 98000 00000',
        };
      case UserRole.teacher:
        return {
          'Full Name': 'Niti Patel',
          'Employee ID': 'TCH-2024-047',
          'Phone Number': '+91 99887 76655',
          'Email': 'niti.patel@school.edu',
          'Designation': 'Senior Teacher',
          'Department': 'Science',
          'Qualification': 'M.Sc, B.Ed',
          'Address': '45, Shivaji Nagar, Pune',
        };
      case UserRole.admin:
        return {
          'Full Name': 'Admin Name',
          'Admin ID': 'ADM-2024-001',
          'Phone Number': '+91 99000 11223',
          'Email': 'admin@schoolname.edu',
          'School Name': 'Springfield High School',
          'Designation': 'Principal',
          'Address': '1, School Road, Delhi',
          'Office Extension': '0110-234567',
        };
    }
  }

  List<String> get _readOnlyFields {
    switch (widget.role) {
      case UserRole.student:
        return ['Date of Birth'];
      case UserRole.teacher:
        return ['Employee ID'];
      case UserRole.admin:
        return ['Admin ID'];
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit Personal Information')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Avatar with edit button
              Center(
                child: Stack(
                  children: [
                    const CircleAvatar(
                      radius: 48,
                      backgroundColor: Color(0xFFB8C8D0),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: AppColors.accent, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              ..._controllers.entries.map((entry) => EditableField(
                label: entry.key.toUpperCase(),
                initialValue: entry.value.text,
                controller: entry.value,
                readOnly: _readOnlyFields.contains(entry.key),
                keyboardType: entry.key.contains('Phone') || entry.key.contains('Extension')
                    ? TextInputType.phone
                    : entry.key == 'Email'
                    ? TextInputType.emailAddress
                    : TextInputType.text,
              )),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Save Changes',
                icon: Icons.check,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully!')),
                  );
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}