# Redmine Issue Checklists

**Last maintained: 2026-09-17**

**Community edition — free forever, MIT.** No license key, no phone-home, no account required to install.

Source of truth: [github.com/redmineshop/redmine_issue_checklists](https://github.com/redmineshop/redmine_issue_checklists).

Interactive checklists on Redmine issues — add items, mark them done, and see progress on the issue page. Built for self-hosted teams that want a Definition of Done without turning every step into a subtask.

Optional product overview (not required to install): [redmineshop.com/products/redmine-issue-checklists](https://redmineshop.com/products/redmine-issue-checklists).

## Features

- Checklist box on **Issues → show** (below the description)
- Add, toggle done, and delete items (HTML forms; checkbox toggle also works with a small script)
- Progress: `N of M done` plus a meter
- Permission: `manage_issue_checklists` (issue tracking)
- Anyone who can view the issue can see the list; only the permission can change it
- Mutations also require the issue to be visible to the current user (`Issue#visible?`)
- Maximum 50 items per issue
- English + Vietnamese UI strings

## Compatibility

`init.rb` declares `requires_redmine version_or_higher: '5.0'`. That is the **declared** floor, not a tested matrix.

This maintenance pass ran **GitHub Actions syntax CI only** (Ruby 3.2 `ruby -c` on every `.rb`, plus ERB compile). There is **no live Redmine** in this repository’s Actions workflow, so runtime compatibility with a specific Redmine/Ruby/database combination was **not** verified here.

| Redmine | Typical Ruby | Database | What this pass verified |
|---------|--------------|----------|-------------------------|
| 6.x | 3.2+ | MySQL 8 / PostgreSQL | Declared target. Syntax CI (Ruby 3.2) only. |
| 5.1.x | 3.1+ | MySQL 8 / PostgreSQL | Declared target. Not booted against Redmine in this pass. |
| 5.0.x | 3.0+ | MySQL 8 / PostgreSQL | Minimum declared (`requires_redmine`). Not booted against Redmine in this pass. |

Plugin tests under `test/` are standard Redmine plugin tests; they need a Redmine application tree (see Tests). Do not read the table above as a published QA matrix.

## Installation

**Estimated time: 5–10 minutes.** Clone from GitHub — that is the install path.

### 1. Clone from GitHub

```bash
cd /path/to/redmine/plugins
git clone https://github.com/redmineshop/redmine_issue_checklists.git
ls redmine_issue_checklists/init.rb
```

Do not rename the plugin directory. If you download a GitHub ZIP, rename the unpacked `redmine_issue_checklists-main` folder to `redmine_issue_checklists`.

### 2. Migrate and restart

This plugin adds table `issue_checklists`:

```bash
cd /path/to/redmine
RAILS_ENV=production bundle exec rake redmine:plugins:migrate NAME=redmine_issue_checklists
# then restart Redmine (systemd, Puma, or docker compose restart)
```

Docker:

```bash
docker exec -e RAILS_ENV=production YOUR_REDMINE_CONTAINER \
  bundle exec rake redmine:plugins:migrate NAME=redmine_issue_checklists
docker restart YOUR_REDMINE_CONTAINER
```

No extra gems.

### 3. Grant permission

**Administration → Roles and permissions** — enable **Manage issue checklists** on roles that should add/toggle/delete items.

Open any issue. The checklist box is below the description.

## Uninstall

```bash
cd /path/to/redmine
RAILS_ENV=production bundle exec rake redmine:plugins:migrate NAME=redmine_issue_checklists VERSION=0
```

Remove `plugins/redmine_issue_checklists` and restart Redmine. Rolling back the migration **deletes all checklist rows**.

## Tests

On a Redmine checkout that already has this plugin in `plugins/`:

```bash
bundle exec rake redmine:plugins:test NAME=redmine_issue_checklists RAILS_ENV=test
```

This GitHub repository’s CI does **not** run that rake task (no Redmine app in the workflow). CI is Ruby 3.2 syntax + ERB compile.

## Community support

Async only, via [GitHub issues](https://github.com/redmineshop/redmine_issue_checklists/issues). No 24/7 SLA.

## License

MIT — see `LICENSE`. Community / free edition; no paid SKU in this repository.
