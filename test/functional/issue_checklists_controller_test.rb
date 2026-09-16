# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class IssueChecklistsControllerTest < Redmine::ControllerTest
  fixtures :projects, :users, :roles, :members, :member_roles, :issues,
           :trackers, :projects_trackers, :issue_statuses, :enumerations,
           :enabled_modules

  def setup
    @issue = Issue.find(1)
    @issue.issue_checklists.delete_all
    Role.find(1).add_permission!(:manage_issue_checklists)
    Role.find(2).remove_permission!(:manage_issue_checklists) if Role.find(2).has_permission?(:manage_issue_checklists)
  end

  def test_create_success_for_member_with_permission
    @request.session[:user_id] = 2
    assert_difference 'IssueChecklist.count', 1 do
      post :create, params: { issue_id: @issue.id, issue_checklist: { subject: 'Write README' } }
    end
    assert_redirected_to issue_path(@issue)
    item = @issue.issue_checklists.order(:id).last
    assert_equal 'Write README', item.subject
    assert_not item.is_done?
  end

  def test_create_forbidden_without_permission
    @request.session[:user_id] = 3
    assert_no_difference 'IssueChecklist.count' do
      post :create, params: { issue_id: @issue.id, issue_checklist: { subject: 'Nope' } }
    end
    assert_response :forbidden
  end

  def test_create_requires_login
    @request.session[:user_id] = nil
    post :create, params: { issue_id: @issue.id, issue_checklist: { subject: 'Anon' } }
    assert_response :redirect
  end

  def test_toggle_flips_is_done
    item = @issue.issue_checklists.create!(subject: 'Toggle me', is_done: false)
    @request.session[:user_id] = 2
    post :toggle, params: { id: item.id }
    assert_redirected_to issue_path(@issue)
    assert item.reload.is_done?
  end

  def test_destroy_removes_item
    item = @issue.issue_checklists.create!(subject: 'Remove me')
    @request.session[:user_id] = 2
    assert_difference 'IssueChecklist.count', -1 do
      delete :destroy, params: { id: item.id }
    end
    assert_redirected_to issue_path(@issue)
  end

  def test_toggle_forbidden_without_permission
    item = @issue.issue_checklists.create!(subject: 'Locked')
    @request.session[:user_id] = 3
    post :toggle, params: { id: item.id }
    assert_response :forbidden
    assert_not item.reload.is_done?
  end
end
