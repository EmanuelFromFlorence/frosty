import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:frosty/core/auth/auth_store.dart';
import 'package:frosty/models/category.dart';
import 'package:frosty/screens/categories/category_streams_list/category_streams.dart';
import 'package:frosty/screens/categories/category_streams_list/category_streams_store.dart';
import 'package:provider/provider.dart';

/// A tappable card widget that displays a category's box art and name.
class CategoryCard extends StatelessWidget {
  final CategoryTwitch category;

  const CategoryCard({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return CategoryStreams(
                store: CategoryStreamsStore(
                  categoryInfo: category,
                  authStore: context.read<AuthStore>(),
                ),
              );
            },
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
        child: Column(
          children: [
            Expanded(
              child: Hero(
                tag: category.id,
                child: CachedNetworkImage(
                  imageUrl: category.boxArtUrl.replaceFirst('-{width}x{height}', '-300x400'),
                ),
              ),
            ),
            const SizedBox(height: 5.0),
            Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
