// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2021-2026 Krille Fear / FluffyChat Contributors
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-09: Add notes overview drawer (Issue #25) - Simon
// - 2026-02-09: Integrate drawer navigation for notes rooms - Simon
// - 2026-02-09: Add fuzzy search + tag filtering for notes - Simon
// - 2026-02-09: Allow creating room tags from notes drawer - Simon
// - 2026-02-09: Make drawer fullscreen width on mobile - Simon
// - 2026-02-09: Show timestamps (date + time) in overview list - Simon
// - 2026-02-09: Add tag filter dropdown for notes overview - Simon
// - 2026-02-09: Remove top-left rounding on mobile drawer (Issue #25) - Simon

import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/filtered_timeline_extension.dart';
import 'package:fluffychat/utils/room_tags_extension.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_text_input_dialog.dart';

/// Drawer which lists all note events in the current room.
///
/// A note event is a `m.room.message` with `im.ffchat.note` in the content.
class NotesOverviewDrawer extends StatefulWidget {
  final ChatController controller;
  const NotesOverviewDrawer({super.key, required this.controller});

  @override
  State<NotesOverviewDrawer> createState() => _NotesOverviewDrawerState();
}

class _NotesOverviewDrawerState extends State<NotesOverviewDrawer> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedTag;

  Future<void> _createTag() async {
    final controller = widget.controller;
    final input = await showTextInputDialog(
      context: context,
      title: 'Create tag',
      okLabel: L10n.of(context).ok,
      cancelLabel: L10n.of(context).cancel,
    );
    final tag = (input ?? '').trim();
    if (tag.isEmpty) return;
    final tags = controller.room.roomTags;
    if (!tags.contains(tag)) {
      await controller.room.setRoomTags([...tags, tag]);
    }
    if (!mounted) return;
    setState(() => _selectedTag = tag);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _fuzzyContains(String haystack, String needle) {
    final h = haystack.toLowerCase();
    final n = needle.toLowerCase();
    if (n.isEmpty) return true;
    var i = 0;
    for (var j = 0; j < h.length && i < n.length; j++) {
      if (h.codeUnitAt(j) == n.codeUnitAt(i)) i++;
    }
    return i == n.length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    final screenWidth = MediaQuery.of(context).size.width;
    // Fullscreen on mobile (keep default Drawer width on larger screens).
    final isMobile = screenWidth < 600;

    final controller = widget.controller;
    final timeline = controller.timeline;
    final events =
        timeline?.events.filterByVisibleInGui(
          threadId: controller.activeThreadId,
        ) ??
        const <Event>[];

    final notes = events.where((e) {
      final display = timeline == null ? e : e.getDisplayEvent(timeline);
      final content = display.content;
      if (content is! Map) return false;
      return (content as Map).containsKey('im.ffchat.note');
    }).toList();

    final allTags = controller.room.roomTags;
    final query = _searchController.text.trim();

    final filteredNotes = notes.where((event) {
      final display = timeline == null
          ? event
          : event.getDisplayEvent(timeline);
      final map = (display.content as Map).cast<String, Object?>();
      final note = map['im.ffchat.note'];
      final title = (note is Map) ? note['title']?.toString() : null;
      final body = (note is Map) ? note['body']?.toString() : null;
      final tags = (note is Map) ? note['tags'] : null;
      final hasTag =
          _selectedTag == null ||
          (_selectedTag!.isNotEmpty &&
              tags is List &&
              tags.map((e) => e?.toString()).contains(_selectedTag));
      if (!hasTag) return false;
      if (query.isEmpty) return true;
      final text = '${title ?? ''}\n${body ?? ''}\n${display.body}';
      return _fuzzyContains(text, query);
    }).toList();

    final drawerChild = SafeArea(
      child: Column(
        children: [
          ListTile(
            title: Text(l10n.notesOverview),
            trailing: IconButton(
              tooltip: l10n.close,
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.search,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (allTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTag,
                  hint: const Text('Tag'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All'),
                    ),
                    ...allTags.map(
                      (t) => DropdownMenuItem<String>(value: t, child: Text(t)),
                    ),
                    const DropdownMenuItem<String>(
                      value: '__create__',
                      child: Text('+ Create tag'),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value == '__create__') {
                      await _createTag();
                      return;
                    }
                    setState(() => _selectedTag = value);
                  },
                ),
              ),
            ),
          Expanded(
            child: filteredNotes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(l10n.noResultsFound),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      final event = filteredNotes[index];
                      final display = timeline == null
                          ? event
                          : event.getDisplayEvent(timeline);
                      final map = (display.content as Map)
                          .cast<String, Object?>();
                      final note = map['im.ffchat.note'];
                      final title = (note is Map)
                          ? note['title']?.toString().trim()
                          : null;
                      final body = (note is Map)
                          ? note['body']?.toString().trim()
                          : null;

                      final primary = (title?.isNotEmpty ?? false)
                          ? title!
                          : display.body.split('\n').firstOrNull ?? '';
                      final secondary = (body?.isNotEmpty ?? false)
                          ? body!
                          : null;

                      return ListTile(
                        title: Text(
                          primary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              display.originServerTs.localizedTime(context),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            if (secondary != null)
                              Text(
                                secondary,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          controller.scrollToEventId(display.eventId);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );

    return Drawer(
      width: isMobile ? screenWidth : null,
      shape: isMobile
          ? const RoundedRectangleBorder(borderRadius: BorderRadius.zero)
          : null,
      child: drawerChild,
    );
  }
}
