import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/providers.dart';
import '../../../shared/widgets/widgets.dart';

class AdminGalleryScreen extends ConsumerStatefulWidget {
  const AdminGalleryScreen({super.key});

  @override
  ConsumerState<AdminGalleryScreen> createState() => _AdminGalleryScreenState();
}

class _AdminGalleryScreenState extends ConsumerState<AdminGalleryScreen> {
  Future<void> _addItem() async {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    var type = 'photo';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Add Gallery Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'photo', child: Text('Photo URL / Upload')),
                  DropdownMenuItem(value: 'youtube', child: Text('YouTube Link')),
                ],
                onChanged: (v) => setLocal(() => type = v ?? 'photo'),
              ),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              if (type == 'youtube')
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(labelText: 'YouTube URL'),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
          ],
        ),
      ),
    );

    if (ok != true) return;
    var url = urlCtrl.text.trim();
    var thumb = '';

    if (type == 'photo') {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        final bytes = await file.readAsBytes();
        final session = await ref.read(authServiceProvider).loadSession();
        url = await ref.read(apiClientProvider).uploadMedia(
              token: session.token,
              base64Data: base64Encode(bytes),
              fileName: file.name,
              mimeType: 'image/jpeg',
            );
        thumb = url;
      } else if (url.isEmpty) {
        return;
      }
    }

    final session = await ref.read(authServiceProvider).loadSession();
    await ref.read(apiClientProvider).crud(
          'gallery',
          'create',
          token: session.token,
          data: {
            'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
            'type': type,
            'title': titleCtrl.text.trim(),
            'url': url,
            'thumbnailUrl': thumb,
          },
        );
    await ref.read(syncDataProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final items = [...ref.watch(dataRepositoryProvider).data.gallery]
      ..sort((a, b) => b.date.compareTo(a.date));

    return Stack(
      children: [
        items.isEmpty
            ? const EmptyState(message: 'No gallery items yet.')
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  return GestureDetector(
                    onTap: () async {
                      if (item.isYoutube) {
                        await launchUrl(Uri.parse(item.url), mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: item.isYoutube
                                ? Container(
                                    color: Colors.black12,
                                    child: const Icon(Icons.play_circle_fill, size: 48),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: item.url,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _addItem,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
