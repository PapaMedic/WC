import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:wildland_companion_v2/core/models/cloud/app_user.dart';
import 'package:wildland_companion_v2/core/models/cloud/finalized_ticket_record.dart';
import 'package:wildland_companion_v2/core/models/cloud/workspace.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_pdf_record.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_shift_ticket.dart';

class CloudTicketRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CloudTicketRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  Future<List<FinalizedTicketRecord>> getFinalizedTickets(
    String workspaceId,
  ) async {
    if (workspaceId.isEmpty) return [];
    final snapshot = await _firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('finalizedTickets')
        .orderBy('finalizedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => FinalizedTicketRecord.fromFirestore(doc.data()))
        .toList();
  }

  Future<void> syncFinalizedTicket({
    required OF297ShiftTicket ticket,
    required AppUser user,
    List<OF297PdfRecord> pdfRecords = const [],
  }) async {
    if (!ticket.isFinalized || user.activeWorkspaceId.isEmpty) return;

    final pdfStoragePaths = <String>[];
    for (var i = 0; i < pdfRecords.length; i++) {
      final record = pdfRecords[i];
      final path = await _uploadPdfIfPossible(
        workspaceId: user.activeWorkspaceId,
        ticketId: ticket.id,
        record: record,
        fileName: 'of297_${i + 1}.pdf',
      );
      if (path != null) pdfStoragePaths.add(path);
    }

    final record = FinalizedTicketRecord.fromTicket(
      ticket: ticket,
      workspaceId: user.activeWorkspaceId,
      workspaceType: user.activeWorkspaceType,
      organizationId: user.activeWorkspaceType == WorkspaceType.organization
          ? _activeOrganizationId(user)
          : null,
      ownerUid: user.uid,
      createdByName: user.displayName,
      pdfStoragePaths: pdfStoragePaths,
      syncStatus: 'synced',
    );

    await _firestore
        .collection('workspaces')
        .doc(user.activeWorkspaceId)
        .collection('finalizedTickets')
        .doc(ticket.id)
        .set(record.toFirestore(), SetOptions(merge: true));
  }

  Future<String?> _uploadPdfIfPossible({
    required String workspaceId,
    required String ticketId,
    required OF297PdfRecord record,
    required String fileName,
  }) async {
    if (kIsWeb || record.filePath.isEmpty) return null;

    final file = File(record.filePath);
    if (!await file.exists()) return null;

    final storagePath =
        'workspace_uploads/$workspaceId/finalized_tickets/$ticketId/$fileName';
    await _storage.ref(storagePath).putFile(file);
    return storagePath;
  }

  String? _activeOrganizationId(AppUser user) {
    for (final entry in user.roleByOrganization.entries) {
      if (user.organizationIds.contains(entry.key)) return entry.key;
    }
    return user.organizationIds.isEmpty ? null : user.organizationIds.first;
  }
}
