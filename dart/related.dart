import 'dart:convert';
import 'dart:io';

import 'models.dart';

void main() {
  final postsJson = jsonDecode(File('../posts.json').readAsStringSync()) as List<dynamic>;

  final posts = postsJson.map(Post.fromJson).toList();

  final sw = Stopwatch()..start();

  final (_, tagMap) = posts.fold<(int, Map<String, List<int>>)>(
    (0, {}),
    (state, post) {
      for (final tag in post.tags) {
        state.$2.update(
          tag,
          (list) => list..add(state.$1),
          ifAbsent: () => [state.$1],
        );
      }

      return (state.$1 + 1, state.$2);
    },
  );

  // preallocate and reuse
  final taggedPostCount = List.filled(posts.length, 0);

  final allRelatedPosts = List.generate(posts.length, (i) {
    final post = posts[i];
    taggedPostCount.fillRange(0, posts.length, 0);

    for (final tag in post.tags) {
      for (var otherPostIdx in tagMap[tag]!) {
        taggedPostCount[otherPostIdx] += 1;
      }
    }

    taggedPostCount[i] = 0; // don't include self

    final top5 = List.filled(5, (idx: 0, count: 0), growable: true);
    var minTags = 0;

    // priority queue to keep track of top 5
    for (var i = 0; i < taggedPostCount.length; i++) {
      final count = taggedPostCount[i];
      if (count > minTags) {
        var pos = 4;

        while (pos >= 0 && count > top5[pos].count) {
          pos -= 1;
        }

        pos += 1;

        top5.insert(pos, (idx: i, count: count));
        top5.removeLast();

        minTags = top5.last.count;
      }
    }

    return {
      "_id": post.iD,
      "tags": post.tags,
      "related": top5.map((v) => posts[v.idx]).toList(),
    };
  });

  print('Processing time (w/o IO): ${sw.elapsedMilliseconds}ms');

  File('../related_posts_dart.json').writeAsStringSync(jsonEncode(allRelatedPosts));
}
