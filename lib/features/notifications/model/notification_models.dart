import '../../../utils/json_helpers.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    this.title,
    this.body,
    this.type,
    this.jobId,
    this.isRead = false,
    this.createdOn,
  });

  final int id;
  final String? title;
  final String? body;
  final String? type;
  final int? jobId;
  final bool isRead;
  final DateTime? createdOn;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: JsonHelpers.pickInt(json, ['id', 'Id']) ?? 0,
      title: JsonHelpers.pickString(json, ['title', 'Title']),
      body: JsonHelpers.pickString(json, ['body', 'Body']),
      type: JsonHelpers.pickString(json, ['type', 'Type']),
      jobId: JsonHelpers.pickInt(json, [
        'fk_job_ID',
        'fkJobId',
        'FK_job_ID',
        'jobId',
        'JobId',
      ]),
      isRead: JsonHelpers.pickBool(json, ['is_Read', 'isRead', 'Is_Read']) ??
          false,
      createdOn: JsonHelpers.pickDate(json, ['createdOn', 'CreatedOn']),
    );
  }
}
