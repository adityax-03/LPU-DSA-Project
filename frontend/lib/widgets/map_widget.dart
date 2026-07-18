import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/node.dart';
import '../providers/app_state.dart';

class CampusMapWidget extends StatefulWidget {
  const CampusMapWidget({Key? key}) : super(key: key);

  @override
  State<CampusMapWidget> createState() => _CampusMapWidgetState();
}

class _CampusMapWidgetState extends State<CampusMapWidget> with SingleTickerProviderStateMixin {
  // Navigation avatar position controller for active simulation
  late AnimationController _avatarAnimationController;
  double _animationProgress = 0.0;

  // Zoom and Pan states
  Offset _panOffset = const Offset(0, 0);
  double _zoomScale = 1.0;

  // Background map image reference (disabled in Phase 3 for clean vector style)
  ui.Image? _mapImage;

  // Bounding box for mapping GPS coordinates to canvas coordinates
  final double minLat = 31.2500;
  final double maxLat = 31.2600;
  final double minLng = 75.7000;
  final double maxLng = 75.7100;


  @override
  void initState() {
    super.initState();
    _avatarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    
    _avatarAnimationController.addListener(() {
      setState(() {
        _animationProgress = _avatarAnimationController.value;
      });
    });

    _avatarAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _avatarAnimationController.dispose();
    super.dispose();
  }

  // Convert GPS (Lat, Lng) to local canvas coordinates
  Offset _gpsToCanvas(double lat, double lng, Size size) {
    double x = ((lng - minLng) / (maxLng - minLng)) * size.width;
    double y = ((maxLat - lat) / (maxLat - minLat)) * size.height;
    return Offset(x, y);
  }

  // Find position along the multi-segment route nodes
  Offset _getPositionAlongRoute(List<CampusNode> route, Size size) {
    if (route.isEmpty) return const Offset(0, 0);
    if (route.length == 1) return _gpsToCanvas(route.first.latitude, route.first.longitude, size);

    List<Offset> points = route.map((node) => _gpsToCanvas(node.latitude, node.longitude, size)).toList();
    List<double> segmentLengths = [];
    double totalLength = 0.0;
    
    for (int i = 0; i < points.length - 1; i++) {
      double len = (points[i+1] - points[i]).distance;
      segmentLengths.add(len);
      totalLength += len;
    }

    double targetDistance = _animationProgress * totalLength;
    double currentDistance = 0.0;

    for (int i = 0; i < points.length - 1; i++) {
      double len = segmentLengths[i];
      if (currentDistance + len >= targetDistance) {
        double ratio = (targetDistance - currentDistance) / len;
        return Offset.lerp(points[i], points[i+1], ratio)!;
      }
      currentDistance += len;
    }
    return points.last;
  }

  // Automatically center and scale the camera viewport to fit the active route
  void _fitRoute(List<CampusNode> route, Size size) {
    if (route.isEmpty) return;

    double minRouteLat = 90.0;
    double maxRouteLat = -90.0;
    double minRouteLng = 180.0;
    double maxRouteLng = -180.0;

    for (var node in route) {
      if (node.latitude < minRouteLat) minRouteLat = node.latitude;
      if (node.latitude > maxRouteLat) maxRouteLat = node.latitude;
      if (node.longitude < minRouteLng) minRouteLng = node.longitude;
      if (node.longitude > maxRouteLng) maxRouteLng = node.longitude;
    }

    Offset pMin = _gpsToCanvas(maxRouteLat, minRouteLng, size); // top-left
    Offset pMax = _gpsToCanvas(minRouteLat, maxRouteLng, size); // bottom-right

    double routeWidth = (pMax.dx - pMin.dx).abs();
    double routeHeight = (pMax.dy - pMin.dy).abs();

    if (routeWidth == 0) routeWidth = 50;
    if (routeHeight == 0) routeHeight = 50;

    // Viewport padding and visible bounds accounting for the 380px left side panel on desktop
    double padding = 120.0;
    bool isWideScreen = size.width > 700;
    double availableWidth = isWideScreen ? (size.width - 380 - padding) : (size.width - padding);
    double scaleX = availableWidth / routeWidth;
    double scaleY = (size.height - padding) / routeHeight;
    double targetScale = min(scaleX, scaleY).clamp(0.9, 2.5);

    Offset routeCenter = Offset(
      (pMin.dx + pMax.dx) / 2,
      (pMin.dy + pMax.dy) / 2,
    );

    // Shift center to the right by 190px (half of 380px side panel) on wide screens
    double horizontalOffset = isWideScreen ? 190.0 : 0.0;
    Offset viewCenter = Offset(size.width / 2 + horizontalOffset, size.height / 2);
    Offset targetPan = viewCenter - (routeCenter * targetScale);

    setState(() {
      _zoomScale = targetScale;
      _panOffset = targetPan;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    // Map camera remains fixed to avoid moving on route changes or clicks

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        
        Offset? avatarPos;
        if (appState.isNavigating && appState.routeNodes.length >= 2) {
          avatarPos = _getPositionAlongRoute(appState.routeNodes, canvasSize);
        }

        return Stack(
          children: [
            // 1. Draggable/Pannable Map GestureDetector (occupies the full background)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleUpdate: (details) {
                  setState(() {
                    _panOffset += details.focalPointDelta;
                    if (details.scale != 1.0) {
                      _zoomScale = (_zoomScale * details.scale).clamp(0.8, 4.0);
                    }
                  });
                },
                onTapUp: (details) {
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final Offset localPos = box.globalToLocal(details.globalPosition);

                  // Convert touch position back to canvas coordinates
                  final Offset canvasPos = (localPos - _panOffset) / _zoomScale;

                  // Find nearest node
                  CampusNode? nearest;
                  double minDist = 99999.0;
                  for (var node in appState.allNodes) {
                    final nodePos = _gpsToCanvas(node.latitude, node.longitude, box.size);
                    final d = (canvasPos - nodePos).distance;
                    if (d < 45.0 && d < minDist) { // wide click tolerance
                      minDist = d;
                      nearest = node;
                    }
                  }

                  if (nearest != null) {
                    if (appState.activeField == "from") {
                      appState.setStartNode(nearest);
                    } else {
                      appState.setEndNode(nearest);
                    }
                  }
                },
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _MapPainter(
                    mapImage: _mapImage,
                    allNodes: appState.allNodes,
                    routeNodes: appState.routeNodes,
                    alternativeRoutes: appState.alternativeRoutes,
                    selectedRouteIndex: appState.selectedRouteIndex,
                    panOffset: _panOffset,
                    zoomScale: _zoomScale,
                    gpsToCanvas: _gpsToCanvas,
                    activeFacility: appState.nearestFacility,
                  ),
                ),
              ),
            ),

            // 2. Dynamic Boy/Girl Avatar marker animated on the path (ignoring pointers)
            if (avatarPos != null)
              Positioned(
                left: _panOffset.dx + (avatarPos.dx * _zoomScale) - 22,
                top: _panOffset.dy + (avatarPos.dy * _zoomScale) - 52,
                child: IgnorePointer(
                  child: _buildAvatarMarker(
                    appState.isNavigating,
                    appState.userProfile?['gender'] ?? "boy",
                  ),
                ),
              ),

            // 3. Zoom and Recenter float controls (overlays on top of map)
            Positioned(
              bottom: 24,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIconButton(Icons.add, () {
                    setState(() {
                      _zoomScale = (_zoomScale + 0.25).clamp(0.8, 4.0);
                    });
                  }),
                  const SizedBox(height: 10),
                  _buildIconButton(Icons.remove, () {
                    setState(() {
                      _zoomScale = (_zoomScale - 0.25).clamp(0.8, 4.0);
                    });
                  }),
                  const SizedBox(height: 10),
                  _buildIconButton(Icons.my_location, () {
                    if (appState.isNavigating && appState.routeNodes.isNotEmpty) {
                      _fitRoute(appState.routeNodes, canvasSize);
                    } else {
                      setState(() {
                        _zoomScale = 1.25;
                        _panOffset = Offset(
                          canvasSize.width / 2 - (_gpsToCanvas(31.2550, 75.7050, canvasSize).dx * 1.25),
                          canvasSize.height / 2 - (_gpsToCanvas(31.2550, 75.7050, canvasSize).dy * 1.25),
                        );
                      });
                    }
                  }),
                ],
              ),
            ),

            // 4. Neat Scale indicator in bottom right corner (Google Maps style)
            Positioned(
              bottom: 24,
              right: 80,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "100 ft / 200 m",
                        style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 60,
                        height: 3,
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Colors.black, width: 1.5),
                            right: BorderSide(color: Colors.black, width: 1.5),
                            bottom: BorderSide(color: Colors.black, width: 1.5),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF1E3A8A)),
        onPressed: onPressed,
      ),
    );
  }

  // Premium Gender Avatar Navigating Marker representation
  Widget _buildAvatarMarker(bool isNavigating, String gender) {
    final bool isBoy = gender == "boy";
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isNavigating ? const Color(0xFFD4AF37) : const Color(0xFF1E3A8A), // Gold when navigating
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: isBoy ? const Color(0xFFDBEAFE) : const Color(0xFFFEE2E2), // Soft Blue vs Soft Pink
            child: Text(
              isBoy ? "👦" : "👧", // Gender-based Avatar
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        // Downward Pointer Tail
        Container(
          width: 8,
          height: 8,
          transform: Matrix4.translationValues(0, -2, 0)..rotateZ(pi / 4),
          decoration: BoxDecoration(
            color: isNavigating ? const Color(0xFFD4AF37) : const Color(0xFF1E3A8A),
          ),
        ),
      ],
    );
  }
}

class _MapPainter extends CustomPainter {
  final ui.Image? mapImage;
  final List<CampusNode> allNodes;
  final List<CampusNode> routeNodes;
  final List<List<CampusNode>> alternativeRoutes;
  final int selectedRouteIndex;
  final Offset panOffset;
  final double zoomScale;
  final Offset Function(double, double, Size) gpsToCanvas;
  final CampusNode? activeFacility;

  _MapPainter({
    required this.mapImage,
    required this.allNodes,
    required this.routeNodes,
    required this.alternativeRoutes,
    required this.selectedRouteIndex,
    required this.panOffset,
    required this.zoomScale,
    required this.gpsToCanvas,
    required this.activeFacility,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(zoomScale);

    // 1. Draw Clean Light Vector Map Base (Fills and Lawns)
    final bgPaint = Paint()..color = const Color(0xFFF5F6F9); // Light-grey/cream base
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Paint beautiful soft-green lawns/parks across the campus
    final lawnPaint = Paint()
      ..color = const Color(0xFFE8F5E9)
      ..style = PaintingStyle.fill;
    
    // Draw some stylized lawns representing campus fields
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(40, 60, 240, 220), const Radius.circular(16)), lawnPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(320, 100, 200, 300), const Radius.circular(16)), lawnPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(100, 420, 350, 220), const Radius.circular(16)), lawnPaint);

    // Paint Campus Water Body (Lake) at the right side
    try {
      final waterBodyNode = allNodes.firstWhere((n) => n.id == "WATER_BODY");
      final pLake = gpsToCanvas(waterBodyNode.latitude, waterBodyNode.longitude, size);
      
      final lakePaint = Paint()
        ..color = const Color(0xFFE3F2FD)
        ..style = PaintingStyle.fill;
      final lakeBorderPaint = Paint()
        ..color = const Color(0xFF90CAF9)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawOval(Rect.fromCenter(center: pLake, width: 160, height: 90), lakePaint);
      canvas.drawOval(Rect.fromCenter(center: pLake, width: 160, height: 90), lakeBorderPaint);
    } catch (_) {}

    // 2. Draw Clean Campus Roadways (White lanes with subtle grey borders)
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    final roadBorderPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 17.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void drawRoadSegment(String id1, String id2) {
      try {
        final n1 = allNodes.firstWhere((n) => n.id == id1);
        final n2 = allNodes.firstWhere((n) => n.id == id2);
        final p1 = gpsToCanvas(n1.latitude, n1.longitude, size);
        final p2 = gpsToCanvas(n2.latitude, n2.longitude, size);
        
        canvas.drawLine(p1, p2, roadBorderPaint);
        canvas.drawLine(p1, p2, roadPaint);
      } catch (_) {}
    }

    // Connect nodes by roadways
    drawRoadSegment("GATE_MAIN", "SECURITY_OFFICE");
    drawRoadSegment("SECURITY_OFFICE", "BUS_TERMINUS");
    drawRoadSegment("BUS_TERMINUS", "BUS_STOP");
    drawRoadSegment("BUS_STOP", "PARKING");
    drawRoadSegment("PARKING", "ADMIN_BLOCK");
    drawRoadSegment("ADMIN_BLOCK", "PRIMARY_HEALTH");
    drawRoadSegment("PRIMARY_HEALTH", "HEALTH_CENTRE");
    drawRoadSegment("HEALTH_CENTRE", "LIBRARY");
    drawRoadSegment("LIBRARY", "BLOCK_34");
    drawRoadSegment("BLOCK_34", "BLOCK_38");
    drawRoadSegment("BLOCK_38", "AMPHITHEATRE");
    
    // Hostels
    drawRoadSegment("BH_1", "BH_2");
    drawRoadSegment("BH_2", "BH_3");
    drawRoadSegment("BH_3", "BH_4");
    drawRoadSegment("BH_4", "HEALTH_CENTRE");
    drawRoadSegment("GH_1", "BLOCK_38");
    drawRoadSegment("GH_1", "GH_2");
    
    // Sports & Grounds
    drawRoadSegment("BH_1", "SPORTS_COMPLEX");
    drawRoadSegment("SPORTS_COMPLEX", "CRICKET_GROUND");
    drawRoadSegment("CRICKET_GROUND", "FOOTBALL_GROUND");
    drawRoadSegment("FOOTBALL_GROUND", "BH_4");
    
    // Mall & Food
    drawRoadSegment("BLOCK_34", "UNI_MALL");
    drawRoadSegment("UNI_MALL", "FOOD_COURT");
    drawRoadSegment("FOOD_COURT", "FOOD_STREET");
    drawRoadSegment("UNI_MALL", "ATM");
    drawRoadSegment("ATM", "ATM_BANK");
    
    // Academic Loop
    drawRoadSegment("HEALTH_CENTRE", "HOTEL_MGT");
    drawRoadSegment("HOTEL_MGT", "LAW_SCHOOL");
    drawRoadSegment("LAW_SCHOOL", "AGRICULTURE");
    drawRoadSegment("AGRICULTURE", "BLOCK_34");
    
    // Residences & Lake
    drawRoadSegment("BLOCK_38", "WATER_BODY");
    drawRoadSegment("GH_2", "VC_RES");
    drawRoadSegment("VC_RES", "FACULTY_RES");
    drawRoadSegment("FACULTY_RES", "WATER_BODY");
    drawRoadSegment("WATER_BODY", "NURSERY");

    // 3. Draw Alternative Navigation Route Lines & Road Segment Distance Labels
    if (alternativeRoutes.isNotEmpty) {
      for (int rIdx = 0; rIdx < alternativeRoutes.length; rIdx++) {
        final isSelected = (rIdx == selectedRouteIndex);
        final List<CampusNode> currentRoute = alternativeRoutes[rIdx];
        if (currentRoute.length < 2) continue;

        final dotPaint = Paint()
          ..color = isSelected ? const Color(0xFF1A73E8) : const Color(0xFF90CAF9).withOpacity(0.7) // Active Blue vs Light Alternative Blue
          ..style = PaintingStyle.fill;

        final glowPaint = Paint()
          ..color = isSelected ? const Color(0xFF1A73E8).withOpacity(0.15) : const Color(0xFF90CAF9).withOpacity(0.08)
          ..style = PaintingStyle.fill;

        List<Offset> points = currentRoute.map((n) => gpsToCanvas(n.latitude, n.longitude, size)).toList();
        
        for (int i = 0; i < points.length - 1; i++) {
          Offset p1 = points[i];
          Offset p2 = points[i+1];
          double distance = (p2 - p1).distance;
          double spacing = isSelected ? 12.0 : 18.0; // tighter spacing for selected route
          int numDots = (distance / spacing).floor();
          
          for (int j = 0; j <= numDots; j++) {
            double fraction = numDots == 0 ? 0.0 : j / numDots;
            Offset dotPos = Offset.lerp(p1, p2, fraction)!;
            canvas.drawCircle(dotPos, isSelected ? 7.0 : 5.0, glowPaint);
            canvas.drawCircle(dotPos, isSelected ? 4.0 : 2.5, dotPaint);
          }

          // Only draw distance labels on the selected route to avoid map clutter
          if (isSelected) {
            Offset mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
            int distInMeters = (distance * 1.5).round();
            
            final tagRect = Rect.fromCenter(center: mid, width: 34, height: 16);
            canvas.drawRRect(
              RRect.fromRectAndRadius(tagRect, const Radius.circular(4)),
              Paint()..color = Colors.white,
            );
            canvas.drawRRect(
              RRect.fromRectAndRadius(tagRect, const Radius.circular(4)),
              Paint()
                ..color = const Color(0xFF1A73E8).withOpacity(0.5)
                ..strokeWidth = 0.8
                ..style = PaintingStyle.stroke,
            );

            final textSpan = TextSpan(
              text: "${distInMeters}m",
              style: GoogleFonts.outfit(
                fontSize: 8.0,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A73E8),
              ),
            );
            final textPainter = TextPainter(
              text: textSpan,
              textDirection: TextDirection.ltr,
            )..layout();
            textPainter.paint(
              canvas,
              Offset(mid.dx - textPainter.width / 2, mid.dy - textPainter.height / 2),
            );
          }
        }
      }
    } else if (routeNodes.length >= 2) {
      // Fallback single route
      final dotPaint = Paint()
        ..color = const Color(0xFF1A73E8)
        ..style = PaintingStyle.fill;
      final glowPaint = Paint()
        ..color = const Color(0xFF1A73E8).withOpacity(0.15)
        ..style = PaintingStyle.fill;

      List<Offset> points = routeNodes.map((n) => gpsToCanvas(n.latitude, n.longitude, size)).toList();
      for (int i = 0; i < points.length - 1; i++) {
        Offset p1 = points[i];
        Offset p2 = points[i+1];
        double distance = (p2 - p1).distance;
        double spacing = 12.0;
        int numDots = (distance / spacing).floor();
        
        for (int j = 0; j <= numDots; j++) {
          double fraction = numDots == 0 ? 0.0 : j / numDots;
          Offset dotPos = Offset.lerp(p1, p2, fraction)!;
          canvas.drawCircle(dotPos, 7.0, glowPaint);
          canvas.drawCircle(dotPos, 4.0, dotPaint);
        }

        Offset mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        int distInMeters = (distance * 1.5).round();
        
        final tagRect = Rect.fromCenter(center: mid, width: 34, height: 16);
        canvas.drawRRect(
          RRect.fromRectAndRadius(tagRect, const Radius.circular(4)),
          Paint()..color = Colors.white,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(tagRect, const Radius.circular(4)),
          Paint()
            ..color = const Color(0xFF1A73E8).withOpacity(0.5)
            ..strokeWidth = 0.8
            ..style = PaintingStyle.stroke,
        );

        final textSpan = TextSpan(
          text: "${distInMeters}m",
          style: GoogleFonts.outfit(
            fontSize: 8.0,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A73E8),
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(mid.dx - textPainter.width / 2, mid.dy - textPainter.height / 2),
        );
      }
    }

    // 4. Draw Academic Blocks and Facilities as Styled Vector Cards
    final blockPaint = Paint()
      ..color = const Color(0xFFFFECE0) // Light orange peach
      ..style = PaintingStyle.fill;
    final blockBorder = Paint()
      ..color = const Color(0xFFE28B54)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final facilityPaint = Paint()
      ..color = const Color(0xFFE8F0FE) // Light blue
      ..style = PaintingStyle.fill;
    final facilityBorder = Paint()
      ..color = const Color(0xFF1A73E8)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final hostelPaint = Paint()
      ..color = const Color(0xFFFCE8E6) // Light rose/pink
      ..style = PaintingStyle.fill;
    final hostelBorder = Paint()
      ..color = const Color(0xFFD93025)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (CampusNode node in allNodes) {
      if (node.type == "ROAD_NODE") continue;
      
      final pos = gpsToCanvas(node.latitude, node.longitude, size);
      
      double boxWidth = 64.0;
      double boxHeight = 28.0;
      Paint paintToUse = facilityPaint;
      Paint borderToUse = facilityBorder;

      if (node.type == "BLOCK") {
        boxWidth = 72.0;
        boxHeight = 32.0;
        paintToUse = blockPaint;
        borderToUse = blockBorder;
      } else if (node.type == "HOSTEL") {
        boxWidth = 68.0;
        boxHeight = 30.0;
        paintToUse = hostelPaint;
        borderToUse = hostelBorder;
      }

      final rect = Rect.fromCenter(center: pos, width: boxWidth, height: boxHeight);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
      
      canvas.drawRRect(rrect, paintToUse);
      canvas.drawRRect(rrect, borderToUse);

      // Facility highlight glow
      if (activeFacility != null && activeFacility!.id == node.id) {
        final glowPaint = Paint()
          ..color = const Color(0xFFD4AF37).withOpacity(0.5)
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke;
        canvas.drawRRect(rrect.inflate(4), glowPaint);
      }

      // Draw short label names
      String label = node.name;
      if (label.length > 15) {
        label = label.substring(0, 12) + "...";
      }
      
      final textSpan = TextSpan(
        text: label,
        style: GoogleFonts.outfit(
          fontSize: 8.0,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: boxWidth - 4);
      
      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
      );
    }

    // 5. Draw Pin markers for Start (Blue Dot / Green Pin) and End (Red Pin)
    if (routeNodes.isNotEmpty) {
      final startNode = routeNodes.first;
      final endNode = routeNodes.last;
      
      final pStart = gpsToCanvas(startNode.latitude, startNode.longitude, size);
      final pEnd = gpsToCanvas(endNode.latitude, endNode.longitude, size);

      // Draw Blue Start Pin
      final bluePaint = Paint()..color = const Color(0xFF1A73E8);
      canvas.drawCircle(pStart, 8.0, Paint()..color = Colors.white);
      canvas.drawCircle(pStart, 6.0, bluePaint);

      // Draw Red End Pin
      final redPaint = Paint()..color = Colors.red;
      final path = Path();
      path.moveTo(pEnd.dx, pEnd.dy);
      path.quadraticBezierTo(pEnd.dx - 8, pEnd.dy - 12, pEnd.dx - 6, pEnd.dy - 18);
      path.arcToPoint(Offset(pEnd.dx + 6, pEnd.dy - 18), radius: const Radius.circular(6));
      path.quadraticBezierTo(pEnd.dx + 8, pEnd.dy - 12, pEnd.dx, pEnd.dy);
      canvas.drawPath(path, redPaint);
      canvas.drawCircle(Offset(pEnd.dx, pEnd.dy - 18), 3.0, Paint()..color = Colors.white);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
