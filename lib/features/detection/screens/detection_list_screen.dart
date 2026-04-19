import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/detection.dart';
import '../../../shared/widgets/detection_card.dart';
import '../providers/detection_provider.dart';

class DetectionListScreen extends ConsumerStatefulWidget {
  const DetectionListScreen({super.key});

  @override
  ConsumerState<DetectionListScreen> createState() =>
      _DetectionListScreenState();
}

class _DetectionListScreenState extends ConsumerState<DetectionListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detectionsAsync = ref.watch(detectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('탐지 결과'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: '전체'),
            Tab(text: '미확인'),
            Tab(text: '신고완료'),
          ],
        ),
      ),
      body: detectionsAsync.when(
        data: (list) => TabBarView(
          controller: _tab,
          children: [
            _DetectionList(
              items: list,
              onTap: (d) => context.go('/detections/${d.detectionId}'),
            ),
            _DetectionList(
              items: list
                  .where((d) => d.status == DetectionStatus.unread)
                  .toList(),
              onTap: (d) => context.go('/detections/${d.detectionId}'),
            ),
            _DetectionList(
              items: list
                  .where((d) => d.status == DetectionStatus.reported)
                  .toList(),
              onTap: (d) => context.go('/detections/${d.detectionId}'),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('탐지 결과를 불러오지 못했습니다.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(detectionsProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetectionList extends StatelessWidget {
  final List<Detection> items;
  final void Function(Detection) onTap;

  const _DetectionList({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('탐지된 결과가 없습니다.'));
    }
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        itemCount: items.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (_, i) =>
            DetectionCard(detection: items[i], onTap: () => onTap(items[i])),
      ),
    );
  }
}
