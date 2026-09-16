# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class IssueChecklistsIssuesControllerTest < Redmine::ControllerTest
  tests IssuesController

  fixtures :projects, :users, :roles, :members, :member_roles, :issues,
           :trackers, :projects_trackers, :issue_statuses, :enumerations,
           :enabled_modules, :journals, :journal_details, :issue_categories,
           :versions, :queries, :attachments, :custom_fields,
           :custom_values, :custom_fields_projects, :custom_fields_trackers,
           :time_entries, :watchers

  def setup
    @issue = Issue.find(1)
    Role.find(1).add_permission!(:manage_issue_checklists)
  end

  def test_show_includes_checklist_box
    @issue.issue_checklists.delete_all
    @issue.issue_checklists.create!(subject: 'Visible item')
    @request.session[:user_id] = 2

    get :show, params: { id: @issue.id }
    assert_response :success
    assert_select '#issue-checklists'
    assert_select '#issue-checklists .issue-checklists-item', text: /Visible item/
    assert_select '#issue-checklist-subject'
  end

  def test_show_hides_manage_controls_without_permission
    @issue.issue_checklists.delete_all
    @issue.issue_checklists.create!(subject: 'Read only item')
    @request.session[:user_id] = 3

    get :show, params: { id: @issue.id }
    assert_response :success
    assert_select '#issue-checklists'
    assert_select '#issue-checklist-subject', count: 0
    assert_select 'input.issue-checklist-toggle', count: 0
  end
end
