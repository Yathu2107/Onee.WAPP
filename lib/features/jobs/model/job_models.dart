import '../../../utils/json_helpers.dart';

class JobListItem {
  const JobListItem({
    required this.id,
    this.problemText,
    this.categoryName,
    this.customerName,
    this.workerName,
    this.status,
    this.amount,
    this.offerExpiresAt,
    this.customerLatitude,
    this.customerLongitude,
    this.createdOn,
  });

  final int id;
  final String? problemText;
  final String? categoryName;
  final String? customerName;
  final String? workerName;
  final String? status;
  final double? amount;
  final DateTime? offerExpiresAt;
  final double? customerLatitude;
  final double? customerLongitude;
  final DateTime? createdOn;

  factory JobListItem.fromJson(Map<String, dynamic> json) {
    return JobListItem(
      id: JsonHelpers.pickInt(json, ['id', 'Id']) ?? 0,
      problemText: JsonHelpers.pickString(json, [
        'problem_Text',
        'problemText',
        'Problem_Text',
      ]),
      categoryName: JsonHelpers.pickString(json, [
        'category_Name',
        'categoryName',
        'Category_Name',
      ]),
      customerName: JsonHelpers.pickString(json, [
        'customer_Name',
        'customerName',
      ]),
      workerName: JsonHelpers.pickString(json, [
        'worker_Name',
        'workerName',
        'Worker_Name',
      ]),
      status: JsonHelpers.pickString(json, ['status', 'Status']),
      amount: JsonHelpers.pickDouble(json, ['amount', 'Amount']),
      offerExpiresAt: JsonHelpers.pickDate(json, [
        'offer_Expires_At',
        'offerExpiresAt',
        'Offer_Expires_At',
      ]),
      customerLatitude: JsonHelpers.pickDouble(json, [
        'customer_Latitude',
        'customerLatitude',
      ]),
      customerLongitude: JsonHelpers.pickDouble(json, [
        'customer_Longitude',
        'customerLongitude',
      ]),
      createdOn: JsonHelpers.pickDate(json, ['createdOn', 'CreatedOn']),
    );
  }
}

class JobChatMessage {
  const JobChatMessage({
    required this.id,
    required this.jobId,
    required this.senderId,
    this.senderName,
    required this.message,
    this.createdOn,
  });

  final int id;
  final int jobId;
  final String senderId;
  final String? senderName;
  final String message;
  final DateTime? createdOn;

  factory JobChatMessage.fromJson(Map<String, dynamic> json) {
    return JobChatMessage(
      id: JsonHelpers.pickInt(json, ['id', 'Id']) ?? 0,
      jobId: JsonHelpers.pickInt(json, [
            'fk_job_ID',
            'fK_job_ID',
            'fkJobId',
            'FK_job_ID',
          ]) ??
          0,
      senderId: JsonHelpers.pickString(json, [
            'fk_sender_ID',
            'fK_sender_ID',
            'fkSenderId',
            'FK_sender_ID',
          ]) ??
          '',
      senderName: JsonHelpers.pickString(json, [
        'sender_Name',
        'senderName',
        'Sender_Name',
      ]),
      message: JsonHelpers.pickString(json, ['message', 'Message']) ?? '',
      createdOn: JsonHelpers.pickDate(json, ['createdOn', 'CreatedOn']),
    );
  }
}

class JobRating {
  const JobRating({
    this.id,
    this.rating,
    this.feedback,
  });

  final int? id;
  final int? rating;
  final String? feedback;

  factory JobRating.fromJson(Map<String, dynamic> json) {
    return JobRating(
      id: JsonHelpers.pickInt(json, ['id', 'Id']),
      rating: JsonHelpers.pickInt(json, ['rating', 'Rating']),
      feedback: JsonHelpers.pickString(json, ['feedback', 'Feedback']),
    );
  }
}

class JobDetail {
  const JobDetail({
    required this.id,
    this.problemText,
    this.categoryId,
    this.categoryName,
    this.customerId,
    this.customerName,
    this.workerId,
    this.workerName,
    this.status,
    this.amount,
    this.cancelReason,
    this.offerExpiresAt,
    this.customerLatitude,
    this.customerLongitude,
    this.createdOn,
    this.messages = const [],
    this.hasRating = false,
    this.rating,
  });

  final int id;
  final String? problemText;
  final int? categoryId;
  final String? categoryName;
  final String? customerId;
  final String? customerName;
  final String? workerId;
  final String? workerName;
  final String? status;
  final double? amount;
  final String? cancelReason;
  final DateTime? offerExpiresAt;
  final double? customerLatitude;
  final double? customerLongitude;
  final DateTime? createdOn;
  final List<JobChatMessage> messages;
  final bool hasRating;
  final JobRating? rating;

  factory JobDetail.fromJson(Map<String, dynamic> json) {
    final ratingJson = json['rating'] ?? json['Rating'];
    return JobDetail(
      id: JsonHelpers.pickInt(json, ['id', 'Id']) ?? 0,
      problemText: JsonHelpers.pickString(json, [
        'problem_Text',
        'problemText',
        'Problem_Text',
      ]),
      categoryId: JsonHelpers.pickInt(json, [
        'category_id',
        'categoryId',
        'Category_id',
      ]),
      categoryName: JsonHelpers.pickString(json, [
        'category_Name',
        'categoryName',
        'Category_Name',
      ]),
      customerId: JsonHelpers.pickString(json, [
        'fK_customer_ID',
        'fk_customer_ID',
        'fkCustomerId',
      ]),
      customerName: JsonHelpers.pickString(json, [
        'customer_Name',
        'customerName',
      ]),
      workerId: JsonHelpers.pickString(json, [
        'fK_worker_ID',
        'fk_worker_ID',
        'fkWorkerId',
      ]),
      workerName: JsonHelpers.pickString(json, [
        'worker_Name',
        'workerName',
        'Worker_Name',
      ]),
      status: JsonHelpers.pickString(json, ['status', 'Status']),
      amount: JsonHelpers.pickDouble(json, ['amount', 'Amount']),
      cancelReason: JsonHelpers.pickString(json, [
        'cancel_Reason',
        'cancelReason',
        'Cancel_Reason',
      ]),
      offerExpiresAt: JsonHelpers.pickDate(json, [
        'offer_Expires_At',
        'offerExpiresAt',
        'Offer_Expires_At',
      ]),
      customerLatitude: JsonHelpers.pickDouble(json, [
        'customer_Latitude',
        'customerLatitude',
      ]),
      customerLongitude: JsonHelpers.pickDouble(json, [
        'customer_Longitude',
        'customerLongitude',
      ]),
      createdOn: JsonHelpers.pickDate(json, ['createdOn', 'CreatedOn']),
      messages: JsonHelpers.pickList(
        json,
        ['messages', 'Messages'],
        JobChatMessage.fromJson,
      ),
      hasRating: JsonHelpers.pickBool(json, ['hasRating', 'HasRating']) ?? false,
      rating: ratingJson is Map
          ? JobRating.fromJson(Map<String, dynamic>.from(ratingJson))
          : null,
    );
  }
}
