// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:transport_app/controllers/map_controller.dart';
// import 'package:transport_app/services/location_service.dart';

// class ExpandableSearchBar extends StatefulWidget {
//   const ExpandableSearchBar({super.key});

//   @override
//   State<ExpandableSearchBar> createState() => _ExpandableSearchBarState();
// }

// class _ExpandableSearchBarState extends State<ExpandableSearchBar>
//     with SingleTickerProviderStateMixin {
//   bool _isExpanded = false;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _scaleAnimation;
//   final FocusNode _focusNode = FocusNode();
//   final MapControllerr mapController = Get.find<MapControllerr>();

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 250),
//       vsync: this,
//     );

//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeOut,
//     ));

//     _scaleAnimation = Tween<double>(
//       begin: 0.8,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.elasticOut,
//     ));
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _focusNode.dispose();
//     super.dispose();
//   }

//   void _toggleSearch() {
//     setState(() {
//       _isExpanded = !_isExpanded;
//     });

//     if (_isExpanded) {
//       _animationController.forward();
//       Future.delayed(const Duration(milliseconds: 100), () {
//         _focusNode.requestFocus();
//       });
//     } else {
//       _animationController.reverse();
//       _focusNode.unfocus();
//       mapController.searchController.clear();
//       mapController.searchResults.clear();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Positioned(
//       top: MediaQuery.of(context).padding.top + 16,
//       left: 16,
//       right: 16,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//         height: 48,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(24),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.06),
//               blurRadius: 16,
//               offset: const Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             // Menu button - always visible
//             Container(
//               margin: const EdgeInsets.only(left: 6),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 shape: BoxShape.circle,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.08),
//                     blurRadius: 10,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Builder(
//                 builder: (ctx) => IconButton(
//                   icon: const Icon(Icons.menu, color: Colors.black54),
//                   onPressed: () => Scaffold.of(ctx).openDrawer(),
//                 ),
//               ),
//             ),

//             // Search content area
//             Expanded(
//               child: AnimatedSwitcher(
//                 duration: const Duration(milliseconds: 300),
//                 child: _isExpanded ? _buildExpandedSearch() : _buildCollapsedSearch(),
//               ),
//             ),

//             // Search button
//             Container(
//               margin: const EdgeInsets.only(right: 4),
//               decoration: BoxDecoration(
//                 color: _isExpanded ? Colors.red.shade400 : Colors.orange.shade400,
//                 shape: BoxShape.circle,
//               ),
//               child: IconButton(
//                 icon: Icon(
//                   _isExpanded ? Icons.close : Icons.search,
//                   color: Colors.white,
//                   size: 20,
//                 ),
//                 onPressed: _toggleSearch,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCollapsedSearch() {
//     return GestureDetector(
//       key: const Key('collapsed'),
//       onTap: _toggleSearch,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         child: Obx(() {
//           // إظهار الموقع الحالي بدلاً من النص الافتراضي
//           String displayText;
//           if (mapController.selectedAddress.value.isNotEmpty) {
//             displayText = mapController.selectedAddress.value;
//           } else if (mapController.currentAddress.value.isNotEmpty) {
//             displayText = 'موقعي الحالي: ${mapController.currentAddress.value}';
//           } else {
//             displayText = 'إلى أين تريد الذهاب؟';
//           }

//           return Row(
//             children: [
//               // أيقونة الموقع الحالي
//               Container(
//                 width: 24,
//                 height: 24,
//                 decoration: BoxDecoration(
//                   color: Colors.blue.shade50,
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   mapController.selectedAddress.value.isNotEmpty
//                     ? Icons.location_on
//                     : Icons.my_location,
//                   color: mapController.selectedAddress.value.isNotEmpty
//                     ? Colors.red.shade400
//                     : Colors.blue.shade400,
//                   size: 14,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   displayText,
//                   style: TextStyle(
//                     color: mapController.selectedAddress.value.isNotEmpty
//                         ? Colors.black87
//                         : mapController.currentAddress.value.isNotEmpty
//                             ? Colors.blue.shade700
//                             : Colors.grey.shade600,
//                     fontWeight: mapController.selectedAddress.value.isNotEmpty ||
//                                 mapController.currentAddress.value.isNotEmpty
//                         ? FontWeight.w500
//                         : FontWeight.normal,
//                     fontSize: 14,
//                   ),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           );
//         }),
//       ),
//     );
//   }

//   Widget _buildExpandedSearch() {
//     return ScaleTransition(
//       key: const Key('expanded'),
//       scale: _scaleAnimation,
//       child: FadeTransition(
//         opacity: _fadeAnimation,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 8),
//           child: Column(
//             children: [
//               // Search TextField
//               Expanded(
//                 child: TextField(
//                   controller: mapController.searchController,
//                   focusNode: _focusNode,
//                   textDirection: TextDirection.rtl,
//                   style: const TextStyle(fontSize: 14),
//                   decoration: InputDecoration(
//                     hintText: 'ابحث عن موقع...',
//                     hintStyle: const TextStyle(
//                       color: Colors.grey,
//                       fontSize: 13,
//                     ),
//                     border: InputBorder.none,
//                     contentPadding: const EdgeInsets.symmetric(horizontal: 12),
//                     prefixIcon: Padding(
//                       padding: const EdgeInsets.all(12),
//                       child: Icon(
//                         Icons.search,
//                         size: 18,
//                         color: Colors.grey.shade400,
//                       ),
//                     ),
//                   ),
//                   onChanged: (value) {
//                     if (value.isNotEmpty) {
//                       mapController.searchLocation(value);
//                     } else {
//                       mapController.searchResults.clear();
//                     }
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Search Results Overlay Widget - Enhanced with current location option
// class SearchResultsOverlay extends StatelessWidget {
//   const SearchResultsOverlay({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final mapController = Get.find<MapControllerr>();

//     return Obx(() {
//       if (mapController.searchResults.isEmpty && !mapController.isSearching.value) {
//         return const SizedBox.shrink();
//       }

//       return Positioned(
//         top: MediaQuery.of(context).padding.top + 75, // Below search bar
//         left: 16,
//         right: 16,
//         child: Container(
//           constraints: BoxConstraints(
//             maxHeight: MediaQuery.of(context).size.height * 0.4,
//           ),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 20,
//                 offset: const Offset(0, 8),
//               ),
//             ],
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Search loading indicator
//               if (mapController.isSearching.value)
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   child: const Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: Colors.orange,
//                         ),
//                       ),
//                       SizedBox(width: 12),
//                       Text('جاري البحث...'),
//                     ],
//                   ),
//                 ),

//               // Current location option (always show first)
//               if (!mapController.isSearching.value &&
//                   mapController.searchController.text.isNotEmpty &&
//                   mapController.currentAddress.value.isNotEmpty)
//                 Container(
//                   margin: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.shade50,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: Colors.blue.shade200),
//                   ),
//                   child: ListTile(
//                     leading: Container(
//                       width: 40,
//                       height: 40,
//                       decoration: BoxDecoration(
//                         color: Colors.blue.shade100,
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(
//                         Icons.my_location,
//                         color: Colors.blue.shade600,
//                         size: 20,
//                       ),
//                     ),
//                     title: const Text(
//                       'موقعي الحالي',
//                       style: TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 14,
//                       ),
//                     ),
//                     subtitle: Text(
//                       mapController.currentAddress.value,
//                       style: TextStyle(
//                         color: Colors.blue.shade700,
//                         fontSize: 12,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     onTap: () {
//                       if (mapController.currentLocation.value != null) {
//                         mapController.selectLocationFromMap(mapController.currentLocation.value!);
//                         // Hide search results and collapse search bar
//                         Future.delayed(const Duration(milliseconds: 100), () {
//                           if (context.mounted) {
//                             final searchBarState = context.findAncestorStateOfType<_ExpandableSearchBarState>();
//                             searchBarState?._toggleSearch();
//                           }
//                         });
//                       }
//                     },
//                   ),
//                 ),

//               // Search results
//               if (!mapController.isSearching.value && mapController.searchResults.isNotEmpty)
//                 Flexible(
//                   child: ListView.separated(
//                     shrinkWrap: true,
//                     padding: const EdgeInsets.all(8),
//                     itemCount: mapController.searchResults.length,
//                     separatorBuilder: (context, index) => Divider(
//                       height: 1,
//                       color: Colors.grey.shade200,
//                     ),
//                     itemBuilder: (context, index) {
//                       final result = mapController.searchResults[index];
//                       return ListTile(
//                         leading: Container(
//                           width: 40,
//                           height: 40,
//                           decoration: BoxDecoration(
//                             color: Colors.orange.shade50,
//                             shape: BoxShape.circle,
//                           ),
//                           child: Icon(
//                             Icons.location_on,
//                             color: Colors.orange.shade600,
//                             size: 20,
//                           ),
//                         ),
//                         title: Text(
//                           result.name,
//                           style: const TextStyle(
//                             fontWeight: FontWeight.w600,
//                             fontSize: 14,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         subtitle: Text(
//                           result.address,
//                           style: TextStyle(
//                             color: Colors.grey.shade600,
//                             fontSize: 12,
//                           ),
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         trailing: mapController.currentLocation.value != null
//                             ? Text(
//                                 '${LocationService.to.calculateDistance(
//                                   mapController.currentLocation.value!,
//                                   result.latLng,
//                                 ).toStringAsFixed(1)} كم',
//                                 style: TextStyle(
//                                   color: Colors.grey.shade500,
//                                   fontSize: 11,
//                                 ),
//                               )
//                             : null,
//                         onTap: () {
//                           mapController.selectLocationFromSearch(result);
//                           // Hide search results and collapse search bar
//                           Future.delayed(const Duration(milliseconds: 100), () {
//                             if (context.mounted) {
//                               final searchBarState = context.findAncestorStateOfType<_ExpandableSearchBarState>();
//                               searchBarState?._toggleSearch();
//                             }
//                           });
//                         },
//                       );
//                     },
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       );
//     });
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/map_controller.dart';
import 'package:transport_app/controllers/map_controller_copy.dart';
import 'package:transport_app/services/location_service.dart';

class ExpandableSearchBar extends StatefulWidget {
  const ExpandableSearchBar({super.key});

  @override
  State<ExpandableSearchBar> createState() => _ExpandableSearchBarState();
}

class _ExpandableSearchBarState extends State<ExpandableSearchBar>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final FocusNode _focusNode = FocusNode();
  final MapControllerr mapController = Get.find<MapControllerr>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
      Future.delayed(const Duration(milliseconds: 100), () {
        _focusNode.requestFocus();
      });
    } else {
      _animationController.reverse();
      _focusNode.unfocus();
      mapController.searchController.clear();
      mapController.searchResults.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Menu button - always visible
            Container(
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black54),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
            ),

            // Search content area
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isExpanded
                    ? _buildExpandedSearch()
                    : _buildCollapsedSearch(),
              ),
            ),

            // Search button
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color:
                    _isExpanded ? Colors.red.shade400 : Colors.orange.shade400,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  _isExpanded ? Icons.close : Icons.search,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _toggleSearch,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedSearch() {
    return GestureDetector(
      key: const Key('collapsed'),
      onTap: _toggleSearch,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Obx(() {
          // إظهار الموقع الحالي بدلاً من النص الافتراضي
          String displayText;
          if (mapController.selectedAddress.value.isNotEmpty) {
            displayText = mapController.selectedAddress.value;
          } else if (mapController.currentAddress.value.isNotEmpty) {
            displayText = 'موقعي الحالي: ${mapController.currentAddress.value}';
          } else {
            displayText = 'إلى أين تريد الذهاب؟';
          }

          return Row(
            children: [
              // أيقونة الموقع الحالي
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  mapController.selectedAddress.value.isNotEmpty
                      ? Icons.location_on
                      : Icons.my_location,
                  color: mapController.selectedAddress.value.isNotEmpty
                      ? Colors.red.shade400
                      : Colors.blue.shade400,
                  size: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayText,
                  style: TextStyle(
                    color: mapController.selectedAddress.value.isNotEmpty
                        ? Colors.black87
                        : mapController.currentAddress.value.isNotEmpty
                            ? Colors.blue.shade700
                            : Colors.grey.shade600,
                    fontWeight:
                        mapController.selectedAddress.value.isNotEmpty ||
                                mapController.currentAddress.value.isNotEmpty
                            ? FontWeight.w500
                            : FontWeight.normal,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildExpandedSearch() {
    return ScaleTransition(
      key: const Key('expanded'),
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              // Search TextField
              Expanded(
                child: TextField(
                  controller: mapController.searchController,
                  focusNode: _focusNode,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'ابحث عن موقع...',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      mapController.searchLocation(value);
                    } else {
                      mapController.searchResults.clear();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Search Results Overlay Widget
class SearchResultsOverlay extends StatelessWidget {
  const SearchResultsOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final mapController = Get.find<MapControllerr>();

    return Obx(() {
      if (mapController.searchResults.isEmpty &&
          !mapController.isSearching.value) {
        return const SizedBox.shrink();
      }

      return Positioned(
        top: MediaQuery.of(context).padding.top + 75, // Below search bar
        left: 16,
        right: 16,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search loading indicator
              if (mapController.isSearching.value)
                Container(
                  padding: const EdgeInsets.all(20),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('جاري البحث...'),
                    ],
                  ),
                ),

              // Current location option (always show first)
              if (!mapController.isSearching.value &&
                  mapController.searchController.text.isNotEmpty &&
                  mapController.currentAddress.value.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.my_location,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'موقعي الحالي',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      mapController.currentAddress.value,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      if (mapController.currentLocation.value != null) {
                        mapController.selectLocationFromMap(
                            mapController.currentLocation.value!);
                        // Hide search results and collapse search bar
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (context.mounted) {
                            final searchBarState =
                                context.findAncestorStateOfType<
                                    _ExpandableSearchBarState>();
                            searchBarState?._toggleSearch();
                          }
                        });
                      }
                    },
                  ),
                ),

              // Search results
              if (!mapController.isSearching.value &&
                  mapController.searchResults.isNotEmpty)
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: mapController.searchResults.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                    ),
                    itemBuilder: (context, index) {
                      final result = mapController.searchResults[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: Colors.orange.shade600,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          result.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          result.address,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: mapController.currentLocation.value != null
                            ? Text(
                                '${LocationService.to.calculateDistance(
                                      mapController.currentLocation.value!,
                                      result.latLng,
                                    ).toStringAsFixed(1)} كم',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                ),
                              )
                            : null,
                        onTap: () {
                          mapController.selectLocationFromSearch(result);
                          // Hide search results and collapse search bar
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (context.mounted) {
                              // Find the search bar widget in the tree and collapse it
                              final searchBarState =
                                  context.findAncestorStateOfType<
                                      _ExpandableSearchBarState>();
                              searchBarState?._toggleSearch();
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}
