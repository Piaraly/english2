import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../models/material_item.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import 'immersion_player_screen.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  String _status = 'all';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final filtered = controller.materials.where((item) {
      final statusMatches = _status == 'all' || item.status == _status;
      final text = '${item.name} ${item.skill} ${item.level} ${item.notes}'.toLowerCase();
      return statusMatches && (_query.isEmpty || text.contains(_query.toLowerCase()));
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _importMaterial(context),
        icon: const Icon(Icons.add_to_drive_outlined),
        label: const Text('Adicionar material'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      eyebrow: 'BIBLIOTECA SEM ACÚMULO',
                      title: 'Um recurso ativo por habilidade',
                      subtitle:
                          'Quando ativa um novo material para a mesma habilidade, o anterior vai automaticamente para a lista de espera.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Pesquisar materiais, nível ou habilidade',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'all', label: Text('Todos')),
                          ButtonSegment(value: 'active', label: Text('Ativos'), icon: Icon(Icons.play_circle_outline)),
                          ButtonSegment(value: 'waitlist', label: Text('Em espera'), icon: Icon(Icons.schedule)),
                          ButtonSegment(value: 'completed', label: Text('Concluídos'), icon: Icon(Icons.check_circle_outline)),
                          ButtonSegment(value: 'archive', label: Text('Arquivo'), icon: Icon(Icons.inventory_2_outlined)),
                        ],
                        selected: {_status},
                        onSelectionChanged: (value) => setState(() => _status = value.first),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (filtered.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.folder_open,
                  title: 'Nenhum material aqui',
                  message: 'Adicione áudio, vídeo, PDF ou texto. O ficheiro continua no seu aparelho e o app funciona offline.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _MaterialCard(
                    material: filtered[index],
                    onOpen: () => _openMaterial(context, filtered[index]),
                    onEdit: () => _editMaterial(context, filtered[index]),
                    onDelete: () => _deleteMaterial(context, filtered[index]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _importMaterial(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac',
        'mp4', 'mkv', 'webm',
        'pdf', 'epub', 'txt', 'md', 'docx',
      ],
    );
    if (!mounted || result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    final path = picked.path;
    if (path == null || path.isEmpty) {
      _message('O Android não forneceu um caminho local para este ficheiro. Copie-o para a memória interna e tente novamente.');
      return;
    }
    final draft = MaterialItem(
      name: picked.name,
      path: path,
      kind: _kindFromName(picked.name),
      skill: _kindFromName(picked.name) == 'audio' ? 'Listening' : 'Reading',
      status: 'waitlist',
      level: context.read<AppController>().currentLevel,
      createdAt: DateTime.now(),
    );
    await _showMaterialEditor(context, draft, isNew: true);
  }

  Future<void> _editMaterial(BuildContext context, MaterialItem item) =>
      _showMaterialEditor(context, item, isNew: false);

  Future<void> _showMaterialEditor(
    BuildContext context,
    MaterialItem item, {
    required bool isNew,
  }) async {
    final controller = context.read<AppController>();
    final name = TextEditingController(text: item.name);
    final notes = TextEditingController(text: item.notes);
    var skill = item.skill;
    var status = item.status;
    var level = item.level;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text(isNew ? 'Adicionar material' : 'Editar material'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: skill,
                    decoration: const InputDecoration(labelText: 'Habilidade principal'),
                    items: const ['Listening', 'Reading', 'Speaking', 'Writing', 'Grammar', 'Vocabulary']
                        .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) => setLocalState(() => skill = value ?? skill),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: level,
                    decoration: const InputDecoration(labelText: 'Nível'),
                    items: const ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                        .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) => setLocalState(() => level = value ?? level),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: const {
                      'active': 'Ativo agora',
                      'waitlist': 'Lista de espera',
                      'completed': 'Concluído',
                      'archive': 'Arquivo — não usar agora',
                    }
                        .entries
                        .map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value)))
                        .toList(),
                    onChanged: (value) => setLocalState(() => status = value ?? status),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notes,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Notas e objetivo',
                      hintText: 'Ex.: usar 15 minutos por dia para shadowing',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.path,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Guardar')),
          ],
        ),
      ),
    );

    if (saved != true || name.text.trim().isEmpty) return;
    await controller.saveMaterial(item.copyWith(
      name: name.text.trim(),
      skill: skill,
      status: status,
      level: level,
      notes: notes.text.trim(),
    ));
    if (mounted) _message(status == 'active' ? 'Material ativado. Outros materiais ativos de $skill foram movidos para a lista de espera.' : 'Material guardado.');
  }

  Future<void> _openMaterial(BuildContext context, MaterialItem item) async {
    if (!await File(item.path).exists()) {
      _message('O ficheiro já não existe neste caminho. Edite ou remova o material.');
      return;
    }
    if (item.kind == 'audio') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ImmersionPlayerScreen(material: item)),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Tipo: ${item.kind} • ${item.level} • ${item.skill}'),
            const SizedBox(height: 12),
            SelectableText(item.path),
            if (item.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(item.notes),
            ],
            const SizedBox(height: 16),
            const Text('Leitores externos não são iniciados automaticamente para preservar o funcionamento offline e evitar permissões adicionais. O reprodutor especializado interno está disponível para áudios.'),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMaterial(BuildContext context, MaterialItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover da biblioteca?'),
        content: const Text('O ficheiro original não será apagado do aparelho.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AppController>().deleteMaterial(item);
    }
  }

  String _kindFromName(String name) {
    final extension = name.split('.').last.toLowerCase();
    if (const {'mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac'}.contains(extension)) return 'audio';
    if (const {'mp4', 'mkv', 'webm'}.contains(extension)) return 'video';
    if (extension == 'pdf') return 'pdf';
    if (extension == 'epub') return 'ebook';
    return 'document';
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({
    required this.material,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final MaterialItem material;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: colorScheme.secondaryContainer,
                child: Icon(_iconFor(material.kind), color: colorScheme.onSecondaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(material.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Tag(material.level),
                        _Tag(material.skill),
                        _Tag(_statusLabel(material.status)),
                      ],
                    ),
                    if (material.progress > 0) ...[
                      const SizedBox(height: 10),
                      LinearProgressIndicator(value: material.progress.clamp(0, 1).toDouble()),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Editar'))),
                  PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Remover'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String kind) => switch (kind) {
        'audio' => Icons.graphic_eq,
        'video' => Icons.movie_outlined,
        'pdf' => Icons.picture_as_pdf_outlined,
        'ebook' => Icons.menu_book_outlined,
        _ => Icons.description_outlined,
      };

  String _statusLabel(String status) => switch (status) {
        'active' => 'Ativo',
        'waitlist' => 'Em espera',
        'completed' => 'Concluído',
        _ => 'Arquivo',
      };
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          child: Text(text, style: Theme.of(context).textTheme.labelSmall),
        ),
      );
}
