import 'dart:convert';

class Note {
  final int? id;
  final List<int> encryptedContent;
  final List<int> nonce;
  final List<int> mac;
  final List<int> salt;
  final DateTime createdAt;

  Note({
    this.id,
    required this.encryptedContent,
    required this.nonce,
    required this.mac,
    required this.salt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': base64Encode(encryptedContent),
      'nonce': base64Encode(nonce),
      'mac': base64Encode(mac),
      'salt': base64Encode(salt),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      encryptedContent: base64Decode(map['content']),
      nonce: base64Decode(map['nonce']),
      mac: base64Decode(map['mac']),
      salt: base64Decode(map['salt']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class DecryptedNote {
  final int id;
  final String content;
  final DateTime createdAt;

  DecryptedNote({
    required this.id,
    required this.content,
    required this.createdAt,
  });
}
