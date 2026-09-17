# Changelog — Redmine Issue Checklists

All notable changes to this plugin.

## [1.0.1] — 2026-09-17

Community maintenance pass (GitHub-first docs, syntax CI, issue visibility).

### Security

- Create, toggle, and delete now require the parent issue to be visible to the current user (`Issue#visible?` / `Unauthorized`), matching Redmine core `find_issue`. Project permission alone is not enough.

### Changed

- Plugin `url` in `init.rb` points at the GitHub repository
- README: **Last maintained: 2026-09-17**, GitHub clone as the install path, honest compatibility notes (syntax CI only; no live Redmine in Actions)
- CI: `permissions: contents: read`, fail if no `.rb` files, compile ERB templates

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

[1.0.1]: https://github.com/redmineshop/redmine_issue_checklists
[1.0.0]: https://github.com/redmineshop/redmine_issue_checklists
