import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/core/models/cloud/workspace.dart';

class WorkspaceSelector extends StatelessWidget {
  final List<Workspace> workspaces;
  final String activeWorkspaceId;
  final ValueChanged<Workspace> onChanged;

  const WorkspaceSelector({
    super.key,
    required this.workspaces,
    required this.activeWorkspaceId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (workspaces.isEmpty) {
      return const Text('No cloud workspaces available.');
    }

    return Column(
      children: workspaces.map((workspace) {
        final isSelected = workspace.workspaceId == activeWorkspaceId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: isSelected
                ? AppColors.primaryAccent.withValues(alpha: 0.12)
                : const Color(0xFF111611),
            borderRadius: BorderRadius.circular(10),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color:
                      isSelected ? AppColors.primaryAccent : AppColors.border,
                ),
              ),
              leading: Icon(
                workspace.type == WorkspaceType.personal
                    ? Icons.person_outline
                    : Icons.groups_outlined,
                color:
                    isSelected ? AppColors.primaryAccent : AppColors.textMuted,
              ),
              title: Text(
                workspace.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(workspace.type.value),
              trailing: isSelected
                  ? const Icon(Icons.check_circle,
                      color: AppColors.primaryAccent)
                  : null,
              onTap: isSelected ? null : () => onChanged(workspace),
            ),
          ),
        );
      }).toList(),
    );
  }
}
