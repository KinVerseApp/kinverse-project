import subprocess
import textwrap

issues = [
    {
        "id": "KV-001",
        "epic": "Authentication",
        "title": "Registration UI",
        "summary": "Create the user registration screen and validation flow for new accounts.",
    },
    {
        "id": "KV-002",
        "epic": "Authentication",
        "title": "Login UI",
        "summary": "Create the sign-in experience with email/password entry and error states.",
    },
    {
        "id": "KV-003",
        "epic": "Authentication",
        "title": "Forgot Password",
        "summary": "Allow users to request a password reset email and complete a secure reset flow.",
    },
    {
        "id": "KV-004",
        "epic": "Authentication",
        "title": "Registration API",
        "summary": "Implement backend endpoints and validation for account creation and duplicate checks.",
    },
    {
        "id": "KV-005",
        "epic": "Authentication",
        "title": "JWT Authentication",
        "summary": "Implement stateless authentication tokens and secure session handling.",
    },
    {
        "id": "KV-006",
        "epic": "Authentication",
        "title": "Authentication Integration",
        "summary": "Connect the frontend and backend flows so the app enforces protected routes and user identity.",
    },
    {
        "id": "KV-007",
        "epic": "Profile",
        "title": "Create Profile",
        "summary": "Allow a newly registered user to create their profile details.",
    },
    {
        "id": "KV-008",
        "epic": "Profile",
        "title": "Edit Profile",
        "summary": "Enable users to update their personal information after onboarding.",
    },
    {
        "id": "KV-009",
        "epic": "Profile",
        "title": "Upload Profile Picture",
        "summary": "Let users upload, preview, and store a profile photo.",
    },
    {
        "id": "KV-010",
        "epic": "Profile",
        "title": "Privacy Settings",
        "summary": "Provide controls for visibility and access to personal profile information.",
    },
    {
        "id": "KV-011",
        "epic": "Family Tree",
        "title": "Tree Screen",
        "summary": "Implement the main family tree screen and navigation model.",
    },
    {
        "id": "KV-012",
        "epic": "Family Tree",
        "title": "Tree Node Widget",
        "summary": "Create the reusable UI element that represents a person in the tree.",
    },
    {
        "id": "KV-013",
        "epic": "Family Tree",
        "title": "Relative Card",
        "summary": "Show summary details for each relative in a compact card layout.",
    },
    {
        "id": "KV-014",
        "epic": "Family Tree",
        "title": "Expand Branch",
        "summary": "Allow users to expand a node and reveal more relatives in the tree.",
    },
    {
        "id": "KV-015",
        "epic": "Family Tree",
        "title": "Collapse Branch",
        "summary": "Allow users to collapse branches to reduce visual clutter.",
    },
    {
        "id": "KV-016",
        "epic": "Family Tree",
        "title": "Search Relative",
        "summary": "Add search and navigation to quickly find relatives in the tree.",
    },
    {
        "id": "KV-017",
        "epic": "Relationships",
        "title": "Add Relative",
        "summary": "Support adding a new person and connecting them to the family record.",
    },
    {
        "id": "KV-018",
        "epic": "Relationships",
        "title": "Edit Relative",
        "summary": "Allow updates to a relative's details after initial creation.",
    },
    {
        "id": "KV-019",
        "epic": "Relationships",
        "title": "Delete Relative",
        "summary": "Allow authorized removal of a relative with a safe confirmation flow.",
    },
    {
        "id": "KV-020",
        "epic": "Relationships",
        "title": "Relationship Validation",
        "summary": "Prevent invalid parent/child or spouse links and enforce graph integrity.",
    },
    {
        "id": "KV-021",
        "epic": "Invitations",
        "title": "Email Invite",
        "summary": "Send invite emails to family members to join the app.",
    },
    {
        "id": "KV-022",
        "epic": "Invitations",
        "title": "SMS Invite",
        "summary": "Send invite text messages for mobile users who prefer SMS.",
    },
    {
        "id": "KV-023",
        "epic": "Invitations",
        "title": "Invite Acceptance",
        "summary": "Process user acceptance of invitations and activate the relationship.",
    },
    {
        "id": "KV-024",
        "epic": "Invitations",
        "title": "Invite Status Tracking",
        "summary": "Track each invite from sent to accepted, expired, or rejected states.",
    },
    {
        "id": "KV-025",
        "epic": "Notifications",
        "title": "Birthday Notifications",
        "summary": "Notify users about upcoming or current birthdays within their family network.",
    },
    {
        "id": "KV-026",
        "epic": "Notifications",
        "title": "Invite Accepted Notifications",
        "summary": "Notify family members when an invitation is accepted.",
    },
    {
        "id": "KV-027",
        "epic": "Notifications",
        "title": "Notification Center",
        "summary": "Provide a central place for users to review all notifications and their statuses.",
    },
]

acceptance_templates = {
    "Authentication": [
        "User can successfully register using valid data.",
        "Validation errors are shown for invalid or duplicate input.",
        "The app securely stores user credentials or uses approved backend protection.",
        "Users can sign in and remain authenticated with protected routes.",
        "Reset-password flow is available and functional.",
    ],
    "Profile": [
        "User can create a profile on first access.",
        "User can edit profile fields without losing data.",
        "Profile picture upload works with preview and storage.",
        "Privacy settings are persisted and enforced.",
    ],
    "Family Tree": [
        "The tree screen loads family data and displays relatives correctly.",
        "Nodes are clickable and show context-specific actions.",
        "Branches can expand and collapse without breaking layout.",
        "Search returns relevant relatives quickly and accurately.",
    ],
    "Relationships": [
        "Users can add, edit, and delete relatives with confirmation flows.",
        "Relationship rules prevent invalid or duplicate connections.",
        "Saved relationships are reflected consistently in the tree and profile data.",
    ],
    "Invitations": [
        "Invite emails and texts are sent with correct content and tracking metadata.",
        "Accepted invites create the right account or connection state.",
        "Invite states are visible to the user and updated correctly.",
    ],
    "Notifications": [
        "Birthday and invitation events generate notifications.",
        "Users can view notifications in a single center.",
        "Notification status is clear and actionable.",
    ],
}


def build_body(issue):
    criteria = acceptance_templates.get(issue["epic"], ["Feature works as expected."])
    title_lower = issue["title"].lower()
    epic = issue["epic"]
    lines = [
        f"## Epic\n{epic}",
        f"\n## Summary\n{issue['summary']}",
        f"\n## User Story\nAs a user, I want to {title_lower} so that I can successfully use the KinVerse experience.",
        f"\n## Description\nThis issue covers the implementation of {title_lower} within the {epic} epic. The work should include the full user flow, validation, and backend/frontend integration required for a production-ready experience.",
        "\n## Acceptance Criteria",
        f"- {criteria[0]}",
        f"- {criteria[1] if len(criteria) > 1 else 'The feature is consistent with the product design and UX patterns.'}",
        f"- {criteria[2] if len(criteria) > 2 else 'The feature handles error states and empty states gracefully.'}",
        f"- {criteria[3] if len(criteria) > 3 else 'The feature is accessible and supports mobile-first interaction patterns.'}",
        f"- {criteria[4] if len(criteria) > 4 else 'The feature is documented and ready for QA review.'}",
        "\n## Definition of Done",
        "- Code is implemented and reviewed.",
        "- Required validations and edge cases are covered.",
        "- The behavior is testable in the application.",
        "- Documentation or handoff notes are updated as needed.",
        "\n## Notes",
        "- Depends on related backlog items and shared domain models.",
        "- Should be implemented with product-first UX and security considerations in mind.",
        "- Must be compatible with existing user flows and data models.",
    ]
    return textwrap.dedent("\n".join(lines))


for issue in issues:
    title = f"{issue['id']} {issue['title']}"
    body = build_body(issue)
    result = subprocess.run(
        [
            "gh",
            "issue",
            "create",
            "--repo",
            "KinVerseApp/kinverse-project",
            "--title",
            title,
            "--body",
            body,
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"FAILED: {title}")
        print(result.stderr)
        raise SystemExit(result.returncode)
    print(result.stdout.strip())

print(f"Created {len(issues)} GitHub issues in KinVerseApp/kinverse-project")
