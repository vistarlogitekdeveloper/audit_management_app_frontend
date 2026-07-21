class ApiConstants {
  static const String baseUrl = 'https://vistar-crm.onrender.com/api/v1/audit';

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String updateFcmToken = '/auth/fcm-token';

  // Projects
  static const String projects = '/projects';

  // Users
  static const String users = '/users';
  static const String myProfile = '/users/me';
  static String userById(String id) => '/users/$id';

  // User-role lookups (sourced from users table, filtered by role + is_active)
  static const String projectIncharges = '/project-incharges';
  static const String clusterManagers = '/cluster-managers';
  static const String auditors = '/auditors';

  // Audit Plans
  static const String auditPlans = '/audit-plans';
  static const String releaseAuditPlans = '/audit-plans/release';
  static String auditPlanById(String id) => '/audit-plans/$id';
  static String releaseAuditPlanById(String id) =>
      '/audit-plans/$id/release';
  static String rescheduleAuditPlan(String id) =>
      '/audit-plans/$id/reschedule';
  static String cancelAuditPlan(String id) => '/audit-plans/$id';
  // Cascade hard-delete: removes the plan plus its sheet, parameters, photos,
  // action plan / items and associated S3 objects in a single transaction.
  static String hardDeleteAuditPlan(String id) =>
      '/audit-plans/$id/hard-delete';

  // Dashboard
  static const String adminDashboard = '/admin/dashboard';
  static const String ownerDashboard = '/owner/dashboard';
  static const String auditorDashboard = '/auditor/dashboard';

  // Audit Questions (admin-managed master list of audit points)
  static const String auditQuestions = '/audit-questions';
  static String auditQuestionById(String id) => '/audit-questions/$id';
  static const String reorderAuditQuestions = '/audit-questions/reorder';

  // Audit Sheets
  static String auditSheet(String auditPlanId) =>
      '/audit-sheets/$auditPlanId';
  static String submitAuditSheet(String id) => '/audit-sheets/$id/submit';
  /// Multipart POST that attaches a single photo to a parameter on the
  /// auditor's sheet. Returns a presigned HTTPS URL in `image_url` (and
  /// duplicated on `presigned_url` / `url` for backward compat).
  static String uploadAuditSheetImage(String id) =>
      '/audit-sheets/$id/upload-image';
  static String acknowledgeAuditSheet(String id) =>
      '/audit-sheets/$id/acknowledge';
  static String reviewAuditSheet(String id) => '/audit-sheets/$id/review';

  // Action Plans
  static const String actionPlans = '/action-plans';
  static const String actionPlansList = '/action-plans';
  static String actionPlanByAuditSheet(String auditSheetId) =>
      '/action-plans/$auditSheetId';
  static String actionPlanById(String id) => '/action-plans/$id';
  static String actionPlanItem(String id, String itemId) =>
      '/action-plans/$id/items/$itemId';
  /// Owner evidence files for one action-plan point. Multipart POST with the
  /// file under field name `file`; DELETE by attachment id.
  static String actionPlanItemAttachments(String planId, String itemId) =>
      '/action-plans/$planId/items/$itemId/attachments';
  static String actionPlanItemAttachment(
          String planId, String itemId, String attachmentId) =>
      '/action-plans/$planId/items/$itemId/attachments/$attachmentId';
  /// Auditor approves / rejects a single item with a remark.
  static String actionPlanItemReview(String planId, String itemId) =>
      '/action-plans/$planId/items/$itemId/review';
  /// Auditor closes the plan once every item is approved.
  static String actionPlanClose(String planId) =>
      '/action-plans/$planId/close';

  // Cluster
  static const String clusterDashboard = '/cluster/dashboard';

  // Reports
  static String report(String auditPlanId) => '/reports/$auditPlanId';
  static String reportPdf(String auditPlanId) =>
      '/reports/$auditPlanId/pdf';
  static String clusterReport(String clusterManagerId) =>
      '/reports/cluster/$clusterManagerId';
  static const String reportAnalytics = '/reports/analytics';
  static const String exportReports = '/reports/export';
  static const String exportReportsCsv = '/reports/export.csv';
  static const String exportReportsXlsx = '/reports/export.xlsx';
  static const String exportReportsPdf = '/reports/export.pdf';

  static const String releasedAudits = '/audit-plans';

  // Leads API (external — different backend, keeps its own /api prefix)
  static const String leadsBaseUrl =
      'https://client-entry-portal-backend.onrender.com';
  static const String wonLeads = '/api/leads/public/won';

  // Notifications
  static const String notifications = '/notifications';
  static String markNotificationRead(String id) =>
      '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static String deleteNotification(String id) => '/notifications/$id';
}
