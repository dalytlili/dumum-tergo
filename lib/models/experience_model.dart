// lib/models/experience_model.dart
import 'dart:convert';

class Experience {
  final String id;
  final User user;
  final String description;
  final List<ExperienceImage> images;
  final List<dynamic> likes;
  final List<dynamic> tags;
  final List<dynamic> comments;
  final DateTime createdAt;
  final int version;
    bool? isFavorite;


  Experience({
    required this.id,
    required this.user,
    required this.description,
    required this.images,
    required this.likes,
    required this.tags,
    required this.comments,
    required this.createdAt,
    required this.version,
        this.isFavorite,

  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      id: json['_id'],
      user: User.fromJson(json['user']),
      description: json['description'],
      images: (json['images'] as List)
          .map((img) => ExperienceImage.fromJson(img))
          .toList(),
      likes: json['likes'] ?? [],
            isFavorite: json['isFavorite'] ?? false,

      tags: json['tags'] ?? [],
      comments: (json['comments'] as List?)?.map((comment) {
        if (comment is Map) return comment;
        return {'text': comment.toString()}; // Fallback pour les commentaires mal formatés
      }).toList() ?? [],
      createdAt: DateTime.parse(json['createdAt']),
      version: json['__v'],
    );
  }

  bool isLikedByUser(String userId) {
    return likes.any((like) {
      if (like is String) {
        return like == userId;
      } else if (like is Map) {
        return like['_id'] == userId || like['user'] == userId;
      }
      return false;
    });
  }

  Future<void> toggleLike(String userId) async {
    if (isLikedByUser(userId)) {
      likes.remove(userId);
    } else {
      likes.add(userId);
    }
  }
}

class User {
  final String id;
  final String name;
  final String image;

  User({
    required this.id,
    required this.name,
    required this.image,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      name: json['name'],
      image: json['image'],
    );
  }
}

class ExperienceImage {
  final String id;
  final String url;

  ExperienceImage({
    required this.id,
    required this.url,
  });

  factory ExperienceImage.fromJson(Map<String, dynamic> json) {
    return ExperienceImage(
      id: json['_id'],
      url: json['url'],
    );
  }
}

class Comment {
  final String id;
  final User user;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.user,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'],
      user: User.fromJson(json['user']),
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}