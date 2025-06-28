import 'package:flutter/material.dart';

class ChatCampingScreen extends StatefulWidget {
  const ChatCampingScreen({super.key});

  @override
  _ChatCampingScreenState createState() => _ChatCampingScreenState();
}

class _ChatCampingScreenState extends State<ChatCampingScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];

  void _handleSubmitted(String text) {
    _messageController.clear();
    
    // Ajouter le message de l'utilisateur
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
      ));
    });

    // Simuler une réponse du chatbot (à remplacer par votre modèle IA)
    _simulateBotResponse(text);
  }

  void _simulateBotResponse(String userMessage) {
    // Simulation simple (à remplacer par l'appel à votre API IA)
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _messages.add(ChatMessage(
          text: _generateBotResponse(userMessage),
          isUser: false,
        ));
      });
    });
  }
String _generateBotResponse(String userMessage) {
  return "Notre assistant conversationnel spécialisé en camping sera disponible très bientôt ! 🚀\n\n"
         "En attendant, vous pouvez :\n"
         "• Explorer nos guides camping sur notre site\n"
         "• Consulter notre FAQ\n"
         "• Nous contacter par email à contact@camping.com\n\n"
         "Merci pour votre patience et à très vite pour cette nouvelle aventure ! 🏕️";
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant Camping 🏕️'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _messages[index],
            ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }
Widget _buildMessageComposer() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          spreadRadius: 2,
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: Colors.green[100]!),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12.0),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Demandez des conseils de camping...",
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    style: const TextStyle(color: Colors.black87),
                    onSubmitted: _handleSubmitted,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green[600],
          ),
          child: IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: () {
              if (_messageController.text.trim().isNotEmpty) {
                _handleSubmitted(_messageController.text);
              }
            },
          ),
        ),
      ],
    ),
  );
}
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: isUser ? Colors.blue : Colors.green,
            child: Icon(
              isUser ? Icons.person : Icons.chat_bubble,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUser ? "Vous" : "Assistant Camping",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}