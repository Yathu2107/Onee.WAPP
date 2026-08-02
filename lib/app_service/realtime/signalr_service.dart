import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../features/jobs/model/job_models.dart';
import '../storage/secure_storage_service.dart';

/// SignalR client for `{BASE_URL}/hubs/job` (Worker listens to JobOffer).
class SignalRService extends GetxService {
  SignalRService(this._storage);

  final SecureStorageService _storage;
  HubConnection? _connection;

  final jobOffer = Rxn<JobDetail>();
  final jobUpdated = Rxn<JobDetail>();
  final chatMessage = Rxn<JobChatMessage>();

  /// Ref-counted job groups so chat leave doesn't drop detail listeners.
  final Map<int, int> _joinedJobs = {};

  bool get isConnected =>
      _connection?.state == HubConnectionState.Connected;

  Future<void> connect() async {
    if (isConnected) return;

    final token = await _storage.getToken();
    if (token == null || token.isEmpty) return;

    final baseUrl = dotenv.env['BASE_URL'] ?? 'https://localhost:7076';
    final hubUrl = '$baseUrl/hubs/job';

    try {
      await disconnect(clearJoined: false);

      _connection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async {
                final t = await _storage.getToken();
                return t ?? '';
              },
              skipNegotiation: false,
              requestTimeout: 15000,
            ),
          )
          .withAutomaticReconnect(retryDelays: [0, 2000, 5000, 10000, 30000])
          .build();

      _connection!.on('JobOffer', _onJobOffer);
      _connection!.on('JobUpdated', _onJobUpdated);
      _connection!.on('ChatMessage', _onChatMessage);
      _connection!.onreconnected(({connectionId}) {
        if (kDebugMode) {
          debugPrint('SignalR reconnected ($connectionId); rejoining jobs');
        }
        _rejoinJobs();
      });

      await _connection!.start();
      if (kDebugMode) {
        debugPrint('SignalR connected to $hubUrl');
      }
      await _rejoinJobs();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SignalR connect failed: $e');
      }
    }
  }

  Future<void> disconnect({bool clearJoined = true}) async {
    try {
      await _connection?.stop();
    } catch (_) {}
    _connection = null;
    if (clearJoined) _joinedJobs.clear();
  }

  Future<void> joinJob(int jobId) async {
    if (jobId <= 0) return;
    _joinedJobs[jobId] = (_joinedJobs[jobId] ?? 0) + 1;
    if ((_joinedJobs[jobId] ?? 0) > 1 && isConnected) return;

    if (!isConnected) await connect();
    await _invokeJoin(jobId);
  }

  Future<void> leaveJob(int jobId) async {
    if (jobId <= 0) return;
    final count = (_joinedJobs[jobId] ?? 0) - 1;
    if (count > 0) {
      _joinedJobs[jobId] = count;
      return;
    }
    _joinedJobs.remove(jobId);
    try {
      await _connection?.invoke('LeaveJob', args: <Object>[jobId]);
    } catch (e) {
      if (kDebugMode) debugPrint('LeaveJob failed: $e');
    }
  }

  Future<void> _rejoinJobs() async {
    if (!isConnected) return;
    for (final jobId in _joinedJobs.keys.toList()) {
      await _invokeJoin(jobId);
    }
  }

  Future<void> _invokeJoin(int jobId) async {
    try {
      await _connection?.invoke('JoinJob', args: <Object>[jobId]);
    } catch (e) {
      if (kDebugMode) debugPrint('JoinJob failed: $e');
    }
  }

  void _onJobOffer(List<Object?>? args) {
    final map = _asStringKeyedMap(args);
    if (map == null) return;
    try {
      final detail = JobDetail.fromJson(map);
      if (kDebugMode) {
        debugPrint('SignalR JobOffer id=${detail.id} status=${detail.status}');
      }
      jobOffer.value = null;
      jobOffer.value = detail;
    } catch (e) {
      if (kDebugMode) debugPrint('JobOffer parse error: $e raw=$map');
    }
  }

  void _onJobUpdated(List<Object?>? args) {
    final map = _asStringKeyedMap(args);
    if (map == null) return;
    try {
      final detail = JobDetail.fromJson(map);
      if (kDebugMode) {
        debugPrint('SignalR JobUpdated id=${detail.id} status=${detail.status}');
      }
      jobUpdated.value = null;
      jobUpdated.value = detail;
    } catch (e) {
      if (kDebugMode) debugPrint('JobUpdated parse error: $e raw=$map');
    }
  }

  void _onChatMessage(List<Object?>? args) {
    final map = _asStringKeyedMap(args);
    if (map == null) return;
    try {
      final msg = JobChatMessage.fromJson(map);
      if (kDebugMode) {
        debugPrint('SignalR ChatMessage job=${msg.jobId} id=${msg.id}');
      }
      chatMessage.value = null;
      chatMessage.value = msg;
    } catch (e) {
      if (kDebugMode) debugPrint('ChatMessage parse error: $e raw=$map');
    }
  }

  Map<String, dynamic>? _asStringKeyedMap(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;
    final raw = args.first;
    if (raw is Map) {
      return Map<String, dynamic>.from(
        raw.map((k, v) => MapEntry(k.toString(), v)),
      );
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return Map<String, dynamic>.from(
            decoded.map((k, v) => MapEntry(k.toString(), v)),
          );
        }
      } catch (_) {}
    }
    return null;
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
