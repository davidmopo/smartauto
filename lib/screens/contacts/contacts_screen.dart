import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/contact_service.dart';
import '../../models/contact.dart';
import 'upload_contacts_screen.dart';
import 'email_finder_screen.dart';
import 'email_verifier_screen.dart';

/// Main contacts screen with list view and management
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final ContactService _contactService = ContactService();
  final TextEditingController _searchController = TextEditingController();

  List<Contact> _contacts = [];
  bool _isLoading = false;
  String _searchQuery = '';
  VerificationStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;

      if (userId == null) return;

      final contacts = await _contactService.getContacts(
        userId,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _filterStatus,
      );

      setState(() => _contacts = contacts);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contacts: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            onSelected: (value) {
              switch (value) {
                case 'upload':
                  _navigateToUpload();
                  break;
                case 'finder':
                  _navigateToFinder();
                  break;
                case 'verifier':
                  _navigateToVerifier();
                  break;
                case 'manual':
                  _showAddContactDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'upload',
                child: ListTile(
                  leading: Icon(Icons.upload_file),
                  title: Text('Upload CSV'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'finder',
                child: ListTile(
                  leading: Icon(Icons.search),
                  title: Text('Find Email'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'verifier',
                child: ListTile(
                  leading: Icon(Icons.verified_user),
                  title: Text('Verify Email'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'manual',
                child: ListTile(
                  leading: Icon(Icons.person_add),
                  title: Text('Add Manually'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatsBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _contacts.isEmpty
                    ? _buildEmptyState()
                    : _buildContactsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[100],
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search contacts...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _loadContacts();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          // Debounce search
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_searchQuery == value) {
              _loadContacts();
            }
          });
        },
      ),
    );
  }

  Widget _buildStatsBar() {
    final verified = _contacts.where((c) => c.verificationStatus == VerificationStatus.verified).length;
    final pending = _contacts.where((c) => c.verificationStatus == VerificationStatus.pending).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.blue.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', _contacts.length.toString(), Colors.blue),
          _buildStatItem('Verified', verified.toString(), Colors.green),
          _buildStatItem('Pending', pending.toString(), Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.contacts_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No contacts yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add contacts to get started',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToUpload,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload CSV'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    return ListView.builder(
      itemCount: _contacts.length,
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        return _buildContactCard(contact);
      },
    );
  }

  Widget _buildContactCard(Contact contact) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            contact.initials,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          contact.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.email),
            if (contact.company != null) ...[
              const SizedBox(height: 4),
              Text(
                '${contact.position ?? 'Unknown'} at ${contact.company}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: _buildStatusBadge(contact.verificationStatus),
        onTap: () => _showContactDetails(contact),
      ),
    );
  }

  Widget _buildStatusBadge(VerificationStatus status) {
    Color color;
    String label;

    switch (status) {
      case VerificationStatus.verified:
        color = Colors.green;
        label = 'Verified';
        break;
      case VerificationStatus.invalid:
        color = Colors.red;
        label = 'Invalid';
        break;
      case VerificationStatus.risky:
        color = Colors.orange;
        label = 'Risky';
        break;
      case VerificationStatus.pending:
        color = Colors.grey;
        label = 'Pending';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Contacts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All'),
              leading: Radio<VerificationStatus?>(
                value: null,
                groupValue: _filterStatus,
                onChanged: (value) {
                  setState(() => _filterStatus = value);
                  Navigator.pop(context);
                  _loadContacts();
                },
              ),
            ),
            ...VerificationStatus.values.map((status) {
              return ListTile(
                title: Text(status.name.toUpperCase()),
                leading: Radio<VerificationStatus?>(
                  value: status,
                  groupValue: _filterStatus,
                  onChanged: (value) {
                    setState(() => _filterStatus = value);
                    Navigator.pop(context);
                    _loadContacts();
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showContactDetails(Contact contact) {
    // TODO: Navigate to contact details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Contact details for ${contact.fullName}')),
    );
  }

  void _showAddContactDialog() {
    // TODO: Implement manual contact addition
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Manual contact addition coming soon')),
    );
  }

  Future<void> _navigateToUpload() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UploadContactsScreen()),
    );

    if (result == true) {
      _loadContacts();
    }
  }

  Future<void> _navigateToFinder() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmailFinderScreen()),
    );
    _loadContacts();
  }

  Future<void> _navigateToVerifier() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmailVerifierScreen()),
    );
  }
}

