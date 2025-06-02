import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/views/user/auth/sign_in_screen.dart' show storage;
import 'package:dumum_tergo/views/user/car/full_screen_image_gallery.dart';
import 'package:dumum_tergo/views/user/experiences/add_experience_screen.dart';
import 'package:dumum_tergo/views/user/experiences/user_profil.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:dumum_tergo/models/experience_model.dart'; // Importez vos modèles

class ExperiencesScreen extends StatefulWidget {
  const ExperiencesScreen({Key? key}) : super(key: key);

  @override
  State<ExperiencesScreen> createState() => _ExperiencesScreenState();
}

class _ExperiencesScreenState extends State<ExperiencesScreen> {
  List<Experience> _experiences = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _currentPage = 1;
  final int _perPage = 10;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    _isLoading = false; 
    _getCurrentUserId().then((_) {
      _fetchExperiences();
    });
    _scrollController.addListener(_scrollListener);
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && 
        !_isLoading && 
        _hasMore) {
      _fetchExperiences();
    }
  }
 
Future<void> _fetchExperiences() async {
  if (_isLoading || !_hasMore) return;

  try {
    if (_currentPage == 1) {
      setState(() {
        _isLoading = true;
      });
    }

    final token = await storage.read(key: 'token');
    // Chargez d'abord les expériences
    final experiencesResponse = await http.get(
      Uri.parse('https://dumum-tergo-backend.onrender.com/api/experiences?page=$_currentPage&perPage=$_perPage'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (experiencesResponse.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(experiencesResponse.body);
      final List<dynamic> data = responseData['data'] ?? [];
      final List<Experience> newExperiences = data.map((e) => Experience.fromJson(e)).toList();

      // Chargez ensuite les favoris de l'utilisateur
      final favoritesResponse = await http.get(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/experiences/favorites'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (favoritesResponse.statusCode == 200) {
        final favoritesData = json.decode(favoritesResponse.body);
        final List<String> favoriteIds = (favoritesData['data'] as List)
            .map((fav) => fav['_id'].toString())
            .toList();

        // Mettez à jour l'état isFavorite pour chaque expérience
        for (var exp in newExperiences) {
          exp.isFavorite = favoriteIds.contains(exp.id);
        }
      }

      if (mounted) {
        setState(() {
          if (_currentPage == 1) {
            _experiences = newExperiences;
          } else {
            _experiences.addAll(newExperiences);
          }
          _hasMore = newExperiences.length == _perPage;
          _currentPage++;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _hasError = true;
      });
    }
    debugPrint('Error fetching experiences: $e');
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  String? currentUserId;

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

    final wasLiked = experience.isLikedByUser(currentUserId!);
    
    setState(() {
      if (wasLiked) {
        // Handle both cases where like might be a String or a Map
        experience.likes.removeWhere((like) => 
          like == currentUserId || 
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
      setState(() {
        if (wasLiked) {
          experience.likes.add(currentUserId!);
        } else {
          experience.likes.removeWhere((like) => 
            like == currentUserId || 
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

    final isCurrentlyFavorite = experience.isFavorite ?? false;
    
    // Mettre à jour l'état visuel immédiatement
    setState(() {
      experience.isFavorite = !isCurrentlyFavorite;
    });

    final response = isCurrentlyFavorite
        ? await http.delete(
            Uri.parse('https://dumum-tergo-backend.onrender.com/api/experiences/unfavorites/${experience.id}'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
        : await http.post(
            Uri.parse('https://dumum-tergo-backend.onrender.com/api/experiences/favorites/${experience.id}'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          );

    if (response.statusCode != 200) {
      // Revenir à l'état précédent si la requête échoue
      setState(() {
        experience.isFavorite = isCurrentlyFavorite;
      });
      debugPrint('Favorite API error: ${response.statusCode} - ${response.body}');
    } else {
      // Afficher une confirmation visuelle
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCurrentlyFavorite 
              ? 'Retiré des favoris' 
              : 'Ajouté aux favoris'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  } catch (e) {
    debugPrint('Favorite error: $e');
    setState(() {
      experience.isFavorite = !(experience.isFavorite ?? false);
    });
  }
}
  Future<void> _showCommentsBottomSheet(String experienceId, List<dynamic> comments) async {
    final TextEditingController _commentController = TextEditingController();
    bool _isPostingComment = false;
    bool _isLoadingComments = true;
    int experienceIndex = _experiences.indexWhere((exp) => exp.id == experienceId);
    List<Comment> fetchedComments = [];
              final theme = Theme.of(context);

    try {
      final token = await storage.read(key: 'token');
      
      // Afficher le bottom sheet immédiatement avec un indicateur de chargement
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
                        _experiences[experienceIndex].comments.add({
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

              // Charger les commentaires au premier affichage
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
                    
                    // Liste des commentaires
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
                    
                    // Champ pour ajouter un commentaire
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

      // Charger les commentaires après l'affichage du bottom sheet
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

  Widget _buildExperienceItem(Experience experience) {
    final lastComment = experience.comments.isNotEmpty 
        ? experience.comments.last 
        : null;

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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.more_vert),
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
                color: Colors.grey[200],
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
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
                    : null,
                ),
                onPressed: () => _handleLike(experience),
              ),
              IconButton(
                icon: const Icon(Icons.comment_outlined),
                onPressed: () {
                  _showCommentsBottomSheet(experience.id, experience.comments);
                },
              ),
        
              const Spacer(),
             IconButton(
  icon: Icon(
    experience.isFavorite ?? false 
      ? Icons.bookmark 
      : Icons.bookmark_border,
    color: experience.isFavorite ?? false 
      ? Theme.of(context).primaryColor 
      : null,
  ),
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
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(
                          text: '${experience.likes.length} ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                         TextSpan(
                        text: experience.likes.length == 1 ? 'j\'aime' : 'j\'aimes',
                        style: const TextStyle(
                          color: Colors.black,
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
                  style: const TextStyle(color: Colors.black),
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
                colorClickableText: AppColors.primary,
                trimMode: TrimMode.Line,
                trimCollapsedText: '... Voir plus',
                trimExpandedText: ' Voir moins',
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
        ),
        
        if (experience.comments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
            child: GestureDetector(
              onTap: () => _showCommentsBottomSheet(experience.id, experience.comments),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dernier commentaire',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: NetworkImage(
                          experience.comments.last['user']['image'].startsWith('https') 
                            ? experience.comments.last['user']['image']
                            : 'https://res.cloudinary.com/dcs2edizr/image/upload/${experience.comments.last['user']['image']}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              experience.comments.last['user']['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              experience.comments.last['text'],
                              style: const TextStyle(fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
          child: Text(
            _formatTimeAgo(experience.createdAt),
            style: const TextStyle(
              color: Colors.grey,
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
      appBar: null,
      body: RefreshIndicator(
        onRefresh: _fetchExperiences,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddExperienceScreen(),
                      ),
                    );

                    if (result == true && mounted) {
                      setState(() {
                        _currentPage = 1;
                        _hasMore = true;
                        _experiences = [];
                      });
                      await _fetchExperiences();
                      
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                     decoration: BoxDecoration(
              border: Border.all(
               color:  Colors.grey.shade300
              ),
              borderRadius: BorderRadius.circular(8),
            ),
                    child: Row(
                      children: [
                        FutureBuilder(
                          future: storage.read(key: 'userImage'),
                          builder: (context, snapshot) {
                            final imagePath = snapshot.data;
                            return CircleAvatar(
                              radius: 16,
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: imagePath != null && imagePath.isNotEmpty
                                      ? imagePath.startsWith('http')
                                          ? imagePath
                                          : 'https://res.cloudinary.com/dcs2edizr/image/upload/$imagePath'
                                      : 'assets/images/default.png',
                                  fit: BoxFit.cover,
                                  width: 32,
                                  height: 32,
                                  placeholder: (context, url) => CircularProgressIndicator(),
                                  errorWidget: (context, url, error) => Icon(Icons.error),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Partagez une expérience...',
                    style: const TextStyle(fontSize: 16),

                        ),
                        const Spacer(),
                        Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
             _isLoading && _experiences.isEmpty
                ? SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _hasError
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Failed to load experiences'),
                              TextButton(
                                onPressed: _fetchExperiences,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index < _experiences.length) {
                              return _buildExperienceItem(_experiences[index]);
                            } else if (_hasMore) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 32.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            return SizedBox.shrink();
                          },
                          childCount: _experiences.length + (_hasMore ? 1 : 0),
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}