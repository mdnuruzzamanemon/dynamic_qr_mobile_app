import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            _buildHeader(),
            const Spacer(flex: 1),
            _buildInfoCards(auth),
            const Spacer(flex: 3),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, auth),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2D6A4F), Color(0xFF40916C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D6A4F).withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.qr_code_scanner_rounded,
            size: 46,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'SecureQR',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Scan & verify documents securely',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards(AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _infoCard(
                icon: Icons.shield_rounded,
                label: 'Standard QR',
                subtitle: 'No login needed',
                color: const Color(0xFF2D6A4F),
              )),
              const SizedBox(width: 12),
              Expanded(child: _infoCard(
                icon: Icons.lock_rounded,
                label: 'Encrypted QR',
                subtitle: auth.isLoggedIn ? 'Ready' : 'Login required',
                color: auth.isLoggedIn ? const Color(0xFF2D6A4F) : Colors.orange.shade600,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: auth.isLoggedIn ? const Color(0xFF059669) : Colors.orange.shade400,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  auth.isLoggedIn
                      ? 'Authenticated as ${auth.role?.replaceAll("_", " ") ?? "user"}'
                      : 'Guest mode — login to scan encrypted QRs',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, AuthProvider auth) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0, right: 0, top: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  color: const Color(0xFF2D6A4F),
                  onTap: auth.isLoggedIn
                      ? () => Navigator.pushNamed(context, '/profile')
                      : () => Navigator.pushNamed(context, '/login'),
                ),
                const SizedBox(width: 80),
                if (auth.isLoggedIn)
                  _navItem(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    color: const Color(0xFFE74C3C),
                    onTap: () => _confirmLogout(context),
                  )
                else
                  _navItem(
                    icon: Icons.login_rounded,
                    label: 'Login',
                    color: const Color(0xFF2D6A4F),
                    onTap: () => Navigator.pushNamed(context, '/login'),
                  ),
              ],
            ),
          ),
          Positioned(
            top: -16,
            left: 0, right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/scanner'),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2D6A4F), Color(0xFF52B788)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2D6A4F).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 32),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
