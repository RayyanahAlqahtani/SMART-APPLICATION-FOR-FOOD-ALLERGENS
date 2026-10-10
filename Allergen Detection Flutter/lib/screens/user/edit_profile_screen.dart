import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../models/allergen_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/allergen_service.dart';
import '../../widgets/common/custom_input_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  late TextEditingController _passwordController;
  final Set<String> _selectedAllergens = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _ageController =
        TextEditingController(text: widget.user.age?.toString() ?? '');
    _passwordController = TextEditingController();
    _selectedAllergens.addAll(widget.user.allergenList);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        if (_emailController.text.trim() != widget.user.email) {
          await authProvider.authService
              .updateEmail(_emailController.text.trim());
        }

        if (_passwordController.text.isNotEmpty) {
          await authProvider.authService
              .updatePassword(_passwordController.text);
        }

        final updatedUser = widget.user.copyWith(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          age: int.tryParse(_ageController.text.trim()),
          allergenList: _selectedAllergens.toList(),
        );

        await authProvider.saveUser(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Update Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title:
            const Text('Edit Profile', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  label: 'Full Name',
                  hint: 'Enter your name',
                  prefixIcon: Icons.person_outline,
                  controller: _nameController,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Age',
                  hint: 'Enter your age',
                  prefixIcon: Icons.calendar_today_outlined,
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
                      return 'Invalid age';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'New Password (Optional)',
                  hint: 'Leave blank to keep current',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  controller: _passwordController,
                  validator: (v) =>
                      v!.isNotEmpty && v.length < 6 ? 'Min 6 chars' : null,
                ),
                const SizedBox(height: 16),

                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_outlined,
                          color: Colors.grey),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Role',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(widget.user.role.toUpperCase(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  'Your Allergens',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select the ingredients you want to avoid:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                StreamBuilder<List<AllergenModel>>(
                  stream: AllergenService().getAllAllergens(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('No allergens available');
                    }

                    final allergens = snapshot.data!;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: allergens.map((allergen) {
                        final isSelected =
                            _selectedAllergens.contains(allergen.name);
                        return FilterChip(
                          label: Text(allergen.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedAllergens.add(allergen.name);
                              } else {
                                _selectedAllergens.remove(allergen.name);
                              }
                            });
                          },
                          selectedColor: AppTheme.dangerRed.withValues(alpha: 0.2),
                          checkmarkColor: AppTheme.dangerRed,
                          labelStyle: TextStyle(
                            color: isSelected ? AppTheme.dangerRed : AppTheme.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          backgroundColor: AppTheme.surface,
                          side: BorderSide(
                            color: isSelected
                                ? AppTheme.dangerRed
                                : AppTheme.textLight,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 32),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('SAVE CHANGES',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
