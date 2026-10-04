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
    assert_select 'input[name=direction]', count: 0
    assert_select '.issue-checklists-delete', count: 0
  end

  def test_show_escapes_checklist_subject
    payload = '"><img src=x onerror=alert(1)>'
    @issue.issue_checklists.delete_all
    @issue.issue_checklists.create!(subject: payload)
    @request.session[:user_id] = 2

    get :show, params: { id: @issue.id }
    assert_response :success
    assert_includes response.body, '&quot;&gt;&lt;img src=x onerror=alert(1)&gt;'
    assert_not_includes response.body, payload
    assert_not_includes response.body, '<img'
  end

  def test_show_renders_progress_and_move_controls
    @issue.issue_checklists.delete_all
    @issue.issue_checklists.create!(subject: 'First', is_done: true)
    @issue.issue_checklists.create!(subject: 'Second', is_done: false)
    @request.session[:user_id] = 2

    get :show, params: { id: @issue.id }
    assert_response :success
    assert_select '.issue-checklists-progress', text: '1 of 2 done'
    assert_select 'progress.issue-checklists-meter[value="1"][max="2"]'
    assert_select 'li.issue-checklists-item:first-child input[name=direction][value=up]', count: 0
    assert_select 'li.issue-checklists-item:first-child input[name=direction][value=down]', count: 1
    assert_select 'li.issue-checklists-item:last-child input[name=direction][value=up]', count: 1
    assert_select 'li.issue-checklists-item:last-child input[name=direction][value=down]', count: 0
  end

  def test_show_includes_csrf_tokens_when_forgery_protection_is_enabled
    ActionController::Base.allow_forgery_protection = true
    @issue.issue_checklists.delete_all
    @issue.issue_checklists.create!(subject: 'First')
    @issue.issue_checklists.create!(subject: 'Second')
    @request.session[:user_id] = 2

    get :show, params: { id: @issue.id }
    assert_response :success
    assert_select '#issue-checklists input[name=authenticity_token]'
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  def test_show_empty_checklist_still_offers_the_add_form
    @issue.issue_checklists.delete_all
    @request.session[:user_id] = 2

    get :show, params: { id: @issue.id }
    assert_response :success
    assert_select '#issue-checklists .nodata'
    assert_select '#issue-checklist-subject'
  end

  def test_show_is_read_only_for_anonymous_on_a_public_issue
    @issue.issue_checklists.delete_all
    @issue.issue_checklists.create!(subject: 'Visible item')
    @request.session[:user_id] = nil

    get :show, params: { id: @issue.id }
    assert_response :success
    assert_select '#issue-checklists', text: /Visible item/
    assert_select '#issue-checklist-subject', count: 0
    assert_select 'input[name=direction]', count: 0
    assert_select '.issue-checklists-delete', count: 0
  end

  def test_show_is_read_only_for_a_non_member_on_a_public_issue
    @issue.issue_checklists.delete_all
    @issue.issue_checklists.create!(subject: 'Visible item')
    @request.session[:user_id] = 7

    get :show, params: { id: @issue.id }
    assert_response :success
    assert_select '#issue-checklists', text: /Visible item/
    assert_select '#issue-checklist-subject', count: 0
  end

  def test_show_forbidden_for_non_member_on_private_project
    Issue.find(4).issue_checklists.create!(subject: 'Secret project item')
    @request.session[:user_id] = 7

    get :show, params: { id: 4 }
    assert_response :forbidden
    assert_select '#issue-checklists', count: 0
  end

  def test_show_private_issue_is_read_only_for_its_author_without_manage_permission
    private_issue = Issue.generate!(project_id: 1, author_id: 3, is_private: true, subject: 'Mine')
    private_issue.issue_checklists.create!(subject: 'Author only')
    @request.session[:user_id] = 3

    get :show, params: { id: private_issue.id }
    assert_response :success
    assert_select '#issue-checklists', text: /Author only/
    assert_select '#issue-checklist-subject', count: 0
    assert_select 'input.issue-checklist-toggle', count: 0
  end

  def test_show_private_issue_forbidden_for_another_member
    private_issue = Issue.generate!(project_id: 1, author_id: 2, is_private: true, subject: 'Not yours')
    private_issue.issue_checklists.create!(subject: 'Secret step')
    @request.session[:user_id] = 3

    get :show, params: { id: private_issue.id }
    assert_response :forbidden
    assert_select '#issue-checklists', count: 0
  end

  def test_show_on_another_project_hides_manage_controls_without_permission
    issue = Issue.find(4)
    issue.issue_checklists.delete_all
    issue.issue_checklists.create!(subject: 'Project two item')
    @request.session[:user_id] = 2

    get :show, params: { id: issue.id }
    assert_response :success
    assert_select '#issue-checklists', text: /Project two item/
    assert_select '#issue-checklist-subject', count: 0
    assert_select 'input.issue-checklist-toggle', count: 0
  end

  def test_update_ignores_nested_checklist_attributes
    @request.session[:user_id] = 2
    assert_no_difference 'IssueChecklist.count' do
      put :update, params: {
        id: @issue.id,
        issue: {
          issue_checklists_attributes: {
            '0' => { subject: 'injected', is_done: '1' }
          }
        }
      }
    end
    assert_nil @issue.issue_checklists.find_by(subject: 'injected')
  end

  def test_create_as_copy_copies_checklist_items
    @issue.issue_checklists.delete_all
    @issue.issue_checklists.create!(subject: 'Copied step', is_done: true, position: 1)
    @request.session[:user_id] = 2

    assert_difference 'Issue.count', 1 do
      post :create, params: {
        project_id: 1,
        copy_from: @issue.id,
        issue: {
          project_id: '1',
          tracker_id: '1',
          status_id: '1',
          subject: 'Copy with checklist'
        }
      }
    end
    assert_response :redirect
    copy = Issue.order(:id).last
    item = copy.issue_checklists.sorted.first
    assert_equal 'Copied step', item.subject
    assert item.is_done?
    assert_equal 1, item.position
  end

  def test_create_as_copy_skips_items_without_manage_permission_on_the_destination
    Role.find(2).remove_permission!(:manage_issue_checklists)
    @issue.issue_checklists.delete_all
    @issue.issue_checklists.create!(subject: 'Do not carry')
    @request.session[:user_id] = 2

    assert_difference 'Issue.count', 1 do
      assert_no_difference 'IssueChecklist.count' do
        post :create, params: {
          project_id: 1,
          copy_from: @issue.id,
          issue: {
            project_id: '2',
            tracker_id: '3',
            status_id: '1',
            subject: 'Copy elsewhere'
          }
        }
      end
    end
    copy = Issue.order(:id).last
    assert_equal 2, copy.project_id
    assert_empty copy.issue_checklists
  end

  def test_create_as_copy_of_an_invisible_issue_does_not_copy_items
    private_issue = Issue.generate!(project_id: 1, author_id: 2, is_private: true, subject: 'Hidden')
    private_issue.issue_checklists.create!(subject: 'Hidden step')
    @request.session[:user_id] = 3

    assert_no_difference 'IssueChecklist.count' do
      post :create, params: {
        project_id: 1,
        copy_from: private_issue.id,
        issue: {
          project_id: '1',
          tracker_id: '1',
          status_id: '1',
          subject: 'Stolen'
        }
      }
    end
    assert_response :not_found
    assert_not Issue.exists?(subject: 'Stolen')
  end
end
