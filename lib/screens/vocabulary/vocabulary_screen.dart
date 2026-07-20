import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../models/vocabulary_item.dart';
import '../../widgets/empty_state.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key, this.startReview = false});

  final bool startReview;

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this, initialIndex: widget.startReview ? 1 : 0);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Palavras e frases'),
          bottom: TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Banco'),
              Tab(text: 'Revisar'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => _editItem(context),
              icon: const Icon(Icons.add),
              tooltip: 'Adicionar palavra ou frase',
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabs,
          children: [
            _buildBank(context),
            const _ReviewView(),
          ],
        ),
      );

  Widget _buildBank(BuildContext context) {
    final controller = context.watch<AppController>();
    final items = controller.vocabulary.where((item) {
      final haystack = '${item.term} ${item.meaning} ${item.example} ${item.category} ${item.tags}'.toLowerCase();
      return _query.isEmpty || haystack.contains(_query.toLowerCase());
    }).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        TextField(
          controller: _search,
          onChanged: (value) => setState(() => _query = value.trim()),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Pesquisar palavra, significado ou tag',
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Chip(label: Text('${controller.vocabulary.length} itens')),
            const SizedBox(width: 8),
            Chip(label: Text('${controller.dueVocabularyCount} vencidos')),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          EmptyState(
            icon: Icons.style_outlined,
            title: controller.vocabulary.isEmpty ? 'Crie o primeiro cartão' : 'Nada encontrado',
            message: controller.vocabulary.isEmpty
                ? 'Guarde palavras e frases que você realmente encontrou em contexto. Evite colecionar listas enormes.'
                : 'Tente outro termo de pesquisa.',
            action: controller.vocabulary.isEmpty
                ? FilledButton(onPressed: () => _editItem(context), child: const Text('Adicionar'))
                : null,
          )
        else
          for (final item in items)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(child: Text(item.term.characters.first.toUpperCase())),
                title: Text(item.term, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(
                  '${item.meaning}${item.example.isEmpty ? '' : '\n${item.example}'}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: item.example.isNotEmpty,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _editItem(context, item: item);
                    if (value == 'archive') controller.saveVocabulary(item.copyWith(archived: !item.archived));
                    if (value == 'delete') _delete(context, item);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'archive', child: Text(item.archived ? 'Reativar' : 'Arquivar')),
                    const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
                onTap: () => _showItem(context, item),
              ),
            ),
      ],
    );
  }

  Future<void> _editItem(BuildContext context, {VocabularyItem? item}) async {
    final term = TextEditingController(text: item?.term ?? '');
    final meaning = TextEditingController(text: item?.meaning ?? '');
    final example = TextEditingController(text: item?.example ?? '');
    final category = TextEditingController(text: item?.category ?? 'Geral');
    final tags = TextEditingController(text: item?.tags ?? '');
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.viewInsetsOf(sheetContext).bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item == null ? 'Nova palavra ou frase' : 'Editar cartão',
                  style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              TextField(controller: term, autofocus: item == null, decoration: const InputDecoration(labelText: 'Inglês')),
              const SizedBox(height: 10),
              TextField(controller: meaning, decoration: const InputDecoration(labelText: 'Significado')),
              const SizedBox(height: 10),
              TextField(controller: example, maxLines: 2, decoration: const InputDecoration(labelText: 'Frase de exemplo')),
              const SizedBox(height: 10),
              TextField(controller: category, decoration: const InputDecoration(labelText: 'Categoria')),
              const SizedBox(height: 10),
              TextField(controller: tags, decoration: const InputDecoration(labelText: 'Tags separadas por vírgula')),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: () => Navigator.pop(sheetContext, true), child: const Text('Guardar')),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved != true || term.text.trim().isEmpty || meaning.text.trim().isEmpty || !context.mounted) return;
    await context.read<AppController>().saveVocabulary(VocabularyItem(
          id: item?.id,
          term: term.text.trim(),
          meaning: meaning.text.trim(),
          example: example.text.trim(),
          category: category.text.trim().isEmpty ? 'Geral' : category.text.trim(),
          tags: tags.text.trim(),
          createdAt: item?.createdAt ?? DateTime.now(),
          dueAt: item?.dueAt ?? DateTime.now(),
          intervalDays: item?.intervalDays ?? 0,
          ease: item?.ease ?? 2.5,
          repetitions: item?.repetitions ?? 0,
          lapses: item?.lapses ?? 0,
          archived: item?.archived ?? false,
        ));
  }

  Future<void> _delete(BuildContext context, VocabularyItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar cartão?'),
        content: Text(item.term),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AppController>().deleteVocabulary(item);
    }
  }

  void _showItem(BuildContext context, VocabularyItem item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.term, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text(item.meaning, style: Theme.of(context).textTheme.titleLarge),
            if (item.example.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(item.example),
            ],
            const SizedBox(height: 16),
            Text('Categoria: ${item.category} • intervalo: ${item.intervalDays} dias • repetições: ${item.repetitions}'),
          ],
        ),
      ),
    );
  }
}

class _ReviewView extends StatefulWidget {
  const _ReviewView();

  @override
  State<_ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends State<_ReviewView> {
  int _index = 0;
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    final due = context.watch<AppController>().vocabulary
        .where((item) => !item.archived && !item.dueAt.isAfter(DateTime.now()))
        .toList();
    if (due.isEmpty || _index >= due.length) {
      return const EmptyState(
        icon: Icons.task_alt,
        title: 'Revisões em dia',
        message: 'O algoritmo mostrará os cartões novamente quando estiverem próximos de ser esquecidos.',
      );
    }
    final item = due[_index];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Text('Cartão ${_index + 1}/${due.length}'),
              const Spacer(),
              Text('Intervalo atual: ${item.intervalDays} d'),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => setState(() => _showAnswer = true),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item.term, textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 20),
                          if (_showAnswer) ...[
                            const Divider(),
                            const SizedBox(height: 18),
                            Text(item.meaning, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                            if (item.example.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              Text(item.example, textAlign: TextAlign.center),
                            ],
                          ] else
                            const Text('Toque para revelar'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (!_showAnswer)
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: () => setState(() => _showAnswer = true), child: const Text('Mostrar resposta')),
            )
          else
            Row(
              children: [
                Expanded(child: _GradeButton(label: 'Errei', quality: 1, onTap: (quality) => _grade(item, quality))),
                const SizedBox(width: 7),
                Expanded(child: _GradeButton(label: 'Difícil', quality: 3, onTap: (quality) => _grade(item, quality))),
                const SizedBox(width: 7),
                Expanded(child: _GradeButton(label: 'Bom', quality: 4, onTap: (quality) => _grade(item, quality))),
                const SizedBox(width: 7),
                Expanded(child: _GradeButton(label: 'Fácil', quality: 5, onTap: (quality) => _grade(item, quality))),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _grade(VocabularyItem item, int quality) async {
    await context.read<AppController>().reviewVocabulary(item, quality);
    if (!mounted) return;
    setState(() {
      _showAnswer = false;
      _index = 0;
    });
  }
}

class _GradeButton extends StatelessWidget {
  const _GradeButton({required this.label, required this.quality, required this.onTap});
  final String label;
  final int quality;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: () => onTap(quality),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12)),
        child: Text(label),
      );
}
