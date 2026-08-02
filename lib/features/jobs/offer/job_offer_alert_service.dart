import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app_service/network/api_response.dart';
import '../../../app_service/notifications/local_notification_service.dart';
import '../../../app_service/notifications/pending_job_offer_store.dart';
import '../../../app_service/realtime/signalr_service.dart';
import '../../../common_widgets/app_snackbar.dart';
import '../../../utils/job_statuses.dart';
import '../model/job_models.dart';
import '../repository/job_repository.dart';
import 'job_offer_incoming_popup.dart';

/// Shows a PickMe-style popup + looping tone when a job offer arrives.
///
/// Background: posts a full-screen intent that opens the app, then shows
/// the same popup when the UI is resumed.
class JobOfferAlertService extends GetxService with WidgetsBindingObserver {
  final isShowing = false.obs;

  Worker? _offerWorker;
  Worker? _updatedWorker;
  AudioPlayer? _player;
  int? _activeOfferId;
  int? _lastHandledOfferId;
  JobDetail? _pendingOffer;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;
  bool _started = false;
  bool _seededKnownOffers = false;
  final Set<int> _knownOfferIds = <int>{};

  bool get handlesForegroundOffers =>
      _lifecycle == AppLifecycleState.resumed;

  bool get handlesOfferAlerts => true;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _attachSignalR();
    unawaited(consumeStoredPendingOffer());
  }

  void _attachSignalR() {
    if (!Get.isRegistered<SignalRService>()) return;
    final signalR = Get.find<SignalRService>();

    _offerWorker?.dispose();
    _updatedWorker?.dispose();

    _offerWorker = ever<JobDetail?>(signalR.jobOffer, (detail) {
      if (detail == null) return;
      if (kDebugMode) {
        debugPrint('JobOfferAlert: SignalR JobOffer id=${detail.id}');
      }
      unawaited(showIncomingOffer(detail, source: 'signalr_offer'));
    });

    _updatedWorker = ever<JobDetail?>(signalR.jobUpdated, (detail) {
      if (detail == null) return;
      if (!JobStatuses.isOffering(detail.status)) return;
      if (kDebugMode) {
        debugPrint(
          'JobOfferAlert: SignalR JobUpdated(Offering) id=${detail.id}',
        );
      }
      unawaited(showIncomingOffer(detail, source: 'signalr_updated'));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    if (state == AppLifecycleState.resumed) {
      unawaited(_onResumed());
    } else if (isShowing.value) {
      unawaited(_stopTone());
    }
  }

  Future<void> _onResumed() async {
    final pending = _pendingOffer;
    if (pending != null && !isShowing.value) {
      _pendingOffer = null;
      await _show(pending);
      return;
    }
    if (isShowing.value) {
      unawaited(_startTone());
      return;
    }
    await consumeStoredPendingOffer();
  }

  /// Open popup for a job id saved by the FCM background isolate / FSI wake.
  Future<void> consumeStoredPendingOffer() async {
    if (isShowing.value) return;
    final jobId = await PendingJobOfferStore.read(clear: true);
    if (jobId == null || jobId <= 0) return;
    if (kDebugMode) {
      debugPrint('JobOfferAlert: consuming stored pending offer id=$jobId');
    }
    await onPushOffer(jobId: jobId, forcePopup: true);
  }

  Future<void> onOffersLoaded(List<JobListItem> offers) async {
    final active = offers.where((o) {
      if (o.id <= 0) return false;
      final status = o.status?.trim();
      return status == null ||
          status.isEmpty ||
          JobStatuses.isOffering(status);
    }).toList();

    if (!_seededKnownOffers) {
      _seededKnownOffers = true;
      _knownOfferIds
        ..clear()
        ..addAll(active.map((o) => o.id));
      return;
    }

    for (final offer in active) {
      if (_knownOfferIds.contains(offer.id)) continue;
      _knownOfferIds.add(offer.id);
      await showIncomingOffer(
        _fromListItem(offer),
        source: 'offers_poll',
      );
      if (isShowing.value || _pendingOffer != null) break;
    }

    _knownOfferIds.removeWhere(
      (id) => active.every((o) => o.id != id),
    );
  }

  Future<void> onPushOffer({
    required int jobId,
    bool forcePopup = false,
  }) async {
    if (jobId <= 0) return;
    if (!Get.isRegistered<JobRepository>()) {
      await showIncomingOffer(
        JobDetail(id: jobId, status: JobStatuses.offering),
        source: 'fcm',
        forcePopup: forcePopup,
      );
      return;
    }
    try {
      final response = await Get.find<JobRepository>().getJob(jobId);
      final detail = response.result;
      if (detail == null) return;
      await showIncomingOffer(
        detail,
        source: 'fcm',
        forcePopup: forcePopup,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('JobOfferAlert: FCM fetch failed: $e');
      await showIncomingOffer(
        JobDetail(id: jobId, status: JobStatuses.offering),
        source: 'fcm',
        forcePopup: forcePopup,
      );
    }
  }

  Future<void> showIncomingOffer(
    JobDetail detail, {
    String source = 'unknown',
    bool forcePopup = false,
  }) async {
    if (detail.id <= 0) return;

    final status = detail.status?.trim();
    if (status != null &&
        status.isNotEmpty &&
        !JobStatuses.isOffering(status)) {
      return;
    }

    if (detail.id == _activeOfferId) return;
    if (isShowing.value) return;

    if (_isViewingOffer(detail.id) && !forcePopup) {
      _lastHandledOfferId = detail.id;
      _knownOfferIds.add(detail.id);
      return;
    }

    if (!forcePopup &&
        detail.id == _lastHandledOfferId &&
        _pendingOffer?.id != detail.id) {
      return;
    }

    _knownOfferIds.add(detail.id);

    final inForeground =
        forcePopup || _lifecycle == AppLifecycleState.resumed;

    if (!inForeground) {
      // App is backgrounded: wake with full-screen intent, then popup on resume.
      if (kDebugMode) {
        debugPrint(
          'JobOfferAlert: background wake id=${detail.id} via $source',
        );
      }
      _pendingOffer = detail;
      _lastHandledOfferId = detail.id;
      await _postBackgroundOfferNotification(detail);
      return;
    }

    if (kDebugMode) {
      debugPrint('JobOfferAlert: showing popup id=${detail.id} via $source');
    }
    await _show(detail);
  }

  Future<void> _postBackgroundOfferNotification(JobDetail detail) async {
    await PendingJobOfferStore.save(detail.id);

    final preview = detail.problemText?.trim();
    final body = (preview != null && preview.isNotEmpty)
        ? (preview.length > 80 ? '${preview.substring(0, 80)}...' : preview)
        : 'Incoming job request';

    if (Get.isRegistered<LocalNotificationService>()) {
      await Get.find<LocalNotificationService>().showJobOffer(
        title: 'Incoming job request',
        body: body,
        jobId: detail.id,
      );
      return;
    }

    await showOneeJobOfferBanner(
      title: 'Incoming job request',
      body: body,
      jobId: detail.id,
    );
  }

  bool _isViewingOffer(int jobId) {
    if (Get.currentRoute != AppRoutes.offerDetail) return false;
    final args = Get.arguments;
    if (args is int) return args == jobId;
    if (args is Map) {
      final raw = args['jobId'] ?? args['id'];
      if (raw is int) return raw == jobId;
      return int.tryParse(raw?.toString() ?? '') == jobId;
    }
    return false;
  }

  Future<void> _show(JobDetail detail) async {
    if (isShowing.value) return;

    isShowing.value = true;
    _activeOfferId = detail.id;
    _lastHandledOfferId = detail.id;
    _pendingOffer = null;
    unawaited(PendingJobOfferStore.clearIfJob(detail.id));

    if (Get.isRegistered<LocalNotificationService>()) {
      unawaited(
        Get.find<LocalNotificationService>().cancelJobOffer(detail.id),
      );
    }

    unawaited(_startTone());

    try {
      await showJobOfferIncomingPopup(
        job: detail,
        onAccept: () => _accept(detail),
        onDecline: () => _decline(detail),
        onView: () => _viewDetails(detail),
        onExpired: () => _dismiss(expired: true),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('JobOfferAlert: dialog failed: $e');
    } finally {
      await _cleanupAfterClose();
    }
  }

  Future<void> _accept(JobDetail detail) async {
    if (!Get.isRegistered<JobRepository>()) return;
    try {
      await Get.find<JobRepository>().accept(detail.id);
      await _dismiss();
      Get.toNamed(AppRoutes.jobDetail, arguments: {'jobId': detail.id});
      AppSnackbar.success('Job accepted.');
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('Failed to accept offer.');
    }
  }

  Future<void> _decline(JobDetail detail) async {
    if (!Get.isRegistered<JobRepository>()) return;
    try {
      await Get.find<JobRepository>().decline(detail.id);
      await _dismiss();
      AppSnackbar.info('Offer declined.');
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('Failed to decline offer.');
    }
  }

  Future<void> _viewDetails(JobDetail detail) async {
    await _dismiss();
    Get.toNamed(AppRoutes.offerDetail, arguments: {'jobId': detail.id});
  }

  Future<void> _dismiss({bool expired = false}) async {
    await _stopTone();
    if (Get.isDialogOpen == true) {
      Get.back();
    }
    if (expired) {
      AppSnackbar.info('Job offer expired.');
    }
  }

  Future<void> _cleanupAfterClose() async {
    await _stopTone();
    isShowing.value = false;
    _activeOfferId = null;
  }

  Future<void> _startTone() async {
    try {
      _player ??= AudioPlayer();
      await _player!.stop();
      await _player!.setReleaseMode(ReleaseMode.loop);
      await _player!.setVolume(1.0);
      await _player!.play(AssetSource('sounds/job_offer_ring.wav')).timeout(
            const Duration(seconds: 3),
          );
    } catch (e) {
      if (kDebugMode) debugPrint('Job offer tone failed: $e');
    }
  }

  Future<void> _stopTone() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }

  static JobDetail _fromListItem(JobListItem offer) {
    return JobDetail(
      id: offer.id,
      problemText: offer.problemText,
      categoryName: offer.categoryName,
      customerName: offer.customerName,
      workerName: offer.workerName,
      status: offer.status ?? JobStatuses.offering,
      amount: offer.amount,
      offerExpiresAt: offer.offerExpiresAt,
      customerLatitude: offer.customerLatitude,
      customerLongitude: offer.customerLongitude,
      createdOn: offer.createdOn,
    );
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _offerWorker?.dispose();
    _updatedWorker?.dispose();
    _player?.dispose();
    _player = null;
    super.onClose();
  }
}
