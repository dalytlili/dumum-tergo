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
  final Map<String, dynamic> experience;
  final Function()? onExperienceDeleted;

  const ExperienceDetailView({
    Key? key, 
    required this.experience,
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

  @override
  void initState() {
    super.initState();
    _likeCount = widget.experience['likes']?.length ?? 0;
    _comments = widget.experience['comments'] ?? [];
    _getCurrentUserId();
  }

  Future<void> _getCurrentUserId() async {
    try {
      final token = await storage.read(key: 'token');
      if (token != null) {
        currentUserId = await _getUserIdFromToken(token);
        if (mounted) {
          setState(() {
            _isLiked = widget.experience['likes']?.contains(currentUserId) ?? false;
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
      if (token == null || currentUserId == null) return;

      // Mise à jour optimiste de l'UI
      setState(() {
        _isLiked = !_isLiked;
        _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
      });

      final response = await http.put(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/experiences/${widget.experience['_id']}/${_isLiked ? 'like' : 'unlike'}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        // Annuler le changement en cas d'erreur
        setState(() {
          _isLiked = !_isLiked;
          _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
        });
      }
    } catch (e) {
      debugPrint('Like error: $e');
    }
  }

  Future<void> _showLikesBottomSheet(String experienceId) async {
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
                              'https://res.cloudinary.com/dcs2edizr/image/upload/${user['image'] ?? 'default.jpg'}',
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
          SnackBar(content: Text('Erreur lors du chargement des likes')),
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
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/experiences/${widget.experience['_id']}/comment'),
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
          title: Text('Confirmer la suppression'),
          content: Text('Voulez-vous vraiment supprimer cette expérience ?'),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Supprimer', style: TextStyle(color: Colors.red)),
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
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/experiences/${widget.experience['_id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression')),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
      return false;
    }
  }

  String _formatTimeAgo(dynamic date) {
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
    final experience = widget.experience;
    final user = experience['user'] ?? {};
    final images = experience['images'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Détails de l\'expérience',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.text),
        actions: [
         PopupMenuButton<String>(
  icon: Icon(Icons.more_vert, color: AppColors.text),
  onSelected: (value) async {
    if (value == 'delete') {
      _showDeleteConfirmationDialog();
    } else if (value == 'edit') {
      final updatedExperience = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EditExperienceScreen(
            experience: widget.experience,
            onExperienceUpdated: (updatedExp) {
              setState(() {
                widget.experience['description'] = updatedExp['description'];
              });
            },
          ),
        ),
      );
      if (updatedExperience != null) {
        setState(() {
          widget.experience['description'] = updatedExperience['description'];
        });
      }
    }
  },
  itemBuilder: (BuildContext context) {
    return [
      if (currentUserId == widget.experience['user']?['_id']) ...[
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: AppColors.primary),
              SizedBox(width: 10),
              Text('Modifier'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 10),
              Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ],
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
                      'https://res.cloudinary.com/dcs2edizr/image/upload/${user['image'] ?? 'default.jpg'}',
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    user['name'] ?? 'Utilisateur inconnu',
                    style: TextStyle(
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
                      errorWidget: (context, url, error) => Icon(Icons.error),
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
                    icon: Icon(Icons.comment_outlined),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            
            // Nombre de likes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: _likeCount == 0
                  ? SizedBox.shrink()
                  : GestureDetector(
                      onTap: () => _showLikesBottomSheet(widget.experience['_id']),
                      child: Text(
                        '$_likeCount j\'aime${_likeCount > 1 ? 's' : ''}',
                        style: TextStyle(
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
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: '${user['name']} ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  ReadMoreText(
                    experience['description'] ?? '',
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
                _formatTimeAgo(experience['createdAt']),
                style: TextStyle(
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
                  Text(
                    'Commentaires',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  
                  // Liste des commentaires
                  if (_comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'Aucun commentaire pour le moment',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        final commentUser = comment['user'] ?? {};
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundImage: NetworkImage(
                              'https://res.cloudinary.com/dcs2edizr/image/upload/${commentUser['image'] ?? 'default.jpg'}',
                            ),
                          ),
                          title: Text(commentUser['name'] ?? 'Utilisateur inconnu'),
                          subtitle: Text(comment['text'] ?? ''),
                          trailing: Text(
                            _formatTimeAgo(comment['createdAt']),
                            style: TextStyle(fontSize: 12, color: Colors.grey),
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
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        _isPostingComment
                            ? CircularProgressIndicator()
                            : IconButton(
                                icon: Icon(Icons.send),
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