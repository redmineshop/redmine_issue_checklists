# frozen_string_literal: true

require 'redmine'

require_relative 'lib/redmine_issue_checklists/version'
require_relative 'lib/redmine_issue_checklists/hooks'
require_relative 'lib/redmine_issue_checklists/issue_patch'

Redmine::Plugin.register :redmine_issue_checklists do
  name 'Redmine Issue Checklists'
  author 'RedmineShop'
  author_url 'https://github.com/redmineshop'
  description 'Interactive checklists on Redmine issues — add items, toggle done, track progress. Community edition, free forever (MIT).'
  version RedmineIssueChecklists::VERSION
  url 'https://github.com/redmineshop/redmine_issue_checklists'

  requires_redmine version_or_higher: '5.0'

  project_module :issue_tracking do
    permission :manage_issue_checklists,
               { issue_checklists: %i[create destroy toggle] }
  end
end

module RedmineIssueChecklists
  def self.patch_issue!
    return if Issue.included_modules.include?(IssuePatch)

    Issue.include IssuePatch
  end
end

RedmineIssueChecklists.patch_issue!

reloader = defined?(ActiveSupport::Reloader) ? ActiveSupport::Reloader : ActionDispatch::Callbacks
reloader.to_prepare do
  RedmineIssueChecklists.patch_issue!
end
