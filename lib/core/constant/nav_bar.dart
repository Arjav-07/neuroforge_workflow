import 'package:flutter/material.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';
import 'package:neuroforge_workflow/screen/home_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  // Central Router Core Stack Mappings
  final List<Widget> _appWorkspaceScreens = [
    const HomeScreen(), 
    const Center(child: Text("Calendar Workspace Coming Soon")), 
    const Center(child: Text("Create Task Sheet Coming Soon")),    
    const Center(child: Text("App Settings Panel Coming Soon")),   
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ForgeTheme.background,
      body: _appWorkspaceScreens[_currentIndex],
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // IntrinsicWidth forces the row to size itself tightly around its children
              IntrinsicWidth(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ForgeTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04), 
                        blurRadius: 24, 
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildBottomNavItem(
                        index: 0,
                        itemLabel: "Home",
                        activeAsset: "assets/icons/home_active.png",
                        inactiveAsset: "assets/icons/home_inactive.png",
                      ),
                      const SizedBox(width: 4),
                      _buildBottomNavItem(
                        index: 1,
                        itemLabel: "Calendar",
                        activeAsset: "assets/icons/cal_active.png",
                        inactiveAsset: "assets/icons/cal_inactive.png",
                      ),
                      const SizedBox(width: 4),
                      _buildBottomNavItem(
                        index: 2,
                        itemLabel: "Event",
                        activeAsset: "assets/icons/event_active.png",
                        inactiveAsset: "assets/icons/event_inactive.png",
                      ),
                      const SizedBox(width: 4),
                      _buildBottomNavItem(
                        index: 3,
                        itemLabel: "Settings",
                        activeAsset: "assets/icons/settings_active.png",
                        inactiveAsset: "assets/icons/settings_inactive.png",
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

  // Dynamic Item Constructor swapping PNG states based on selection status
  Widget _buildBottomNavItem({
    required int index,
    required String itemLabel,
    required String activeAsset,
    required String inactiveAsset,
  }) {
    final bool isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? brandBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              isSelected ? activeAsset : inactiveAsset,
              width: 22,
              height: 22,
              fit: BoxFit.contain,
              color: isSelected ? Colors.white : ForgeTheme.textMuted,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.image_not_supported_outlined, 
                color: isSelected ? Colors.white : ForgeTheme.textMuted, 
                size: 22,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                itemLabel,
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 13,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}