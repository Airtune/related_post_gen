import heapq
import json
import time
from collections import Counter


def main():
    with open("../posts.json") as f:
        posts = json.load(f)

    start = time.monotonic()

    tag_map = {}
    for idx, post in enumerate(posts):
        for tag in post["tags"]:
            if tag not in tag_map:
                tag_map[tag] = []
            tag_map[tag].append(idx)

    all_related_posts = []
    for this_post_idx, post in enumerate(posts):
        related_posts_list = Counter((p for tag in post["tags"] for p in tag_map[tag]))
        related_posts_list[this_post_idx] = 0

        top_posts = [
            {k: posts[p][k] for k in ("_id", "title", "tags")}
            for p in heapq.nlargest(5, related_posts_list, key=related_posts_list.get)
        ]

        all_related_posts.append(
            {
                "_id": post["_id"],
                "tags": post["tags"],
                "related": top_posts,
            }
        )

    end = time.monotonic()

    print(f"Processing time (w/o IO): {end - start:.3f}s")

    with open("../related_posts_python.json", "w") as f:
        json.dump(all_related_posts, f)


if __name__ == "__main__":
    main()
