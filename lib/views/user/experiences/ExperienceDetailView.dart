import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/views/user/auth/sign_in_screen.dart' show storage;
import 'package:dumum_tergo/views/user/experiences/EditExperienceScreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ExperienceDetailView extends StatefulWidget {
  final String experienceId;
  final Function()? onExperienceDeleted;

  const ExperienceDetailView({
    Key? key, 
    required this.experienceId,
    this.onExperienceDeleted,
  }) : super(key: key);

  @override
  _ExperienceDetailViewState createState() => _ExperienceDetailViewState();
}

class _ExperienceDetailViewState extends State<ExperienceDetailView> {
  String? currentUserId;
  final storage = const FlutterSecureStorage();
  bool _isLiked = false;
  int _likeCount = 0;
  List<dynamic> _comments = [];
  final TextEditingController _commentController = TextEditingController();
  bool _isPostingComment = false;
  Map<String, dynamic>? _experience;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchExperience();
    _getCurrentUserId();
  }

  Future<void> _fetchExperience() async {
  try {
    final token = await storage.read(key: 'token');
    final headers = {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(
      Uri.parse('https://dumum-tergo-backend.onrender.com/api/experiences/${widget.experienceId}'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _experience = data['data'];
        _likeCount = _experience?['likes']?.length ?? 0;
        _comments = _experience?['comments'] ?? [];
        
        // Initialiser _isLiked en vérifiant si currentUserId est dans les likes
        if (currentUserId != null && _experience?['likes'] != null) {
          _isLiked = _experience!['likes'].contains(currentUserId);
        } else {
          _isLiked = false;
        }
        
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = 'Erreur lors du chargement de l\'expérience';
        _isLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'Erreur de connexion: ${e.toString()}';
      _isLoading = false;
    });
  }
}

  Future<void> _getCurrentUserId() async {
    try {
      final token = await storage.read(key: 'token');
      if (token != null) {
        currentUserId = await _getUserIdFromToken(token);
        if (mounted && _experience != null) {
          setState(() {
            _isLiked = _experience!['likes']?.contains(currentUserId) ?? false;
          });
        }
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

Future<void> _handleLike() async {
  try {
    final token = await storage.read(key: 'token');
    if (token == null || currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez vous connecter pour aimer')),
        );
      }
      return;
    }

    // Vérifier que l'expérience existe
    if (_experience == null) return;

    // Mise à jour optimiste de l'UI
    setState(() {
      _isLiked = !_isLiked;
      _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
    });

    final endpoint = _isLiked ? 'like' : 'unlike';
    final uri = Uri.parse('https://dumum-tergo-backend.onrender.com/api/experiences/${widget.experienceId}/$endpoint');

    debugPrint('Envoi de la requête LIKE à: $uri');
    debugPrint('Token: ${token.substring(0, 10)}...');

    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    debugPrint('Réponse du serveur: ${response.statusCode}');
    debugPrint('Corps de la réponse: ${response.body}');

    if (response.statusCode != 200) {
      // Annuler le changement en cas d'erreur
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${response.body}')),
        );
      }
    } else {
      // Rafraîchir les données après un like réussi
      await _fetchExperience();
    }
  } catch (e) {
    debugPrint('Like error: $e');
    if (mounted) {
      setState(() {
        _isLiked = !_isLiked;
        _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur réseau: ${e.toString()}')),
      );
    }
  }
}

  Future<void> _showLikesBottomSheet() async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/experiences/${widget.experienceId}/like'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> likers = data['data'] ?? [];

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
                              user['image'].startsWith('https') 
                                ? user['image']
                                : 'https://res.cloudinary.com/dcs2edizr/image/upload/${user['image']}',
                            ),
                          ),
                          title: Text(user['name'] ?? 'Utilisateur inconnu'),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du chargement des likes')),
        );
      }
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.isEmpty) return;
    
    setState(() => _isPostingComment = true);
    try {
      final token = await storage.read(key: 'token');
      if (token == null) return;

      final response = await http.post(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/experiences/${widget.experienceId}/comment'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'text': _commentController.text}),
      );

      if (response.statusCode == 200) {
        final newCommentData = json.decode(response.body);
        setState(() {
          _comments.add(newCommentData['data']['comments'].last);
          _commentController.clear();
        });
        // Rafraîchir l'expérience complète
        await _fetchExperience();
      }
    } catch (e) {
      debugPrint('Error posting comment: $e');
    } finally {
      if (mounted) {
        setState(() => _isPostingComment = false);
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const Text('Voulez-vous vraiment supprimer cette expérience ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmed && mounted) {
      final success = await _deleteExperience();
      if (success && mounted) {
        Navigator.of(context).pop(true);
        widget.onExperienceDeleted?.call();
      }
    }
  }

  Future<bool> _deleteExperience() async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.delete(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/experiences/${widget.experienceId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de la suppression')),
          );
        }
        return false;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
      return false;
    }
  }

  String _formatTimeAgo(dynamic date) {
    if (date == null) return 'Date inconnue';
    
    DateTime parsedDate;
    
    if (date is DateTime) {
      parsedDate = date;
    } else if (date is String) {
      parsedDate = DateTime.parse(date);
    } else {
      return 'Date inconnue';
    }

    final now = DateTime.now();
    final difference = now.difference(parsedDate);
    
    if (difference.inMinutes < 1) return 'À l\'instant';
    if (difference.inMinutes < 60) return 'il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'il y a ${difference.inHours} h';
    if (difference.inDays < 7) return 'il y a ${difference.inDays} j';
    
    return DateFormat('dd/MM/yyyy').format(parsedDate);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchExperience,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_experience == null) {
      return const Scaffold(
        body: Center(child: Text('Expérience non trouvée')),
      );
    }

    final user = _experience!['user'] ?? {};
    final images = _experience!['images'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de l\'expérience'),
        elevation: 0,
        actions: [
          if (currentUserId == user['_id'])
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'delete') {
                  _showDeleteConfirmationDialog();
                } else if (value == 'edit') {
                  final updatedExperience = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EditExperienceScreen(
                        experience: _experience!,
                        onExperienceUpdated: (updatedExp) {
                          setState(() {
                            _experience!['description'] = updatedExp['description'];
                          });
                        },
                      ),
                    ),
                  );
                  if (updatedExperience != null) {
                    setState(() {
                      _experience!['description'] = updatedExperience['description'];
                    });
                  }
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: const [
                        Icon(Icons.edit, color: AppColors.primary),
                        SizedBox(width: 10),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: const [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 10),
                        Text(
                          'Supprimer',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ];
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec les infos utilisateur
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(
                      user['image'].startsWith('https') 
                        ? user['image']
                        : 'https://res.cloudinary.com/dcs2edizr/image/upload/${user['image']}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user['name'] ?? 'Utilisateur inconnu',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Carrousel d'images
            if (images.isNotEmpty)
              SizedBox(
                height: 300,
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final image = images[index];
                    final imageUrl = image is String ? image : image['url'] ?? '';
                    return CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    );
                  },
                ),
              ),
            
            // Actions (like, comment)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.red : null,
                    ),
                    onPressed: _handleLike,
                  ),
                  IconButton(
                    icon: const Icon(Icons.comment_outlined),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            
            // Nombre de likes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: _likeCount == 0
                  ? const SizedBox.shrink()
                  : GestureDetector(
                      onTap: _showLikesBottomSheet,
                      child: Text(
                        '$_likeCount j\'aime${_likeCount > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            
            // Description
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
                          text: '${user['name']} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  ReadMoreText(
                    _experience!['description'] ?? '',
                    trimLines: 2,
                    colorClickableText: AppColors.primary,
                    trimMode: TrimMode.Line,
                    trimCollapsedText: '... Voir plus',
                    trimExpandedText: ' Voir moins',
                  ),
                ],
              ),
            ),
            
            // Timestamp
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
              child: Text(
                _formatTimeAgo(_experience!['createdAt']),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
            
            // Section commentaires
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Commentaires',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Liste des commentaires
                  if (_comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: const Text(
                        'Aucun commentaire pour le moment',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        final commentUser = comment['user'] ?? {};
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundImage: NetworkImage(
                              commentUser['image'].startsWith('https') 
                                ? commentUser['image']
                                : 'https://res.cloudinary.com/dcs2edizr/image/upload/${commentUser['image']}',
                            ),
                          ),
                          title: Text(commentUser['name'] ?? 'Utilisateur inconnu'),
                          subtitle: Text(comment['text'] ?? ''),
                          trailing: Text(
                            _formatTimeAgo(comment['createdAt']),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  
                  // Champ pour ajouter un commentaire
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
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
            ),
          ],
        ),
      ),
    );
  }
}