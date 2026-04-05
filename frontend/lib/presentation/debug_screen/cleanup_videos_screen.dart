import 'package:flutter/material.dart';
import 'package:skill_link_gh/utils/cleanup_4k_videos.dart';

class CleanupVideosScreen extends StatefulWidget {
  const CleanupVideosScreen({super.key});

  @override
  State<CleanupVideosScreen> createState() => _CleanupVideosScreenState();
}

class _CleanupVideosScreenState extends State<CleanupVideosScreen> {
  bool _isLoading = false;
  String _result = '';
  List<dynamic> _videos = [];

  Future<void> _listVideos() async {
    setState(() {
      _isLoading = true;
      _result = 'Fetching video list...';
    });

    try {
      final result = await Cleanup4KVideos.listVideoSizes();

      setState(() {
        _isLoading = false;
        _videos = result['videos'] ?? [];
        _result =
            '''
✅ Found ${result['totalVideos']} videos
🎬 4K videos (>10MB): ${result['total4K']}
        ''';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _result = '❌ Error: $e';
      });
    }
  }

  Future<void> _cleanup() async {
    // Confirm first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cleanup'),
        content: const Text(
          'This will DELETE all videos larger than 10MB from Firestore and Storage. This action cannot be undone!\n\nAre you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _result = 'Deleting 4K videos...';
    });

    try {
      final result = await Cleanup4KVideos.cleanup4KVideos();

      setState(() {
        _isLoading = false;
        _result =
            '''
✅ Cleanup Complete!

Deleted Reels: ${result['deletedReels']}
Deleted Videos: ${result['deletedVideos']}
Errors: ${result['errors']}

${result['errors'] > 0 ? '\n⚠️ Check logs for error details' : ''}
        ''';
        _videos = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 4K videos deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _result = '❌ Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cleanup 4K Videos'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '⚠️ WARNING',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This tool will delete all videos larger than 10MB from your Firestore database and Firebase Storage. Use with caution!',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _listVideos,
              icon: const Icon(Icons.list),
              label: const Text('List All Videos'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _cleanup,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete 4K Videos (>10MB)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_result.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _result,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
              ),
            const SizedBox(height: 16),
            if (_videos.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _videos.length,
                  itemBuilder: (context, index) {
                    final video = _videos[index];
                    final is4K = video['is4K'] == true;

                    return Card(
                      color: is4K ? Colors.red[50] : Colors.white,
                      child: ListTile(
                        leading: Icon(
                          is4K ? Icons.warning : Icons.check_circle,
                          color: is4K ? Colors.red : Colors.green,
                        ),
                        title: Text(video['artisanName'] ?? 'Unknown'),
                        subtitle: Text(
                          'Size: ${video['sizeMB']}MB\nID: ${video['reelId']}',
                        ),
                        trailing: is4K
                            ? const Chip(
                                label: Text('4K'),
                                backgroundColor: Colors.red,
                                labelStyle: TextStyle(color: Colors.white),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
