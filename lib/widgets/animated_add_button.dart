import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class AnimatedAddButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  const AnimatedAddButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
  });

  @override
  State<AnimatedAddButton> createState() => _AnimatedAddButtonState();
}

class _AnimatedAddButtonState extends State<AnimatedAddButton> {
  bool _isExpanded = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // Dynamic colors based on theme
    final primaryColor = isDark ? ThemeProvider.primaryDark : ThemeProvider.primaryLight;
    final accentColor = isDark ? ThemeProvider.accentDark : ThemeProvider.accentLight;
    final hoverColor = isDark ? ThemeProvider.accentDark.withOpacity(0.8) : ThemeProvider.accentLight.withOpacity(0.8);
    final textColor = isDark ? Colors.white.withOpacity(0.95) : Colors.white.withOpacity(0.95);

    return MouseRegion(
      onEnter: (_) => setState(() => _isExpanded = true),
      onExit: (_) => setState(() {
        _isExpanded = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_isExpanded ? 16 : 20),
            boxShadow: [
              BoxShadow(
                color: isDark 
                      ? accentColor.withOpacity(_isPressed ? 0.24 : _isExpanded ? 0.3 : 0.18)
                      : accentColor.withOpacity(_isPressed ? 0.2 : _isExpanded ? 0.25 : 0.15),
                spreadRadius: _isPressed ? 1 : _isExpanded ? 2 : 1,
                blurRadius: _isPressed ? 8 : _isExpanded ? 20 : 12,
                offset: Offset(0, _isPressed ? 2 : _isExpanded ? 4 : 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(_isExpanded ? 16 : 20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(
                  horizontal: _isExpanded ? 20.0 : 14.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _isPressed ? primaryColor : _isExpanded ? hoverColor : accentColor,
                      _isPressed ? primaryColor.withOpacity(0.9) : _isExpanded 
                          ? hoverColor.withOpacity(0.9) 
                          : accentColor.withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(_isExpanded ? 16 : 20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.all(_isExpanded ? 2 : 0),
                      child: Icon(
                        widget.icon,
                        size: _isExpanded ? 20 : 18,
                        color: textColor,
                      ),
                    ),
                    ClipRect(
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        alignment: Alignment.centerLeft,
                        widthFactor: _isExpanded ? 1.0 : 0.0,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            widget.label,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
