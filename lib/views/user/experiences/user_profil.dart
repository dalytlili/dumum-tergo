import 'package:dumum_tergo/views/user/auth/sign_in_screen.dart' show storage;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dumum_tergo/models/experience_model.dart';
import 'package:dumum_tergo/constants/colors.dart';
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';
import 'package:audioplayers/audioplayers.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Future<Map<String, dynamic>> _userData;
  late Future<List<Experience>> _userExperiences;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isProcessingFollow = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? currentUserId;
  bool _isBottomSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId().then((_) {
      _loadUserData();
    });
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

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      _userData = _fetchUserData();
      _userExperiences = _fetchUserExperiences();
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _playSound(String sound) async {
    try {
      await _audioPlayer.play(AssetSource('sounds/$sound.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
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

      final wasLiked = experience.likes.any((like) => 
          (like is String && like == currentUserId) || 
          (like is Map && like['_id'] == currentUserId));
      
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

Future<void> _showCommentsBottomSheet(String experienceId, List<dynamic> comments) async {
  if (_isBottomSheetOpen) return; // Empêche l'ouverture multiple
  
  setState(() => _isBottomSheetOpen = true);
  
  final TextEditingController _commentController = TextEditingController();
  bool _isPostingComment = false;

  try {
    final token = await storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('https://dumum-tergo-backend.onrender.com/api/experiences/$experienceId/comments'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (!mounted) return;
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<Comment> fetchedComments = (data['data'] as List)
          .map((commentJson) => Comment.fromJson(commentJson))
          .toList();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
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
                  }
                } catch (e) {
                  debugPrint('Error posting comment: $e');
                } finally {
                  setState(() => _isPostingComment = false);
                }
              }

              return Container(
                padding: const EdgeInsets.all(16),
                height: MediaQuery.of(context).size.height * 0.85,
                child: Column(
                  children: [
                    const Text(
                      'Commentaires',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    Expanded(
                      child: fetchedComments.isEmpty
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
finally {
    if (mounted) {
      setState(() => _isBottomSheetOpen = false);
    }
  }
}
Future<void> _showLikesBottomSheet(String experienceId) async {
    if (_isBottomSheetOpen) return; // Empêche l'ouverture multiple
  setState(() => _isBottomSheetOpen = true);

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
      final List<User> likers = (data['data'] as List)
          .map((userJson) => User.fromJson(userJson))
          .toList();

      if (!mounted) return;
      
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                const Text(
                  'Personnes qui ont aimé',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
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
    }
  } catch (e) {
    debugPrint('Error fetching likes: $e');
  } finally {
    if (mounted) {
      setState(() => _isBottomSheetOpen = false);
    }
  }
}

  Future<Map<String, dynamic>> _fetchUserData() async {
    final token = await storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('https://dumum-tergo-backend.onrender.com/api/user/${widget.userId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true) {
        return jsonResponse['data'];
      } else {
        throw Exception(jsonResponse['msg'] ?? 'Failed to load user data');
      }
    } else {
      throw Exception('Failed to load user data: ${response.statusCode}');
    }
  }

  Future<List<Experience>> _fetchUserExperiences() async {
    final token = await storage.read(key: 'token');
    final response = await _makeExperiencesRequest(token!, widget.userId);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((e) => Experience.fromJson(e))
            .toList();
      } else {
        throw Exception(data['msg'] ?? 'Failed to load experiences');
      }
    } else {
      throw Exception('Failed to load experiences: ${response.statusCode}');
    }
  }

  Future<http.Response> _makeExperiencesRequest(String token, String userId) async {
    return await http.get(
      Uri.parse('https://dumum-tergo-backend.onrender.com/api/experiences/user/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<void> _toggleFollowStatus(Map<String, dynamic> userData) async {
    if (_isProcessingFollow) return;
    
    setState(() {
      _isProcessingFollow = true;
    });

    try {
      final token = await storage.read(key: 'token');
      final response = await http.post(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/${widget.userId}/follow'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          await _loadUserData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonResponse['msg'] ?? 'Erreur inconnue')),
          );
        }
      } else {
        throw Exception('Failed to update follow status: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isProcessingFollow = false;
      });
    }
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

  Widget _buildProfileHeader(Map<String, dynamic> userData) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(right: 20),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  backgroundImage: NetworkImage(
                    userData['image'].startsWith('https') 
                      ? userData['image']
                      : 'https://res.cloudinary.com/dcs2edizr/image/upload/${userData['image']}',
                  ),
                ),
              ),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            userData['name'],
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutQuart,
                          transform: Matrix4.identity()..scale(_isProcessingFollow ? 0.95 : 1.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              if (!userData['isFollowing'] && !_isProcessingFollow)
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 4),
                                ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isProcessingFollow 
                                ? null 
                                : () async {
                                    HapticFeedback.lightImpact();
                                    await _playSound(userData['isFollowing'] ? 'notification' : 'notification');
                                    _toggleFollowStatus(userData);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: userData['isFollowing'] 
                                  ? isDarkMode ? Colors.grey[800] : Colors.grey[100]
                                  : AppColors.primary,
                              foregroundColor: userData['isFollowing'] 
                                  ? isDarkMode ? Colors.white : Colors.grey[800]
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                side: userData['isFollowing'] 
                                    ? BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!, width: 1) 
                                    : BorderSide.none,
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              animationDuration: const Duration(milliseconds: 300),
                              enableFeedback: true,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              switchInCurve: Curves.easeOutBack,
                              switchOutCurve: Curves.easeInCirc,
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: _isProcessingFollow
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                        backgroundColor: Colors.white24,
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (userData['isFollowing'])
                                          Icon(
                                            Icons.check_circle_outline,
                                            size: 18,
                                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                        if (userData['isFollowing'])
                                          const SizedBox(width: 6),
                                        Text(
                                          userData['isFollowing'] ? 'Abonné' : 'Suivre',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.2,
                                            shadows: userData['isFollowing'] 
                                                ? null 
                                                : [
                                                    Shadow(
                                                      color: Colors.black.withOpacity(0.1),
                                                      blurRadius: 2,
                                                      offset: const Offset(0, 1),
                                                    ),
                                                  ],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem('Expériences', userData['experienceCount'].toString(), theme),
                        _buildStatItem('Abonnés', userData['followersCount'].toString(), theme),
                        _buildStatItem('Abonnements', userData['followingCount'].toString(), theme),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: isDarkMode ? Colors.grey[800] : Colors.grey[200]),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.4, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceItem(Experience experience) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: theme.cardTheme.color,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(
                      experience.user.image.startsWith('https') 
                        ? experience.user.image
                        : 'https://res.cloudinary.com/dcs2edizr/image/upload/${experience.user.image}',
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
                        color: textColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTimeAgo(experience.createdAt),
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            if (experience.images.isNotEmpty)
              SizedBox(
                height: 300,
                child: PageView.builder(
                  itemCount: experience.images.length,
                  itemBuilder: (context, index) {
                    return CachedNetworkImage(
                      imageUrl: experience.images[index].url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      ),
                      errorWidget: (context, url, error) => Icon(Icons.error, color: secondaryTextColor),
                    );
                  },
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      experience.isLikedByUser(currentUserId ?? '') 
                        ? Icons.favorite 
                        : Icons.favorite_border,
                      color: experience.isLikedByUser(currentUserId ?? '') 
                        ? Colors.red 
                        : secondaryTextColor,
                    ),
                    onPressed: () => _handleLike(experience),
                  ),
                  IconButton(
                    icon: Icon(Icons.comment_outlined, color: secondaryTextColor),
                    onPressed: () {
                      if (!_isBottomSheetOpen) {
                        _showCommentsBottomSheet(experience.id, experience.comments);
                      }
                    },
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: experience.likes.isEmpty
                  ? const SizedBox.shrink()
                  : GestureDetector(
                      onTap: () {
                        if (!_isBottomSheetOpen) {
                          _showLikesBottomSheet(experience.id);
                        }
                      },
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(color: textColor),
                          children: [
                            TextSpan(
                              text: '${experience.likes.length} ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: experience.likes.length == 1 ? 'j\'aime' : 'j\'aimes',
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
                      style: TextStyle(color: textColor),
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
                    colorClickableText: theme.primaryColor,
                    trimMode: TrimMode.Line,
                    trimCollapsedText: '... Voir plus',
                    trimExpandedText: ' Voir moins',
                    style: TextStyle(color: textColor),
                  ),
                ],
              ),
            ),
            
            if (experience.comments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                child: GestureDetector(
                  onTap: () {
                    if (!_isBottomSheetOpen) {
                      _showCommentsBottomSheet(experience.id, experience.comments);
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dernier commentaire',
                        style: TextStyle(
                          color: secondaryTextColor,
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
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  experience.comments.last['text'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textColor,
                                  ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
              child: Text(
                _formatTimeAgo(experience.createdAt),
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Erreur de chargement',
                        style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                      ),
                      TextButton(
                        onPressed: _loadUserData,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUserData,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: FutureBuilder<Map<String, dynamic>>(
                          future: _userData,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return SizedBox(
                                height: 300,
                                child: Center(child: CircularProgressIndicator(color: theme.primaryColor)),
                              );
                            } else if (snapshot.hasError) {
                              return SizedBox(
                                height: 300,
                                child: Center(
                                  child: Text(
                                    'Erreur: ${snapshot.error}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                                  ),
                                ),
                              );
                            } else if (!snapshot.hasData) {
                              return SizedBox(
                                height: 300,
                                child: Center(
                                  child: Text(
                                    'Aucune donnée disponible',
                                    style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                                  ),
                                ),
                              );
                            } else {
                              return _buildProfileHeader(snapshot.data!);
                            }
                          },
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        sliver: SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Expériences',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.titleLarge?.color,
                              ),
                            ),
                          ),
                        ),
                      ),
                      FutureBuilder<List<Experience>>(
                        future: _userExperiences,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return SliverFillRemaining(
                              child: Center(child: CircularProgressIndicator(color: theme.primaryColor)),
                            );
                          } else if (snapshot.hasError) {
                            return SliverFillRemaining(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Erreur: ${snapshot.error}',
                                      style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                                    ),
                                    TextButton(
                                      onPressed: _loadUserData,
                                      child: const Text('Réessayer'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return SliverFillRemaining(
                              child: Center(
                                child: Text(
                                  'Aucune expérience partagée',
                                  style: TextStyle(color: theme.textTheme.bodySmall?.color),
                                ),
                              ),
                            );
                          } else {
                            return SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return _buildExperienceItem(snapshot.data![index]);
                                },
                                childCount: snapshot.data!.length,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
}