class ApiConstants {
  static const String baseUrl =
      'https://audit-management-app-backend.onrender.com';

  // Auth
  static const String login = '/api/auth/login';
  static const String logout = '/api/auth/logout';
  static const String refreshToken = '/api/auth/refresh';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';
  static const String updateFcmToken = '/api/auth/fcm-token';

  // Projects
  static const String projects = '/api/projects';

  // Users
  static const String users = '/api/users';
  static const String myProfile = '/api/users/me';
  static String userById(String id) => '/api/users/$id';

  // User-role lookups (sourced from users table, filtered by role + is_active)
  static const String projectIncharges = '/api/project-incharges';
  static const String clusterManagers = '/api/cluster-managers';
  static const String auditors = '/api/auditors';

  // Audit Plans
  static const String auditPlans = '/api/audit-plans';
  static const String releaseAuditPlans = '/api/audit-plans/release';
  static String auditPlanById(String id) => '/api/audit-plans/$id';
  static String releaseAuditPlanById(String id) =>
      '/api/audit-plans/$id/release';
  static String rescheduleAuditPlan(String id) =>
      '/api/audit-plans/$id/reschedule';
  static String cancelAuditPlan(String id) => '/api/audit-plans/$id';

  // Dashboard
  static const String adminDashboard = '/api/admin/dashboard';
  static const String ownerDashboard = '/api/owner/dashboard';
  static const String auditorDashboard = '/api/auditor/dashboard';

  // Audit Sheets
  static String auditSheet(String auditPlanId) =>
      '/api/audit-sheets/$auditPlanId';
  static String uploadAuditSheetImage(String id) =>
      '/api/audit-sheets/$id/upload-image';
  static String submitAuditSheet(String id) => '/api/audit-sheets/$id/submit';
  static String acknowledgeAuditSheet(String id) =>
      '/api/audit-sheets/$id/acknowledge';
  static String reviewAuditSheet(String id) => '/api/audit-sheets/$id/review';

  // Action Plans
  static const String actionPlans = '/api/action-plans';
  static const String actionPlansList = '/api/action-plans';
  static String actionPlanByAuditSheet(String auditSheetId) =>
      '/api/action-plans/$auditSheetId';
  static String actionPlanById(String id) => '/api/action-plans/$id';
  static String actionPlanItem(String id, String itemId) =>
      '/api/action-plans/$id/items/$itemId';

  // Cluster
  static const String clusterDashboard = '/api/cluster/dashboard';

  // Reports
  static String report(String auditPlanId) => '/api/reports/$auditPlanId';
  static String reportPdf(String auditPlanId) =>
      '/api/reports/$auditPlanId/pdf';
  static String clusterReport(String clusterManagerId) =>
      '/api/reports/cluster/$clusterManagerId';
  static const String exportReports = '/api/reports/export';
  static const String exportReportsCsv = '/api/reports/export.csv';
  static const String exportReportsXlsx = '/api/reports/export.xlsx';
  static const String exportReportsPdf = '/api/reports/export.pdf';

  static const String releasedAudits = '/api/audit-plans';

  // Leads API (external)
  static const String leadsBaseUrl =
      'https://client-entry-portal-backend.onrender.com';
  static const String wonLeads = '/api/leads/public/won';

  // Notifications
  static const String notifications = '/api/notifications';
  static String markNotificationRead(String id) =>
      '/api/notifications/$id/read';
  static const String markAllNotificationsRead = '/api/notifications/read-all';
  static String deleteNotification(String id) => '/api/notifications/$id';
}
