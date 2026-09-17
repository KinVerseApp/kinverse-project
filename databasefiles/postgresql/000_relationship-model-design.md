# KinVerse — Family Relationship Data Model

This document explains the graph-based data model used by the KinVerse database.

## Core rule

Store only two edge types:
- `parent_child`
- `partner`

Everything else is derived through recursive queries instead of being stored as a new column or a hard-coded relationship label.

## Schema responsibilities

- `user_account`: authentication and login metadata
- `person`: people in all trees, registered or unclaimed
- `relationship_edge`: the actual graph
- `privacy_setting`: field-level visibility
- `invitation`: invites, links, QR-based joins
- `notification`: in-app alerts
- `contact_match` and `story`: future-phase stubs

## Validation sample

The sample tree in `002_seed_sample.sql` creates a small family tree that supports:
- parent / grandparent ancestry
- sibling detection
- spouse lookup
- aunt/uncle and cousin detection
- in-law queries

This graph model is intentionally designed to avoid schema churn as the app grows.
