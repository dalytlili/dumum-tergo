import 'package:country_picker/country_picker.dart';
import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/services/auth_service.dart';
import 'package:dumum_tergo/services/logout_service.dart';
import 'package:dumum_tergo/views/user/auth/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dumum_tergo/viewmodels/seller/EditProfileSellerViewModel.dart';
import 'dart:io';

class EditProfileSellerView extends StatefulWidget {
  const EditProfileSellerView({super.key});

  @override
  _EditProfileSellerViewState createState() => _EditProfileSellerViewState();
}

class _EditProfileSellerViewState extends State<EditProfileSellerView> {
  final LogoutService _logoutService = LogoutService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EditProfileSellerViewModel>(context, listen: false).fetchProfileData();
    });
  }

  Future<void> _refreshData() async {
    await Provider.of<EditProfileSellerViewModel>(context, listen: false).fetchProfileData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final viewModel = Provider.of<EditProfileSellerViewModel>(context, listen: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Modifier le profil',
         
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refreshData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05,
            vertical: 30.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildProfileImage(viewModel, isDarkMode),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                     TextSpan(text: 'Temps restant avant expiration : ',style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
),
                    TextSpan(
                      text: viewModel.remainingSubscriptionTime,
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: viewModel.nameController,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Nom',
                  labelStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  fillColor: isDarkMode ? Colors.grey[800]! : Colors.grey[50]!,
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: viewModel.adressController,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Adresse',
                  labelStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  fillColor: isDarkMode ? Colors.grey[800]! : Colors.grey[50]!,
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: viewModel.emailController,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  fillColor: isDarkMode ? Colors.grey[800]! : Colors.grey[50]!,
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: viewModel.descriptionController,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  fillColor: isDarkMode ? Colors.grey[800]! : Colors.grey[50]!,
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: viewModel.phoneNumberController,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Numéro de téléphone',
                  hintStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[500]),
                  labelStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                  prefixIcon: InkWell(
                    onTap: () {
                      showCountryPicker(
                        context: context,
                        showPhoneCode: true,
                        onSelect: (Country country) {
                          setState(() {
                            viewModel.selectedCountry = country;
                          });
                        },
                        countryListTheme: CountryListThemeData(
                          backgroundColor: isDarkMode ? Colors.grey[900]! : Colors.white,
                          textStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            viewModel.selectedCountry.flagEmoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+${viewModel.selectedCountry.phoneCode}',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_drop_down,
                            color: isDarkMode ? Colors.white70 : Colors.grey[700],
                          ),
                        ],
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  fillColor: isDarkMode ? Colors.grey[800]! : Colors.grey[50]!,
                  filled: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre numéro de téléphone';
                  }
                  if (!RegExp(r'^\d+$').hasMatch(value)) {
                    return 'Veuillez entrer un numéro valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: viewModel.isLoading
                      ? null
                      : () async {
                          await viewModel.updateProfile(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                  ),
                  child: viewModel.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Enregistrer', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(EditProfileSellerViewModel viewModel, bool isDarkMode) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          backgroundImage: _getImage(viewModel.imageUrlController.text),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDarkMode ? Colors.grey[900]! : Colors.white,
              width: 2,
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.edit, color: Colors.white, size: 20),
            onPressed: () async {
              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                viewModel.imageUrlController.text = pickedFile.path;
                viewModel.notifyListeners();
              }
            },
          ),
        ),
      ],
    );
  }

  ImageProvider _getImage(String imageUrl) {
    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        return NetworkImage(imageUrl);
      } else {
        final file = File(imageUrl);
        if (file.existsSync()) {
          return FileImage(file);
        } else {
          return const AssetImage('assets/images/default.png');
        }
      }
    } else {
      return const AssetImage('assets/images/default.png');
    }
  }
}