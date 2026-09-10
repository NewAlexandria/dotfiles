from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from twscrape.models import Media, MediaAnimated, MediaPhoto, MediaVideo, Tweet, User


def _iso_date(dt: datetime) -> str:
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc).isoformat()


def _orig_photo_url(url: str) -> str:
    if "pbs.twimg.com" in url:
        base = url.split("?")[0]
        return f"{base}?format=jpg&name=orig"
    return url


def _best_video_url(video: MediaVideo) -> str | None:
    if not video.variants:
        return None
    best = max(video.variants, key=lambda v: v.bitrate)
    return best.url


def extract_media_items(media: Media | None) -> list[dict[str, Any]]:
    if media is None:
        return []
    items: list[dict[str, Any]] = []
    for i, photo in enumerate(media.photos):
        items.append(
            {
                "type": "photo",
                "index": i,
                "url": _orig_photo_url(photo.url),
                "local_path": None,
                "sha256": None,
                "bytes": None,
                "downloaded_at": None,
            }
        )
    for i, video in enumerate(media.videos):
        url = _best_video_url(video)
        items.append(
            {
                "type": "video",
                "index": i,
                "url": url,
                "thumbnail_url": video.thumbnailUrl,
                "duration_ms": video.duration,
                "local_path": None,
                "sha256": None,
                "bytes": None,
                "downloaded_at": None,
            }
        )
    for i, anim in enumerate(media.animated):
        items.append(
            {
                "type": "gif",
                "index": i,
                "url": anim.videoUrl,
                "thumbnail_url": anim.thumbnailUrl,
                "local_path": None,
                "sha256": None,
                "bytes": None,
                "downloaded_at": None,
            }
        )
    return items


def normalize_tweet(tweet: Tweet, source: str = "twscrape", raw_path: str | None = None) -> dict[str, Any]:
    author: User = tweet.user
    quoted_id = None
    if tweet.quotedTweet is not None:
        quoted_id = tweet.quotedTweet.id_str or str(tweet.quotedTweet.id)

    links = [lnk.url for lnk in (tweet.links or []) if getattr(lnk, "url", None)]

    return {
        "tweet_id": tweet.id_str or str(tweet.id),
        "timestamp": _iso_date(tweet.date),
        "permalink": tweet.url,
        "author": {
            "id": author.id_str or str(author.id),
            "username": author.username,
            "displayname": author.displayname,
        },
        "text": tweet.rawContent or "",
        "lang": tweet.lang,
        "urls": links,
        "media": extract_media_items(tweet.media),
        "quoted_tweet_id": quoted_id,
        "conversation_id": tweet.conversationIdStr or (
            str(tweet.conversationId) if tweet.conversationId else None
        ),
        "in_reply_to_tweet_id": tweet.inReplyToTweetIdStr or (
            str(tweet.inReplyToTweetId) if tweet.inReplyToTweetId else None
        ),
        "metrics": {
            "reply_count": tweet.replyCount,
            "retweet_count": tweet.retweetCount,
            "like_count": tweet.likeCount,
            "quote_count": tweet.quoteCount,
        },
        "source": source,
        "raw_path": raw_path,
    }


def profile_from_user(user: User) -> dict[str, Any]:
    return {
        "id": user.id_str or str(user.id),
        "username": user.username,
        "displayname": user.displayname,
        "description": user.rawDescription,
        "created": _iso_date(user.created) if user.created else None,
        "followers_count": user.followersCount,
        "statuses_count": user.statusesCount,
        "verified": user.verified,
        "profile_url": user.url,
        "archived_at": datetime.now(timezone.utc).isoformat(),
    }
