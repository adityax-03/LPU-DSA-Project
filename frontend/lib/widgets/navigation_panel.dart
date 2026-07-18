import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class NavigationPanel extends StatefulWidget {
  final String selectedTransportMode;
  const NavigationPanel({Key? key, required this.selectedTransportMode}) : super(key: key);

  @override
  State<NavigationPanel> createState() => _NavigationPanelState();
}

class _NavigationPanelState extends State<NavigationPanel> {
  bool _showStepsInline = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    if (!appState.isNavigating) return const SizedBox.shrink();

    // Determine current mode metrics
    int displayTime = appState.walkTime;
    String modeName = "Walk";
    String routeDetail = "Mostly flat";

    if (widget.selectedTransportMode == "driving") {
      displayTime = (appState.walkTime * 0.3).round() + 1;
      modeName = "Drive";
      routeDetail = "via Main Road";
    } else if (widget.selectedTransportMode == "cycling") {
      displayTime = appState.cycleTime;
      modeName = "Cycle";
      routeDetail = "via Campus Cycle Lane";
    } else if (widget.selectedTransportMode == "shuttle") {
      displayTime = appState.shuttleTime;
      modeName = "Shuttle";
      routeDetail = "via LPU Shuttle Lane";
    }

    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title / Destination
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appState.endNode?.name ?? "Navigating Destination",
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E3A8A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (appState.classroomDetails != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                appState.classroomDetails!,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFD4AF37),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                        onPressed: () {
                          appState.clearNavigation();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Alternative Routes Selector (Google Maps style)
                  if (appState.alternativeRoutes.length > 1) ...[
                    Text(
                      "Available Routes:",
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 52,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: appState.alternativeRoutes.length,
                        itemBuilder: (context, index) {
                          final isSelected = (appState.selectedRouteIndex == index);
                          final distance = appState.alternativeDistances[index];
                          final time = appState.alternativeWalkTimes[index];
                          final isShortest = (index == 0);
                          
                          return GestureDetector(
                            onTap: () => appState.selectRoute(index),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFE8F0FE) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF1A73E8) : Colors.black12,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Route ${index + 1}${isShortest ? ' (Shortest)' : ''}",
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? const Color(0xFF1E3A8A) : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      "$distance km • $time min",
                                      style: GoogleFonts.outfit(fontSize: 10, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                  ],

                  // Route Summary Metric: "25 min (1.8 km) Mostly flat"
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "$displayTime min",
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF16A34A), // Green highlight
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "(${appState.routeDistance} km)",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        routeDetail,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "ETA: ${appState.eta} • $modeName Mode",
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.black38, fontWeight: FontWeight.w500),
                  ),

                  // Expandable step-by-step list
                  if (_showStepsInline) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Text(
                      "Directions:",
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: appState.directions.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.subdirectory_arrow_right,
                                  size: 14,
                                  color: Color(0xFFD4AF37),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    appState.directions[index],
                                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Bottom Action Buttons Row: [Start, Live View, Steps]
                  Row(
                    children: [
                      // 1. START BUTTON
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Starting navigation to ${appState.endNode?.name ?? 'destination'}...",
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: const Color(0xFF16A34A),
                              ),
                            );
                          },
                          icon: const Icon(Icons.navigation, size: 16, color: Colors.white),
                          label: Text(
                            "Start",
                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A73E8),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 2. LIVE VIEW BUTTON
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Show beautiful dialog with satellite image
                            final isBlock = appState.endNode?.type == "BLOCK";
                            final imageName = isBlock ? 'assets/block_amphitheater.jpg' : 'assets/campus_sunset.jpg';
                            final imageTitle = isBlock ? 'Building View (Amphitheater)' : 'Campus Aerial View';

                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                contentPadding: EdgeInsets.zero,
                                titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Live View Mode",
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => Navigator.pop(context),
                                    )
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(24),
                                        bottomRight: Radius.circular(24),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.bottomLeft,
                                        children: [
                                          Image.asset(
                                            imageName,
                                            fit: BoxFit.cover,
                                            height: 240,
                                            width: double.infinity,
                                          ),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withOpacity(0.75),
                                                ]
                                              )
                                            ),
                                            child: Text(
                                              imageTitle,
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF1E3A8A)),
                          label: Text(
                            "Live View",
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.black12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 3. STEPS BUTTON
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showStepsInline = !_showStepsInline;
                            });
                          },
                          icon: Icon(
                            _showStepsInline ? Icons.expand_less : Icons.format_list_bulleted,
                            size: 16,
                            color: const Color(0xFF1E3A8A),
                          ),
                          label: Text(
                            "Steps",
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.black12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
