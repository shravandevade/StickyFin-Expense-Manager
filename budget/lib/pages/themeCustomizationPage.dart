import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThemeCustomizationPage extends StatefulWidget {
  const ThemeCustomizationPage({Key? key}) : super(key: key);

  @override
  State<ThemeCustomizationPage> createState() => _ThemeCustomizationPageState();
}

class _ThemeCustomizationPageState extends State<ThemeCustomizationPage> {
  late Color _currentColor;
  final TextEditingController _hexController = TextEditingController();

  final List<Map<String, dynamic>> _presets = [
    {"name": "Deep Ocean", "color": const Color(0xFF1B447A)},
    {"name": "Emerald Pine", "color": const Color(0xFF2E7D32)},
    {"name": "Royal Sapphire", "color": const Color(0xFF1565C0)},
    {"name": "Sunset Amber", "color": const Color(0xFFE65100)},
    {"name": "Midnight Amethyst", "color": const Color(0xFF6A1B9A)},
    {"name": "Teal Breeze", "color": const Color(0xFF00838F)},
    {"name": "Rose Bloom", "color": const Color(0xFFC2185B)},
    {"name": "Slate Minimal", "color": const Color(0xFF37474F)},
    {"name": "Crimson Spark", "color": const Color(0xFFC62828)},
    {"name": "Neon Cyan", "color": const Color(0xFF0097A7)},
    {"name": "Golden Honey", "color": const Color(0xFFF57F17)},
    {"name": "Charcoal Velvet", "color": const Color(0xFF212121)},
  ];

  @override
  void initState() {
    super.initState();
    _currentColor = HexColor(appStateSettings["accentColor"], defaultColor: const Color(0xFF1B447A));
    _hexController.text = toHexString(_currentColor).replaceAll("0xFF", "#");
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _applyColor(Color color) {
    setState(() {
      _currentColor = color;
      _hexController.text = toHexString(color).replaceAll("0xFF", "#");
    });

    final hexStr = toHexString(color);
    updateSettings("accentColor", hexStr, updateGlobalState: true);
    updateSettings("accentSystemColor", false, updateGlobalState: true);

    // Update recent colors
    List<dynamic> recents = List.from(appStateSettings["recentThemeColors"] ?? []);
    recents.remove(hexStr);
    recents.insert(0, hexStr);
    if (recents.length > 10) recents = recents.sublist(0, 10);
    updateSettings("recentThemeColors", recents, updateGlobalState: false);

    updateWidgetColorsAndText(context);
  }

  void _addCurrentToFavorites() {
    final hexStr = toHexString(_currentColor);
    List<dynamic> favorites = List.from(appStateSettings["favoriteThemeColors"] ?? []);
    if (!favorites.contains(hexStr)) {
      favorites.add(hexStr);
      updateSettings("favoriteThemeColors", favorites, updateGlobalState: true);
      setState(() {});
    }
  }

  void _removeFavorite(String hex) {
    List<dynamic> favorites = List.from(appStateSettings["favoriteThemeColors"] ?? []);
    favorites.remove(hex);
    updateSettings("favoriteThemeColors", favorites, updateGlobalState: true);
    setState(() {});
  }

  void _resetToDefault() {
    final defaultColor = const Color(0xFF1B447A);
    _applyColor(defaultColor);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<dynamic> favorites = appStateSettings["favoriteThemeColors"] ?? [];
    final List<dynamic> recents = appStateSettings["recentThemeColors"] ?? [];

    return PageFramework(
      title: "color-customization".tr(),
      backButton: true,
      dragDownToDismiss: true,
      horizontalPaddingConstrained: true,
      actions: [
        IconButton(
          tooltip: "restore-defaults".tr(),
          icon: Icon(
            appStateSettings["outlinedIcons"] ? Icons.restart_alt_outlined : Icons.restart_alt_rounded,
          ),
          onPressed: _resetToDefault,
        ),
      ],
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            // Live Theme Preview Card
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 14, 16),
              child: Container(
                padding: const EdgeInsetsDirectional.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _currentColor.withOpacity(0.18),
                      theme.colorScheme.surfaceVariant.withOpacity(0.35),
                    ],
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _currentColor.withOpacity(0.4), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _currentColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: _currentColor.withOpacity(0.4), blurRadius: 6, spreadRadius: 1),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        TextFont(
                          text: "live-theme-preview".tr(),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFont(
                      text: "preview-description".tr(),
                      fontSize: 13,
                      textColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _currentColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextFont(
                              text: "primary-action".tr(),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              textColor: ThemeData.estimateBrightnessForColor(_currentColor) == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _currentColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _currentColor.withOpacity(0.5)),
                            ),
                            child: TextFont(
                              text: "secondary".tr(),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              textColor: _currentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Theme Presets Grid
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 16),
              child: Container(
                padding: const EdgeInsetsDirectional.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFont(
                      text: "curated-presets".tr(),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _presets.map((preset) {
                        final Color c = preset["color"];
                        final bool isSelected = _currentColor.value == c.value;
                        return Tooltip(
                          message: preset["name"],
                          child: GestureDetector(
                            onTap: () => _applyColor(c),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: theme.colorScheme.onSurface, width: 3)
                                    : Border.all(color: Colors.transparent),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(color: c.withOpacity(0.5), blurRadius: 8, spreadRadius: 2),
                                ],
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      size: 22,
                                      color: ThemeData.estimateBrightnessForColor(c) == Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // RGB / HSV & Custom HEX input
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 16),
              child: Container(
                padding: const EdgeInsetsDirectional.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFont(
                      text: "custom-color-picker".tr(),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 12),
                    // HEX Input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _hexController,
                            decoration: InputDecoration(
                              labelText: "HEX Code",
                              hintText: "#1B447A",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onSubmitted: (val) {
                              String cleaned = val.replaceAll("#", "").replaceAll("0x", "").trim();
                              if (cleaned.length == 6) {
                                int? intVal = int.tryParse("0xFF$cleaned");
                                if (intVal != null) {
                                  _applyColor(Color(intVal));
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Button(
                          label: "save-to-favorites".tr(),
                          onTap: _addCurrentToFavorites,
                          icon: Icons.favorite_border_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // RGB Sliders
                    _buildColorSlider("Red", _currentColor.red, (val) {
                      _applyColor(Color.fromARGB(255, val.toInt(), _currentColor.green, _currentColor.blue));
                    }, Colors.red, theme),
                    _buildColorSlider("Green", _currentColor.green, (val) {
                      _applyColor(Color.fromARGB(255, _currentColor.red, val.toInt(), _currentColor.blue));
                    }, Colors.green, theme),
                    _buildColorSlider("Blue", _currentColor.blue, (val) {
                      _applyColor(Color.fromARGB(255, _currentColor.red, _currentColor.green, val.toInt()));
                    }, Colors.blue, theme),
                  ],
                ),
              ),
            ),

            // Favorite Colors Section
            if (favorites.isNotEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 16),
                child: Container(
                  padding: const EdgeInsetsDirectional.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFont(
                        text: "favorite-colors".tr(),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: favorites.map((hex) {
                          Color c = HexColor(hex.toString(), defaultColor: _currentColor);
                          return GestureDetector(
                            onTap: () => _applyColor(c),
                            onLongPress: () => _removeFavorite(hex.toString()),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _currentColor.value == c.value ? theme.colorScheme.onSurface : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

            // Recently Used Colors
            if (recents.isNotEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 32),
                child: Container(
                  padding: const EdgeInsetsDirectional.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFont(
                        text: "recently-used".tr(),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: recents.map((hex) {
                          Color c = HexColor(hex.toString(), defaultColor: _currentColor);
                          return GestureDetector(
                            onTap: () => _applyColor(c),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _currentColor.value == c.value ? theme.colorScheme.onSurface : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
          ]),
        ),
      ],
    );
  }

  Widget _buildColorSlider(String label, int value, ValueChanged<double> onChanged, Color activeColor, ThemeData theme) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: TextFont(
            text: "$label: $value",
            fontSize: 12,
            fontWeight: FontWeight.w600,
            textColor: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            activeColor: activeColor,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
