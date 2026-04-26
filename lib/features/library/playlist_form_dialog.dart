import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/playlist_model.dart';
import '../../data/repositories/library_repository.dart';

const _palette = [
  0xFF1ED760,
  0xFF0D8BFF,
  0xFFFF6B9D,
  0xFFFFC36B,
  0xFF6C5CE7,
  0xFFD63031,
  0xFF55EFC4,
  0xFF74B9FF,
];

Future<PlaylistModel?> showPlaylistFormDialog(
  BuildContext context, {
  PlaylistModel? edit,
}) {
  return showDialog<PlaylistModel>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PlaylistFormDialog(edit: edit),
  );
}

class _PlaylistFormDialog extends StatefulWidget {
  final PlaylistModel? edit;
  const _PlaylistFormDialog({this.edit});

  @override
  State<_PlaylistFormDialog> createState() => _PlaylistFormDialogState();
}

class _PlaylistFormDialogState extends State<_PlaylistFormDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late int _color;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.edit?.name ?? '');
    _desc = TextEditingController(text: widget.edit?.description ?? '');
    _color = widget.edit?.colorValue ?? _palette.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final lib = context.read<LibraryRepository>();
    PlaylistModel result;
    if (widget.edit == null) {
      result = await lib.createPlaylist(
        name: _name.text.trim(),
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        colorValue: _color,
      );
    } else {
      await lib.updatePlaylist(
        widget.edit!.id,
        name: _name.text.trim(),
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        colorValue: _color,
      );
      result = widget.edit!.copyWith(
        name: _name.text.trim(),
        description: _desc.text.trim(),
        colorValue: _color,
      );
    }
    if (!mounted) return;
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.edit == null ? 'Tạo playlist' : 'Sửa playlist',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Tên',
                controller: _name,
                icon: Icons.title_rounded,
                validator: (v) => validateNotEmpty(v, label: 'Tên'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Mô tả (không bắt buộc)',
                controller: _desc,
                icon: Icons.notes_rounded,
              ),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Màu chủ đạo',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final c in _palette)
                    GestureDetector(
                      onTap: () => setState(() => _color = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(c),
                          border: Border.all(
                            color: _color == c ? Colors.white : Colors.white24,
                            width: _color == c ? 2.5 : 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Huỷ',
                      secondary: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: widget.edit == null ? 'Tạo' : 'Lưu',
                      loading: _saving,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
