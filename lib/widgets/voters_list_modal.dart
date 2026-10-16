import 'package:flutter/material.dart';

void showVotersModal({
  required BuildContext context,
  required String itemName,
  required String meal,
  required List<String> yesVoters,
  required List<String> noVoters,
  String initialTab = 'yes',
  String? vendorName,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => VotersListModal(
      itemName: itemName,
      meal: meal,
      vendorName: vendorName,
      yesVoters: yesVoters,
      noVoters: noVoters,
      initialTab: initialTab,
    ),
  );
}

class VotersListModal extends StatefulWidget {
  final String itemName;
  final String meal;
  final String? vendorName;
  final List<String> yesVoters;
  final List<String> noVoters;
  final String initialTab;

  const VotersListModal({
    super.key,
    required this.itemName,
    required this.meal,
    this.vendorName,
    required this.yesVoters,
    required this.noVoters,
    this.initialTab = 'yes',
  });

  @override
  State<VotersListModal> createState() => _VotersListModalState();
}

class _VotersListModalState extends State<VotersListModal> {
  late String _activeTab = widget.initialTab;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return '?';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isYes = _activeTab == 'yes';
    final currentList = isYes ? widget.yesVoters : widget.noVoters;
    final filteredList = _searchQuery.isEmpty
        ? currentList
        : currentList
            .where((name) => name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0D8D0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7ECE4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.meal.toUpperCase()} ${widget.vendorName != null ? '• ${widget.vendorName}' : ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8A3B18),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.itemName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF221711),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.yesVoters.length + widget.noVoters.length} total staff voted',
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF8A827A)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF8A827A)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Segmented Tabs: Yes / No
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5EFE6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Yes Tab
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _activeTab = 'yes';
                          _searchCtrl.clear();
                          _searchQuery = '';
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isYes ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isYes
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.thumb_up_rounded,
                              size: 16,
                              color: isYes ? const Color(0xFF2E7D32) : const Color(0xFF70655E),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Interested (${widget.yesVoters.length})',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isYes ? const Color(0xFF1B5E20) : const Color(0xFF70655E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // No Tab
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _activeTab = 'no';
                          _searchCtrl.clear();
                          _searchQuery = '';
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !isYes ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: !isYes
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.thumb_down_rounded,
                              size: 16,
                              color: !isYes ? const Color(0xFFD32F2F) : const Color(0xFF70655E),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Not Interested (${widget.noVoters.length})',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: !isYes ? const Color(0xFFB71C1C) : const Color(0xFF70655E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Optional Search bar if count > 4
            if (currentList.length > 4) ...[
              TextField(
                controller: _searchCtrl,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search people...',
                  hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF8A827A)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF8A827A)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFFBF8F3),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFEFE8DE)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFEFE8DE)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // People List
            Expanded(
              child: filteredList.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isYes ? const Color(0xFFF0F8F1) : const Color(0xFFFDF2F0),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isYes ? Icons.thumb_up_alt_outlined : Icons.thumb_down_alt_outlined,
                                size: 36,
                                color: isYes ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No matching people found'
                                  : isYes
                                      ? 'Nobody voted "Yes" yet'
                                      : 'Nobody voted "No" yet',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF221711),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Try typing a different name'
                                  : isYes
                                      ? 'Staff who want this dish will be listed here.'
                                      : 'Staff who declined this dish will appear here.',
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF8A827A)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredList.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final personName = filteredList[i];
                        final initials = _getInitials(personName);

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBF8F3),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isYes ? const Color(0xFFE0EFE2) : const Color(0xFFF8E3E1),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Avatar Circle
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isYes ? const Color(0xFFE8F5E9) : const Color(0xFFFDECE8),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                    color: isYes ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Name
                              Expanded(
                                child: Text(
                                  personName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF221711),
                                  ),
                                ),
                              ),

                              // Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isYes ? const Color(0xFFE8F5E9) : const Color(0xFFFDECE8),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isYes ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                      size: 13,
                                      color: isYes ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isYes ? 'Yes' : 'No',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: isYes ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 14),

            // Done Button
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF221711),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}
