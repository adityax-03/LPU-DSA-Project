import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/map_widget.dart';
import '../widgets/navigation_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _showSuggestions = false;

  // Search input controllers and focus nodes for From/To fields
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _fromFocusNode = FocusNode();
  final _toFocusNode = FocusNode();

  // Selected Google Maps Transport Mode
  String _selectedTransportMode = "walking";

  // Toggle for directions inside desktop left side box
  bool _showStepsInsideSideBox = false;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);

    // From field listeners
    _fromController.addListener(() {
      if (_fromFocusNode.hasFocus) {
        appState.getSuggestions(_fromController.text);
      }
    });

    _fromFocusNode.addListener(() {
      if (_fromFocusNode.hasFocus) {
        appState.setActiveField("from");
        setState(() {
          _showSuggestions = true;
        });
      }
    });

    // To field listeners
    _toController.addListener(() {
      if (_toFocusNode.hasFocus) {
        appState.getSuggestions(_toController.text);
      }
    });

    _toFocusNode.addListener(() {
      if (_toFocusNode.hasFocus) {
        appState.setActiveField("to");
        setState(() {
          _showSuggestions = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _fromController.dispose();
    _toController.dispose();
    _fromFocusNode.dispose();
    _toFocusNode.dispose();
    super.dispose();
  }

  void _showLiveViewDialog(AppState appState) {
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
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final size = MediaQuery.of(context).size;
    final bool isWideScreen = size.width > 700;

    // Synchronize text inputs when changed by map node clicks
    if (!_fromFocusNode.hasFocus && appState.startNode != null && _fromController.text != appState.startNode!.name) {
      _fromController.text = appState.startNode!.name;
    }
    if (!_toFocusNode.hasFocus && appState.endNode != null && _toController.text != appState.endNode!.name) {
      _toController.text = appState.endNode!.name;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: isWideScreen
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Desktop left-side control panel (fixed width, side-by-side)
                Container(
                  width: 380,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(5, 0),
                      )
                    ],
                  ),
                  child: _buildLeftSidePanel(appState),
                ),
                // 2. Desktop map canvas (takes remaining screen width)
                const Expanded(
                  child: CampusMapWidget(),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Mobile top search header
                _buildRoutingHeader(appState),
                
                // Categories facility chips row
                if (!appState.isNavigating)
                  _buildCategoriesRow(appState),
                
                // 2. Mobile map canvas (framed in the middle, fixed size layout)
                const Expanded(
                  child: CampusMapWidget(),
                ),

                // 3. Active route detail panel or landing welcome panel at the bottom
                if (appState.isNavigating)
                  NavigationPanel(selectedTransportMode: _selectedTransportMode)
                else
                  _buildWelcomeAndControlCard(appState),
              ],
            ),
    );
  }

  // Helper widgets for Profile Header
  Widget _buildProfileHeader(AppState appState) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFFFEF3C7),
          child: Text(
            appState.userProfile?['gender'] == "girl" ? "👧" : "👦",
            style: const TextStyle(fontSize: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome, ${appState.userProfile?['name'] ?? 'Student'}",
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
              ),
              Text(
                "Reg No: ${appState.userProfile?['registrationNumber'] ?? '12345678'}",
                style: GoogleFonts.outfit(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
          onPressed: () => appState.logout(),
        ),
      ],
    );
  }

  // Helper widgets for GPS Mode Status
  Widget _buildGpsSimulatorRow(AppState appState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "GPS Simulator Mode",
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
            ),
            Text(
              appState.isInsideCampus ? "Inside LPU Campus" : "Outside (Delhi)",
              style: GoogleFonts.outfit(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
        Switch(
          value: appState.isInsideCampus,
          activeColor: const Color(0xFF1E3A8A),
          onChanged: (val) {
            appState.setLocationMode(val, city: val ? "Jalandhar" : "Delhi");
          },
        ),
      ],
    );
  }

  // Unified left-side panel matching "last things first and first things last"
  Widget _buildLeftSidePanel(AppState appState) {
    final walk = appState.walkTime;
    final cycle = appState.cycleTime;
    final shuttle = appState.shuttleTime;
    final drive = (walk * 0.3).round() + 1;

    int displayTime = walk;
    String modeName = "Walk";
    String routeDetail = "Mostly flat";

    if (_selectedTransportMode == "driving") {
      displayTime = drive;
      modeName = "Drive";
      routeDetail = "via Main Road";
    } else if (_selectedTransportMode == "cycling") {
      displayTime = cycle;
      modeName = "Cycle";
      routeDetail = "via Campus Cycle Lane";
    } else if (_selectedTransportMode == "shuttle") {
      displayTime = shuttle;
      modeName = "Shuttle";
      routeDetail = "via LPU Shuttle Lane";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Profile information and GPS toggle placed FIRST at the top
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            children: [
              _buildProfileHeader(appState),
              const SizedBox(height: 12),
              _buildGpsSimulatorRow(appState),
            ],
          ),
        ),

        const Divider(height: 1, color: Colors.black12),

        // 2. From & To interactive search input fields placed NEXT
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _fromController,
                  focusNode: _fromFocusNode,
                  style: GoogleFonts.outfit(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Choose start location...",
                    prefixIcon: const Icon(Icons.circle, color: Color(0xFF1A73E8), size: 10),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _toController,
                  focusNode: _toFocusNode,
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: "Choose destination...",
                    prefixIcon: const Icon(Icons.location_on, color: Colors.red, size: 14),
                    suffixIcon: appState.isNavigating
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              appState.clearNavigation();
                              _toController.clear();
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              // Suggestion List container
              if (_showSuggestions && appState.searchSuggestions.isNotEmpty && (_fromFocusNode.hasFocus || _toFocusNode.hasFocus)) ...[
                const SizedBox(height: 10),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: appState.searchSuggestions.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final suggestion = appState.searchSuggestions[index];
                      return ListTile(
                        dense: true,
                        title: Text(suggestion['name']!, style: GoogleFonts.outfit(fontSize: 12)),
                        onTap: () {
                          final node = appState.allNodes.firstWhere((n) => n.id == suggestion['id']);
                          if (appState.activeField == "from") {
                            appState.setStartNode(node);
                            _fromController.text = node.name;
                            _fromFocusNode.unfocus();
                          } else {
                            appState.setEndNode(node);
                            _toController.text = node.name;
                            _toFocusNode.unfocus();
                          }
                          setState(() {
                            _showSuggestions = false;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),

        const Divider(height: 1, color: Colors.black12),

        // 3. Navigation modes and details placed LAST at the bottom
        Expanded(
          child: Container(
            color: const Color(0xFFF8FAFC),
            child: appState.isNavigating
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Transport Mode Tab Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildTransportModeTab("driving", Icons.directions_car, "$drive min", appState),
                            _buildTransportModeTab("cycling", Icons.directions_bike, "$cycle min", appState),
                            _buildTransportModeTab("walking", Icons.directions_walk, "$walk min", appState),
                            _buildTransportModeTab("shuttle", Icons.airport_shuttle, "$shuttle min", appState),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        Text(
                          appState.endNode?.name ?? "Destination",
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E3A8A),
                          ),
                        ),
                        if (appState.classroomDetails != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            appState.classroomDetails!,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFD4AF37),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Alternative Routes Selector (Google Maps style)
                        if (appState.alternativeRoutes.length > 1) ...[
                          Text(
                            "Available Routes:",
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: List.generate(appState.alternativeRoutes.length, (index) {
                              final isSelected = (appState.selectedRouteIndex == index);
                              final distance = appState.alternativeDistances[index];
                              final time = appState.alternativeWalkTimes[index];
                              final isShortest = (index == 0); // index 0 is always the absolute shortest path
                              
                              return GestureDetector(
                                onTap: () => appState.selectRoute(index),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFE8F0FE) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF1A73E8) : Colors.black12,
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.directions_walk,
                                            size: 16,
                                            color: isSelected ? const Color(0xFF1A73E8) : Colors.black54,
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Route ${index + 1}",
                                                style: GoogleFonts.outfit(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected ? const Color(0xFF1E3A8A) : Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                "$distance km • $time min walk",
                                                style: GoogleFonts.outfit(fontSize: 11, color: Colors.black54),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (isShortest)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            "Shortest",
                                            style: GoogleFonts.outfit(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF16A34A),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 12),

                        // Metrics Summary Card
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "$displayTime min",
                              style: GoogleFonts.outfit(
                                  fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "(${appState.routeDistance} km)",
                              style: GoogleFonts.outfit(
                                  fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                routeDetail,
                                style: GoogleFonts.outfit(fontSize: 13, color: Colors.black54),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "ETA: ${appState.eta} • $modeName Mode",
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.black38, fontWeight: FontWeight.w500),
                        ),

                        const SizedBox(height: 20),

                        // Buttons Row
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Starting navigation to ${appState.endNode?.name ?? 'destination'}..."),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: const Color(0xFF16A34A),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A73E8),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text("Start", style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _showLiveViewDialog(appState),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: Colors.black12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text("Live View", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _showStepsInsideSideBox = !_showStepsInsideSideBox;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: Colors.black12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(_showStepsInsideSideBox ? "Hide Steps" : "Steps", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
                              ),
                            ),
                          ],
                        ),

                        if (_showStepsInsideSideBox) ...[
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Text("Directions:", style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
                          const SizedBox(height: 6),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: appState.directions.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.subdirectory_arrow_right, size: 13, color: Color(0xFFD4AF37)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(appState.directions[index], style: GoogleFonts.outfit(fontSize: 12, color: Colors.black87)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "LPU Campus Nav",
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Select a starting point and destination in the search bars above or click directly on any location on the map to calculate the shortest path.",
                          style: GoogleFonts.outfit(fontSize: 13, color: Colors.black54, height: 1.4),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Quick Facilities:",
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildSideCategoryChip('Hostels', Icons.hotel, 'HOSTEL', appState),
                            _buildSideCategoryChip('Buildings', Icons.business, 'BLOCK', appState),
                            _buildSideCategoryChip('Library', Icons.menu_book, 'LIBRARY', appState),
                            _buildSideCategoryChip('Mall', Icons.shopping_bag, 'MALL', appState),
                            _buildSideCategoryChip('Hospital', Icons.local_hospital, 'HOSPITAL', appState),
                            _buildSideCategoryChip('Sports', Icons.sports_soccer, 'SPORTS', appState),
                            _buildSideCategoryChip('ATM', Icons.atm, 'ATM', appState),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSideCategoryChip(String name, IconData icon, String type, AppState appState) {
    final isSelected = appState.activeFacilityType == type;
    return ChoiceChip(
      label: Text(name, style: GoogleFonts.outfit(fontSize: 11, color: isSelected ? Colors.white : const Color(0xFF1E3A8A))),
      avatar: Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF1E3A8A)),
      selected: isSelected,
      selectedColor: const Color(0xFF1D4ED8),
      backgroundColor: const Color(0xFFF1F5F9),
      onSelected: (selected) {
        if (type == 'HOSTEL' || type == 'BLOCK') {
          _toController.text = name;
          appState.getSuggestions(name);
          _toFocusNode.requestFocus();
        } else {
          appState.findNearby(type);
        }
      },
    );
  }

  // Mobile layout search card (placed at the top)
  Widget _buildRoutingHeader(AppState appState) {
    final walk = appState.walkTime;
    final cycle = appState.cycleTime;
    final shuttle = appState.shuttleTime;
    final drive = (walk * 0.3).round() + 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Mobile Profile info & simulated GPS status at the top
          _buildProfileHeader(appState),
          const SizedBox(height: 10),
          _buildGpsSimulatorRow(appState),
          const Divider(height: 20, color: Colors.black12),
          
          // 2. Mobile From/To text fields at the bottom
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
                onPressed: () {
                  appState.clearNavigation();
                  _fromController.clear();
                  _toController.clear();
                  _searchController.clear();
                },
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _fromController,
                        focusNode: _fromFocusNode,
                        style: GoogleFonts.outfit(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: "Choose start location...",
                          prefixIcon: const Icon(Icons.circle, color: Color(0xFF1A73E8), size: 10),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _toController,
                        focusNode: _toFocusNode,
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: "Choose destination...",
                          prefixIcon: const Icon(Icons.location_on, color: Colors.red, size: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Mobile search suggestions dropdown
          if (_showSuggestions && appState.searchSuggestions.isNotEmpty && (_fromFocusNode.hasFocus || _toFocusNode.hasFocus)) ...[
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxHeight: 140),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: appState.searchSuggestions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final suggestion = appState.searchSuggestions[index];
                  return ListTile(
                    dense: true,
                    title: Text(suggestion['name']!, style: GoogleFonts.outfit(fontSize: 12)),
                    onTap: () {
                      final node = appState.allNodes.firstWhere((n) => n.id == suggestion['id']);
                      if (appState.activeField == "from") {
                        appState.setStartNode(node);
                        _fromController.text = node.name;
                        _fromFocusNode.unfocus();
                      } else {
                        appState.setEndNode(node);
                        _toController.text = node.name;
                        _toFocusNode.unfocus();
                      }
                      setState(() {
                        _showSuggestions = false;
                      });
                    },
                  );
                },
              ),
            ),
          ],

          if (appState.isNavigating) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTransportModeTab("driving", Icons.directions_car, "$drive min", appState),
                _buildTransportModeTab("cycling", Icons.directions_bike, "$cycle min", appState),
                _buildTransportModeTab("walking", Icons.directions_walk, "$walk min", appState),
                _buildTransportModeTab("shuttle", Icons.airport_shuttle, "$shuttle min", appState),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransportModeTab(String mode, IconData icon, String label, AppState appState) {
    final bool isSelected = _selectedTransportMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTransportMode = mode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F0FE) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A73E8) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? const Color(0xFF1A73E8) : Colors.black54),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF1A73E8) : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeAndControlCard(AppState appState) {
    return Container(); // Disabled on mobile to prevent overlapping map layout bounds
  }

  Widget _buildCategoriesRow(AppState appState) {
    final categories = [
      {'name': 'Hostels', 'icon': Icons.hotel, 'type': 'HOSTEL'},
      {'name': 'Buildings', 'icon': Icons.business, 'type': 'BLOCK'},
      {'name': 'Library', 'icon': Icons.library_books, 'type': 'LIBRARY'},
      {'name': 'Mall', 'icon': Icons.shopping_bag, 'type': 'MALL'},
      {'name': 'Hospital', 'icon': Icons.local_hospital, 'type': 'HOSPITAL'},
      {'name': 'Sports', 'icon': Icons.sports_soccer, 'type': 'SPORTS'},
      {'name': 'ATM', 'icon': Icons.atm, 'type': 'ATM'},
    ];

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = appState.activeFacilityType == cat['type'];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ElevatedButton.icon(
              onPressed: () {
                if (cat['type'] == 'HOSTEL' || cat['type'] == 'BLOCK') {
                  _toController.text = cat['name'] as String;
                  appState.getSuggestions(cat['name'] as String);
                  _toFocusNode.requestFocus();
                } else {
                  appState.findNearby(cat['type'] as String);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? const Color(0xFFD4AF37) : Colors.white,
                foregroundColor: isSelected ? Colors.white : const Color(0xFF1E3A8A),
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              icon: Icon(cat['icon'] as IconData, size: 18),
              label: Text(
                cat['name'] as String,
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}
