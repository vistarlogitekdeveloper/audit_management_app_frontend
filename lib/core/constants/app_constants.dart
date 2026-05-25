class AppConstants {
  // SharedPreferences keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userRoleKey = 'user_role';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userEmailKey = 'user_email';
  static const String notificationsAskedKey = 'notifications_permission_requested';

  // Roles
  static const String roleAdmin = 'Admin';
  static const String roleAuditor = 'Auditor';
  static const String roleProjectOwner = 'ProjectOwner';
  static const String roleClusterManager = 'ClusterManager';
  static const List<String> allRoles = [
    roleAdmin,
    roleAuditor,
    roleProjectOwner,
    roleClusterManager,
  ];

  // Audit statuses. Only values that appear in the backend Sequelize enums are
  // kept here — anything the server never returns is dead and was removed.
  //   AuditPlan.status:  draft, released, submitted, acknowledged, completed,
  //                      closed, cancelled
  //   AuditSheet.status: not_started, draft, submitted, acknowledged
  static const String statusNotStarted = 'not_started';
  static const String statusDraft = 'draft';
  static const String statusReleased = 'released';
  static const String statusSubmitted = 'submitted';
  static const String statusAcknowledged = 'acknowledged';
  static const String statusCompleted = 'completed';
  static const String statusClosed = 'closed';
  static const String statusCancelled = 'cancelled';

  // Action plan statuses
  static const String apOpen = 'Open';
  static const String apInProgress = 'In Progress';
  static const String apClosed = 'Closed';

  // Audit result values
  static const String resultPass = 'pass';
  static const String resultFail = 'fail';
  static const String resultNA = 'na';

  // Audit parameters (24 total)
  static const List<String> auditParameters = [
    '5S and hygiene of workplace',
    'Org structure display',
    'Vision / Mission / Safety policies display',
    'Daily Sunrise meeting / Safety Oath',
    'Uniform / PPE used by all',
    'Alertness of security',
    'CCTV availability and monitoring',
    'Layout display',
    'Safety Observation Tour',
    'Vistar Way Matrix review',
    'Inward / Outward / Visitor entry registers',
    'Customer complaints recording',
    'KPI / SLA reports + Awareness',
    'SOP availability + Awareness',
    'CSI score / Action plan',
    'Top 5 Problems / Challenges list',
    'Training calendar / attendance',
    'Skill Matrix availability',
    'KAIZEN implementation',
    'Regular attendance submitted to HR',
    'Random check of one process',
    'Awareness of customer pain area',
    'Energy saving awareness',
    'Employee / Customer connect',
  ];

  // Max image size in bytes (500KB)
  static const int maxImageSizeBytes = 500 * 1024;

  // Action plan deadline (days from audit date)
  static const int actionPlanDeadlineDays = 8;

  static const String notificationEmail = 'email';
  static const String notificationReminder = 'reminder';
  static const String notificationSuccess = 'success';
  static const String notificationOverdue = 'overdue';

  static String normalizeRole(String? rawRole) {
    final value = (rawRole ?? '').trim().toLowerCase();
    switch (value) {
      case 'admin':
        return roleAdmin;
      case 'auditor':
        return roleAuditor;
      case 'projectowner':
      case 'project_owner':
      case 'project owner':
      case 'owner':
        return roleProjectOwner;
      case 'clustermanager':
      case 'cluster_manager':
      case 'cluster manager':
      case 'cluster':
        return roleClusterManager;
      default:
        return rawRole ?? '';
    }
  }
}
