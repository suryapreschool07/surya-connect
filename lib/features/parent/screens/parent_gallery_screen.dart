import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/providers.dart';
import '../../../shared/widgets/widgets.dart';

class ParentGalleryScreen extends ConsumerWidget {
  const ParentGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [...ref.watch(dataRepositoryProvider).data.gallery]
      ..sort((a, b) => b.date.compareTo(a.date));

    if (items.isEmpty) {
      return const EmptyState(message: 'No gallery items yet.');
    }

    return GridView.builder(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                      Text(item.date, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
