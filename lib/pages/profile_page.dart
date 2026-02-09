import 'package:flutter/material.dart';
import '../pages/login_page.dart';
import '../widgets/nav_bar.dart';
import '../theme/app_colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final int _currentIndex = 4;

  // Editable state
  bool _isEditing = false;

  final TextEditingController _nameController = TextEditingController(
    text: 'Sara Ahmed Al-harbi',
  );

  final TextEditingController _emailController = TextEditingController(
    text: 'sara241@gmail.com',
  );

  Color _avatarColor = const Color(0xFFE8E6E1);

  //  Settings
  String _language = 'English';
  bool _theme = false;
  bool _pushNoti = false;

  void _toggleEditSave() {
    if (_isEditing) {
      setState(() => _isEditing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully ✅')),
      );
    } else {
      setState(() => _isEditing = true);
    }
  }

  void _showAvatarColorPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _colorOption(const Color(0xFFE8E6E1)),
            _colorOption(const Color(0xFFDCC7AA)),
            _colorOption(const Color(0xFF1F2A44)),
            _colorOption(const Color(0xFF79926C)),
          ],
        ),
      ),
    );
  }

  Widget _colorOption(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() => _avatarColor = color);
        Navigator.pop(context);
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            children: [
              // Profile header
              Row(
                children: [
                  GestureDetector(
                    onTap: _isEditing ? _showAvatarColorPicker : null,
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _avatarColor, width: 2.5),
                      ),
                      child: CircleAvatar(
                        backgroundColor: _avatarColor,
                        child: const Icon(
                          Icons.person,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _isEditing
                            ? TextField(controller: _nameController)
                            : Text(
                                _nameController.text,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                        const SizedBox(height: 6),
                        _isEditing
                            ? TextField(controller: _emailController)
                            : Text(_emailController.text),
                      ],
                    ),
                  ),

                  GestureDetector(
                    onTap: _toggleEditSave,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent,
                      ),
                      child: Icon(
                        _isEditing ? Icons.check : Icons.edit,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Logout button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    'Log out',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              _MenuTile(
                icon: Icons.info_outline,
                title: 'About RAFIQ',
                onTap: () {},
              ),
              _MenuTile(
                icon: Icons.lock_outline,
                title: 'Security',
                onTap: () {},
              ),
              _MenuTile(
                icon: Icons.help_outline,
                title: 'Help Center',
                onTap: () {},
              ),
              _MenuTile(
                icon: Icons.camera_alt_outlined,
                title: 'Scanned landmarks',
                onTap: () {},
              ),

              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 14),

              Column(
                children: [
                  _SettingRow(
                    label: 'language',
                    trailing: DropdownButton<String>(
                      value: _language,
                      underline: const SizedBox(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'English',
                          child: Text('English'),
                        ),
                        DropdownMenuItem(
                          value: 'Arabic',
                          child: Text('Arabic'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _language = v!),
                    ),
                  ),

                  _SettingRow(
                    label: 'theme',
                    trailing: Switch(
                      value: _theme,
                      onChanged: (v) => setState(() => _theme = v),
                      thumbColor: WidgetStateProperty.all(Colors.white),
                      trackColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return const Color(0xFF79926C);
                        }
                        return const Color(0xFFEDEDED);
                      }),
                    ),
                  ),

                  _SettingRow(
                    label: 'push notification',
                    trailing: Switch(
                      value: _pushNoti,
                      onChanged: (v) => setState(() => _pushNoti = v),
                      thumbColor: WidgetStateProperty.all(Colors.white),
                      trackColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return const Color(0xFF79926C);
                        }
                        return const Color(0xFFEDEDED);
                      }),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: CustomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return;
          _navigate(index, context);
        },
      ),
    );
  }

  void _navigate(int index, BuildContext context) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/nearby');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/scan');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/mytrip');
        break;
    }
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Switch(
          value: value,
          onChanged: onChanged,
          thumbColor: WidgetStateProperty.all(Colors.white),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF79926C);
            }
            return const Color(0xFFEDEDED);
          }),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final Widget trailing;

  const _SettingRow({required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Row(
        children: [
          const SizedBox(width: 20),

          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          trailing,
        ],
      ),
    );
  }
}
