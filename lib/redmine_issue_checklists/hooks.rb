# frozen_string_literal: true

module RedmineIssueChecklists
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_issues_show_description_bottom,
              partial: 'issue_checklists/issue_box'
    render_on :view_layouts_base_html_head,
              partial: 'issue_checklists/html_head'
  end
end
