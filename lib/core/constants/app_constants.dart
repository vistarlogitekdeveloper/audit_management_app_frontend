class AppConstants {
  // SharedPreferences keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userRoleKey = 'user_role';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userEmailKey = 'user_email';
  static const String notificationsAskedKey = 'notifications_permission_requested';
  // "Remember me" on login — stores the flag and the email we prefill with
  // on the next launch. We intentionally never persist the password.
  static const String rememberMeKey = 'login_remember_me';
  static const String rememberedEmailKey = 'login_remembered_email';
  // Active theme mode: "system" | "light" | "dark". Defaults to dark
  // (the launch experience for Vistar Premium) when unset.
  static const String themeModeKey = 'app_theme_mode';

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

  // "What the auditor is checking for" description for each audit parameter,
  // keyed by the parameter name. Shown under the parameter title on the audit
  // sheet so the team understands the audit scope. Keys must match
  // [auditParameters] exactly — a name with no entry here simply renders no
  // description (never an error), so this map is safe to leave partially
  // populated.
  static const Map<String, String> auditParameterDescriptions = {
    '5S and hygiene of workplace':
        'Overall 5S at individual work place as well as project site. '
        'Awareness of 5S to the team as well as its utilization during daily '
        'work.',
    'Org structure display':
        'Availability of updated organization display in clean, neat and '
        'visible format.',
    'Vision / Mission / Safety policies display':
        'Availability of Vision / Mission / Safety / Environmental Policies '
        'display.',
    'Daily Sunrise meeting / Safety Oath':
        'Evidence of Sunrise meeting and key topic discussions — Safety, 5S, '
        'KAIZEN, daily work activity and other (SQDCM). Evidence to be gathered '
        'from random employees.',
    'Uniform / PPE used by all':
        'Availability of uniform and PPE in good condition with all employees.',
    'Alertness of security':
        'When security is in Vistar scope, its alertness needs to be ensured '
        'by the Site Project Owner.',
    'CCTV availability and monitoring':
        'CCTV available, in working condition and being monitored at regular '
        'frequency.',
    'Layout display':
        'Clear layout display of warehouse indicating key areas within Vistar '
        'control.',
    'Safety Observation Tour':
        'Evidence of planned SOT as per agreed frequency, listing safety '
        'observations as well as action plan.',
    'Vistar Way Matrix review':
        'Effective utilization of Vistar Way Matrix to bring efficiency in '
        'operation. Awareness level to project manager as well as next level.',
    'Inward / Outward / Visitor entry registers':
        'Documentation and effective usage of system for Inward, Outward, '
        'Visitor entry and Gate pass: Security Registers.',
    'Customer complaints recording':
        'Customer complaint tracker along with relevant data, RCA and CAPA.',
    'KPI / SLA reports + Awareness':
        'Daily SLA availability, monitoring and review. Awareness to key team '
        'members. Actions towards deviations in SLA.',
    'SOP availability + Awareness':
        'Availability of SOP at site. SOP awareness by operator and evidence '
        'of SOP review.',
    'CSI score / Action plan':
        'Customer survey at regular interval, with action plan on low score.',
    'Top 5 Problems / Challenges list':
        'List of top 5 challenges / problems — awareness and action plan '
        'towards the same.',
    'Training calendar / attendance':
        'Training plan and training records. Training linked to skill matrix '
        'and customer complaints and issues.',
    'Skill Matrix availability':
        'Skill matrix with reference to working skills as well as other topics '
        'such as 5S, KAIZEN, RCA and problem solving.',
    'KAIZEN implementation':
        'KAIZEN awareness to project team and effectiveness of KAIZEN roll out '
        '(including horizontal deployment).',
    'Regular attendance submitted to HR':
        'Discipline in attendance submission and leave records.',
    'Random check of one process':
        'Detailed audit for one of the key processes of operation.',
    'Awareness of customer pain area':
        'Customer pain areas within and beyond Vistar scope listed, with '
        'action plan for resolution / support ready with the Project Manager. '
        'Effective communication about the same to the team.',
    'Energy saving awareness':
        'Awareness and initiative towards energy, water saving and waste '
        'elimination.',
    'Employee / Customer connect':
        'Employee as well as customer connect should be evident during '
        'interaction with employees and the customer representative.',
  };

  /// Description shown under an audit parameter title. Returns null when the
  /// parameter has no description, so callers can conditionally hide the line.
  static String? auditParameterDescription(String name) =>
      auditParameterDescriptions[name];

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
