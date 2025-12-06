import 'package:flutter/material.dart';
import 'create-facility.dart';
import 'facilities-list.dart';
import 'delete-facility.dart';
// import 'facility-by-id.dart';
import 'facility-statistics.dart';
import 'facility-search.dart';
import 'facility-update.dart';

class FacilityManagementPage extends StatelessWidget {
  final String userEmail;
  const FacilityManagementPage({super.key, required this.userEmail});

  Widget _buildFacilityCard({
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title, 
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Create Facility
            _buildFacilityCard(
              icon: Icons.add_business,
              title: 'Create New Facility',
              iconColor: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FacilityProfilePage()),
                );
              },
            ),

            // Get All Facilities
            _buildFacilityCard(
              icon: Icons.business,
              title: 'View All Facilities',
              iconColor: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FacilitiesListPage()),
                );
              },
            ),

            // Get Specific Facility
            _buildFacilityCard(
              icon: Icons.search,
              title: 'Find Facility by Name',
              iconColor: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FacilitySearchPage()),
                );
              },
            ),

            // // Search Facilities
            // _buildFacilityCard(
            //   icon: Icons.find_in_page,
            //   title: 'Search Facilities',
            //   iconColor: Colors.green,
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => const FacilitySearchPage()),
            //     );
            //   },
            // ),

            // Get Statistics
            _buildFacilityCard(
              icon: Icons.analytics,
              title: 'Facility Statistics',
              iconColor: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FacilityStatisticsPage()),
                );
              },
            ),

            // Update Facility
            _buildFacilityCard(
              icon: Icons.edit,
              title: 'Update Facility Details',
              iconColor: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UpdateFacilityPage()),
                );
              },
            ),

            // Delete Facility
            _buildFacilityCard(
              icon: Icons.delete_forever,
              title: 'Delete Facility',
              iconColor: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DeleteFacilityPage()),
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}