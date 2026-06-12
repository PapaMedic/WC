import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wildland_companion_v2/core/models/cloud/workspace.dart';

class WorkspaceRepository {
  final FirebaseFirestore _firestore;

  WorkspaceRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _workspaces =>
      _firestore.collection('workspaces');

  Future<Workspace?> getWorkspace(String workspaceId) async {
    if (workspaceId.isEmpty) return null;
    final snapshot = await _workspaces.doc(workspaceId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return Workspace.fromFirestore(data);
  }

  Stream<Workspace?> watchWorkspace(String workspaceId) {
    if (workspaceId.isEmpty) return Stream.value(null);
    return _workspaces.doc(workspaceId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return Workspace.fromFirestore(data);
    });
  }

  Future<List<Workspace>> getUserWorkspaces({
    required String personalWorkspaceId,
    required List<String> organizationWorkspaceIds,
  }) async {
    final ids = {
      if (personalWorkspaceId.isNotEmpty) personalWorkspaceId,
      ...organizationWorkspaceIds.where((id) => id.isNotEmpty),
    };

    final workspaces = <Workspace>[];
    for (final id in ids) {
      final workspace = await getWorkspace(id);
      if (workspace != null) workspaces.add(workspace);
    }
    return workspaces;
  }

  Future<void> saveWorkspace(Workspace workspace) {
    return _workspaces
        .doc(workspace.workspaceId)
        .set(workspace.toFirestore(), SetOptions(merge: true));
  }
}
