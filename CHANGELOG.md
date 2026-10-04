# Changelog — Redmine Issue Checklists

All notable changes to this plugin.

## Unreleased

### Added

- Move checklist items up or down
- Copying an issue copies checklist items when the user can see the source issue and can manage checklists on the destination project
- GitHub Actions runs the plugin MiniTest suite inside the official Redmine 7.0.1 image (SQLite)

### Fixed

- Create, toggle, reorder, and delete refuse an issue the current user cannot see
- Validation errors stored in the flash are escaped. Redmine renders flash text as HTML

### Changed

- README compatibility: Redmine 7.0.1 on SQLite is verified by CI. Redmine 5.x, 6.x, other 7.x releases, MySQL, and PostgreSQL are declared and were not run

## [1.0.0] — 2026-09-16

First Community release. Free forever, no license key, no phone-home.

### Added

- Checklist panel on the issue page (below the description)
- Add, toggle done, and delete items
- Progress label and meter (`done / total`)
- Permission `manage_issue_checklists` on the issue tracking module
- Viewers without that permission see a read-only list
- Cap of 50 items per issue
- English + Vietnamese UI strings
- Reversible migration for table `issue_checklists`

[1.0.0]: https://redmineshop.com/products/redmine-issue-checklists
