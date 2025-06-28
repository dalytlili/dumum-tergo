import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/views/user/auth/sign_in_screen.dart' show storage;
import 'package:dumum_tergo/views/user/car/full_screen_image_gallery.dart';
import 'package:dumum_tergo/views/user/experiences/user_profil.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:dumum_tergo/models/experience_model.dart';

class FavoriteExperiencesScreen extends StatefulWidget {
  const FavoriteExperiencesScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteExperiencesScreen> createState() => _FavoriteExperiencesScreenState();
}

class _FavoriteExperiencesScreenState extends State<FavoriteExperiencesScreen> {
  List<Experience> _favoriteExperiences = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? currentUserId;
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId().then((_) {
      _fetchFavoriteExperiences();
    });
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) return 'À l\'instant';
    if (difference.inMinutes < 60) return 'il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'il y a ${difference.inHours} h';
    if (difference.inDays < 7) return 'il y a ${difference.inDays} j';
    
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _getCurrentUserId() async {
    try {
      final token = await storage.read(key: 'token');
      if (token != null) {
        currentUserId = await _getUserIdFromToken(token);
      }
    } catch (e) {
      debugPrint('Error getting user ID: $e');
    }
  }

  Future<String?> _getUserIdFromToken(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final jsonMap = jsonDecode(decoded);

      return jsonMap['user']?['_id']?.toString() ?? 
             jsonMap['userId']?.toString() ??
             jsonMap['id']?.toString();
    } catch (e) {
      debugPrint('Token decoding error: $e');
      return null;
    }
  }

  Future<void> _fetchFavoriteExperiences() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final token = await storage.read(key: 'token');
      if (token == null) {
        throw Exception('No token available');
      }

      final response = await http.get(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/experiences/favorites'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'] ?? [];
        
        final List<Experience> favorites = data.map((e) {
          final exp = Experience.fromJson(e);
          exp.isFavorite = true; // Mark as favorite
          return exp;
        }).toList();

        if (mounted) {
          setState(() {
            _favoriteExperiences = favorites;
          });
        }
      } else {
        throw Exception('Failed to load favorites: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching favorite experiences: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLike(Experience experience) async {
    try {
      if (currentUserId == null) {
        await _getCurrentUserId();
        if (currentUserId == null) {
          debugPrint('No user ID available');
          return;
        }
      }

      final token = await storage.read(key: 'token');
      if (token == null) {
        debugPrint('No token available');
        return;
      }

      // Handle both cases where like might be a String (userId) or a Map (user object)
      final wasLiked = experience.likes.any((like) => 
          (like is String && like == currentUserId) || 
          (like is Map && like['_id'] == currentUserId));
      
      // Optimistic UI update
      setState(() {
        if (wasLiked) {
          experience.likes.removeWhere((like) => 
              (like is String && like == currentUserId) || 
              (like is Map && like['_id'] == currentUserId));
        } else {
          experience.likes.add(currentUserId!);
        }
      });

      final response = await http.put(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/experiences/${experience.id}/${wasLiked ? 'unlike' : 'like'}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        // Revert change on error
        setState(() {
          if (wasLiked) {
            experience.likes.add(currentUserId!);
          } else {
            experience.likes.removeWhere((like) => 
                (like is String && like == currentUserId) || 
                (like is Map && like['_id'] == currentUserId));
          }
        });
        debugPrint('Like API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Like error: $e');
    }
  }

  Future<void> _handleFavorite(Experience experience) async {
    try {
      if (currentUserId == null) {
        await _getCurrentUserId();
        if (currentUserId == null) {
          debugPrint('No user ID available');
          return;
        }
      }

      final token = await storage.read(key: 'token');
      if (token == null) {
        debugPrint('No token available');
        return;
      }

      // Immediate visual update
      setState(() {
        experience.isFavorite = false;
        _favoriteExperiences.removeWhere((exp) => exp.id == experience.id);
      });

      final response = await http.delete(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/experiences/unfavorites/${experience.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        // Revert if request fails
        setState(() {
          experience.isFavorite = true;
          _favoriteExperiences.add(experience);
        });
        debugPrint('Favorite API error: ${response.statusCode} - ${response.body}');
      } else {
        // Show visual confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Retiré des favoris'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Favorite error: $e');
      setState(() {
        experience.isFavorite = true;
        _favoriteExperiences.add(experience);
      });
    }
  }

  Future<void> _showLikesBottomSheet(String experienceId) async {
    bool _isLoadingLikes = true;
    List<User> likers = [];
          final theme = Theme.of(context);

    // Afficher immédiatement le bottom sheet avec un indicateur de chargement
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> _loadLikes() async {
              setState(() => _isLoadingLikes = true);
              try {
                final token = await storage.read(key: 'token');
                final response = await http.get(
                  Uri.parse('https://dumum-tergo-backend.onrender.com/api/experiences/$experienceId/like'),
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Accept': 'application/json',
                  },
                );

                if (response.statusCode == 200) {
                  final data = json.decode(response.body);
                  setState(() {
                    likers = (data['data'] as List)
                        .map((userJson) => User.fromJson(userJson))
                        .toList();
                  });
                }
              } catch (e) {
                debugPrint('Error loading likes: $e');
              } finally {
                setState(() => _isLoadingLikes = false);
              }
            }

            // Charger les likes au premier affichage
            if (_isLoadingLikes && likers.isEmpty) {
              _loadLikes();
            }

            return Container(
               decoration: BoxDecoration(
          // fond selon le thème (clair/sombre)
          color: theme.cardTheme.color ?? (theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.white),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
                  const Text(
                    'Personnes qui ont aimé',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoadingLikes
                        ? const Center(child: CircularProgressIndicator())
                        : likers.isEmpty
                            ? const Center(
                                child: Text(
                                  'Aucun like pour le moment',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: likers.length,
                                itemBuilder: (context, index) {
                                  final user = likers[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        user.image.startsWith('https') 
                                          ? user.image 
                                          : 'https://res.cloudinary.com/dcs2edizr/image/upload/${user.image}',
                                      ),
                                    ),
                                    title: Text(user.name),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    // Charger les likes après l'affichage du bottom sheet
    try {
      final token = await storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/experiences/$experienceId/like'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        likers = (data['data'] as List)
            .map((userJson) => User.fromJson(userJson))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching likes: $e');
    }
  }
  Future<void> _showCommentsBottomSheet(String experienceId, List<dynamic> comments) async {
    final TextEditingController _commentController = TextEditingController();
    bool _isPostingComment = false;
    bool _isLoadingComments = true;
    int experienceIndex = _favoriteExperiences.indexWhere((exp) => exp.id == experienceId);
    List<Comment> fetchedComments = [];
              final theme = Theme.of(context);


    try {
      final token = await storage.read(key: 'token');
      
      // Show bottom sheet immediately with loading indicator
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              Future<void> _loadComments() async {
                setState(() => _isLoadingComments = true);
                try {
                  final response = await http.get(
                    Uri.parse('https://dumum-tergo-backend.onrender.com/api/experiences/$experienceId/comments'),
                    headers: {
                      'Authorization': 'Bearer $token',
                      'Accept': 'application/json',
                    },
                  );

                  if (response.statusCode == 200) {
                    final data = json.decode(response.body);
                    fetchedComments = (data['data'] as List)
                        .map((commentJson) => Comment.fromJson(commentJson))
                        .toList();
                  }
                } catch (e) {
                  debugPrint('Error loading comments: $e');
                } finally {
                  setState(() => _isLoadingComments = false);
                }
              }

              Future<void> _postComment() async {
                if (_commentController.text.isEmpty) return;
                
                setState(() => _isPostingComment = true);
                try {
                  final response = await http.post(
                    Uri.parse('https://dumum-tergo-backend.onrender.com/api/experiences/$experienceId/comment'),
                    headers: {
                      'Authorization': 'Bearer $token',
                      'Content-Type': 'application/json',
                    },
                    body: json.encode({'text': _commentController.text}),
                  );

                  if (response.statusCode == 200) {
                    final newCommentData = json.decode(response.body);
                    final newComment = Comment.fromJson(newCommentData['data']['comments'].last);
                    
                    setState(() {
                      fetchedComments.add(newComment);
                      _commentController.clear();
                    });

                    if (experienceIndex != -1) {
                      setState(() {
                        _favoriteExperiences[experienceIndex].comments.add({
                          'user': {
                            '_id': newComment.user.id,
                            'name': newComment.user.name,
                            'image': newComment.user.image
                          },
                          'text': newComment.text,
                          '_id': newComment.id,
                          'createdAt': newComment.createdAt.toIso8601String()
                        });
                      });
                    }
                  }
                } catch (e) {
                  debugPrint('Error posting comment: $e');
                } finally {
                  setState(() => _isPostingComment = false);
                }
              }

              // Load comments on first display
              if (_isLoadingComments && fetchedComments.isEmpty) {
                _loadComments();
              }

              return Container(
                decoration: BoxDecoration(
          // fond selon le thème (clair/sombre)
          color: theme.cardTheme.color ?? (theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.white),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
                padding: const EdgeInsets.all(16),
                height: MediaQuery.of(context).size.height * 0.85,
                child: Column(
                  children: [
                    Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
                    const Text(
                      'Commentaires',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    // Comments list
                    Expanded(
                      child: _isLoadingComments
                          ? const Center(child: CircularProgressIndicator())
                          : fetchedComments.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Aucun commentaire pour le moment',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: fetchedComments.length,
                                  itemBuilder: (context, index) {
                                    final comment = fetchedComments[index];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage: NetworkImage(
                                          comment.user.image.startsWith('https') 
                                            ? comment.user.image 
                                            : 'https://res.cloudinary.com/dcs2edizr/image/upload/${comment.user.image}',
                                        ),
                                      ),
                                      title: Text(comment.user.name),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(comment.text),
                                          Text(
                                            _formatTimeAgo(comment.createdAt),
                                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                    
                    // Comment input field
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText: 'Ajouter un commentaire...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              onSubmitted: (_) => _postComment(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _isPostingComment
                              ? const CircularProgressIndicator()
                              : IconButton(
                                  icon: const Icon(Icons.send),
                                  onPressed: _postComment,
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );

      // Load comments after showing bottom sheet
      final response = await http.get(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/experiences/$experienceId/comments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        fetchedComments = (data['data'] as List)
            .map((commentJson) => Comment.fromJson(commentJson))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      if (!mounted) return;
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.5,
            child: Column(
              children: [
                const Text(
                  'Commentaires',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Expanded(
                  child: Center(
                    child: Text('Impossible de charger les commentaires'),
                  ),
                ),
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Ajouter un commentaire...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

Widget _buildExperienceItem(Experience experience) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(
                'https://res.cloudinary.com/dcs2edizr/image/upload/${experience.user.image ?? 'default.jpg'}',
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                if (currentUserId != null && currentUserId != experience.user.id) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(userId: experience.user.id),
                    ),
                  );
                }
              },
              child: Text(
                experience.user.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color),
              onPressed: () {},
            ),
          ],
        ),
      ),
      
      if (experience.images.isNotEmpty)
        Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImageGallery(
                      images: experience.images.map((img) => img.url).toList(),
                      initialIndex: currentPage,
                    ),
                  ),
                );
              },
              child: SizedBox(
                height: 300,
                child: PageView.builder(
                  itemCount: experience.images.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return CachedNetworkImage(
                      imageUrl: experience.images[index].url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Theme.of(context).cardTheme.color,
                      ),
                      errorWidget: (context, url, error) => Icon(Icons.error, color: Theme.of(context).iconTheme.color),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(experience.images.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: currentPage == index ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: currentPage == index
                        ? Theme.of(context).primaryColor
                        : Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ],
        ),
      
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                experience.isLikedByUser(currentUserId ?? '') 
                  ? Icons.favorite 
                  : Icons.favorite_border,
                color: experience.isLikedByUser(currentUserId ?? '') 
                  ? Colors.red 
                  : Theme.of(context).iconTheme.color,
              ),
              onPressed: () => _handleLike(experience),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.comment_outlined, color: Theme.of(context).iconTheme.color),
              onPressed: () {
                _showCommentsBottomSheet(experience.id, experience.comments);
              },
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.bookmark, color: AppColors.primary),
              onPressed: () => _handleFavorite(experience),
            ),
          ],
        ),
      ),
      
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
        child: experience.likes.isEmpty
            ? const SizedBox.shrink()
            : GestureDetector(
                onTap: () => _showLikesBottomSheet(experience.id),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${experience.likes.length} ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      TextSpan(
                        text: experience.likes.length == 1 ? 'j\'aime' : 'j\'aimes',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                children: [
                  TextSpan(
                    text: '${experience.user.name} ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ReadMoreText(
              experience.description,
              trimLines: 2,
              colorClickableText: Theme.of(context).primaryColor,
              trimMode: TrimMode.Line,
              trimCollapsedText: '... Voir plus',
              trimExpandedText: ' Voir moins',
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ],
        ),
      ),
      
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
        child: Text(
          _formatTimeAgo(experience.createdAt),
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 12,
          ),
        ),
      ),
      
      const SizedBox(height: 8),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes favoris'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchFavoriteExperiences,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Failed to load favorite experiences'),
                        TextButton(
                          onPressed: _fetchFavoriteExperiences,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _favoriteExperiences.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune expérience favorite',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _favoriteExperiences.length,
                        itemBuilder: (context, index) {
                          return _buildExperienceItem(_favoriteExperiences[index]);
                        },
                      ),
      ),
    );
  }
}