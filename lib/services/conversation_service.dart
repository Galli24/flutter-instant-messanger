import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_instant_messenger/models/conversation_models.dart';
import 'package:flutter_instant_messenger/models/user.dart';

class ConversationState with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  String _userUid = '';
  History _history = History();
  StreamSubscription<History> _historyTracking;

  set userUid(String uid) => _userUid = uid;
  History get history => _history;

  void trackMessageHistory() {
    if (_historyTracking == null) {
      _historyTracking = _getHistory().listen((data) {
        _history = data;
        notifyListeners();
      });
    }
  }

  void stopTrackingMessageHistory() {
    if (_historyTracking != null) _historyTracking.cancel();
  }

  Future<UserModel> getParticipant(Conversation conversation) async {
    String uidToSearch =
        conversation.participants[0] == _userUid ? conversation.participants[1] : conversation.participants[0];
    return UserModel.fromDocument(await _firestore.collection('users').doc(uidToSearch).get());
  }

  Stream<History> _getHistory() {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: _userUid)
        .snapshots()
        .map((data) => History.fromSnapshot(data));
  }

  Stream<Conversation> getMessagesForConversation(String conversationId) {
    return _firestore.collection('conversations').doc(conversationId).snapshots().map((data) {
      Conversation conversation = Conversation.fromSnapshot(data);
      return conversation;
    });
  }

  Future<bool> startConversation(String participantUid, Message message) async {
    try {
      CollectionReference convColRef = _firestore.collection('conversations');
      convColRef.add({
        "messages": FieldValue.arrayUnion([message]),
        "participants": List.from([
          _userUid,
          participantUid,
        ]),
      });
      return true;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  Future<bool> sendMessageToConversation(String conversationId, Message message) async {
    try {
      DocumentReference conversationRef = _firestore.collection('conversations').doc(conversationId);
      conversationRef.update({
        'messages': FieldValue.arrayUnion([message])
      });
      return true;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }
}