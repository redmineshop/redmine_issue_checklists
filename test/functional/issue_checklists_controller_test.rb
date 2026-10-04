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

  def test_toggle_ignores_subject_and_issue_id
    item = @issue.issue_checklists.create!(subject: 'Toggle me', is_done: false)
    @request.session[:user_id] = 2
    post :toggle, params: {
      id: item.id,
      issue_checklist: { subject: 'hacked', is_done: '0', issue_id: Issue.find(2).id }
    }
    item.reload
    assert item.is_done?
    assert_equal 'Toggle me', item.subject
    assert_equal @issue.id, item.issue_id
  end

  def test_toggle_twice_clears_is_done
    item = @issue.issue_checklists.create!(subject: 'Toggle me', is_done: false)
    @request.session[:user_id] = 2
    post :toggle, params: { id: item.id }
    post :toggle, params: { id: item.id }
    assert_not item.reload.is_done?
  end

  def test_destroy_forbidden_without_permission
    item = @issue.issue_checklists.create!(subject: 'Keep')
    @request.session[:user_id] = 3
    assert_no_difference 'IssueChecklist.count' do
      delete :destroy, params: { id: item.id }
    end
    assert_response :forbidden
    assert IssueChecklist.exists?(item.id)
  end

  def test_destroy_and_toggle_require_login
    item = @issue.issue_checklists.create!(subject: 'Anon')
    @request.session[:user_id] = nil
    post :toggle, params: { id: item.id }
    assert_response :redirect
    delete :destroy, params: { id: item.id }
    assert_response :redirect
    assert_not item.reload.is_done?
    assert IssueChecklist.exists?(item.id)
  end

  def test_create_ignores_is_done_position_and_issue_id
    other = Issue.find(2)
    @request.session[:user_id] = 2
    post :create, params: {
      issue_id: @issue.id,
      issue_checklist: {
        subject: 'Stay here',
        is_done: '1',
        position: '9',
        issue_id: other.id
      }
    }
    item = @issue.issue_checklists.order(:id).last
    assert_equal 'Stay here', item.subject
    assert_not item.is_done?
    assert_equal 1, item.position
    assert_equal @issue.id, item.issue_id
    assert_not other.issue_checklists.exists?
  end

  def test_create_stores_sql_metacharacters_as_text
    payload = "'); DROP TABLE issue_checklists;--"
    @request.session[:user_id] = 2
    assert_difference 'IssueChecklist.count', 1 do
      post :create, params: { issue_id: @issue.id, issue_checklist: { subject: payload } }
    end
    assert IssueChecklist.table_exists?
    assert_equal payload, @issue.issue_checklists.order(:id).last.subject
  end

  def test_create_rejects_blank_and_overlong_subjects
    @request.session[:user_id] = 2
    assert_no_difference 'IssueChecklist.count' do
      post :create, params: { issue_id: @issue.id, issue_checklist: { subject: '   ' } }
    end
    assert_redirected_to issue_path(@issue)
    assert flash[:error].present?

    assert_no_difference 'IssueChecklist.count' do
      post :create, params: { issue_id: @issue.id, issue_checklist: { subject: 'a' * 256 } }
    end
    assert_redirected_to issue_path(@issue)
  end

  def test_create_rejects_missing_or_non_hash_params
    @request.session[:user_id] = 2
    assert_no_difference 'IssueChecklist.count' do
      post :create, params: { issue_id: @issue.id }
    end
    assert_redirected_to issue_path(@issue)

    assert_no_difference 'IssueChecklist.count' do
      post :create, params: { issue_id: @issue.id, issue_checklist: '<script>alert(1)</script>' }
    end
    assert_redirected_to issue_path(@issue)
    assert_no_match(/<script>/, flash[:error].to_s)
  end

  def test_create_error_flash_escapes_html
    raw = '<img src=x onerror=alert(1)>'
    I18n.backend.store_translations(
      :en,
      activerecord: {
        errors: {
          models: {
            issue_checklist: {
              attributes: { subject: { blank: raw } }
            }
          }
        }
      }
    )
    @request.session[:user_id] = 2
    post :create, params: { issue_id: @issue.id, issue_checklist: { subject: '   ' } }

    assert_response :redirect
    assert_includes flash[:error], '&lt;img src=x onerror=alert(1)&gt;'
    assert_not_includes flash[:error].to_s, '<img'
  ensure
    I18n.backend.store_translations(
      :en,
      activerecord: {
        errors: {
          models: {
            issue_checklist: {
              attributes: { subject: { blank: 'cannot be blank' } }
            }
          }
        }
      }
    )
  end

  def test_create_rejects_the_51st_item
    IssueChecklist::MAX_ITEMS_PER_ISSUE.times do |i|
      @issue.issue_checklists.create!(subject: "Item #{i}")
    end
    @request.session[:user_id] = 2
    assert_no_difference 'IssueChecklist.count' do
      post :create, params: { issue_id: @issue.id, issue_checklist: { subject: 'overflow' } }
    end
    assert_redirected_to issue_path(@issue)
    assert_match(/50/, flash[:error])
  end

  def test_create_missing_issue_is_not_found
    @request.session[:user_id] = 2
    assert_no_difference 'IssueChecklist.count' do
      post :create, params: { issue_id: 999_999, issue_checklist: { subject: 'Missing' } }
    end
    assert_response :not_found
  end

  def test_toggle_missing_item_is_not_found
    @request.session[:user_id] = 2
    post :toggle, params: { id: 999_999 }
    assert_response :not_found
  end

  def test_create_forbidden_for_non_member
    @request.session[:user_id] = 7
    assert_no_difference 'IssueChecklist.count' do
      post :create, params: { issue_id: @issue.id, issue_checklist: { subject: 'Outsider' } }
    end
    assert_response :forbidden
  end

  def test_create_forbidden_for_non_member_of_private_project
    @request.session[:user_id] = 7
    assert_no_difference 'IssueChecklist.count' do
      post :create, params: { issue_id: 4, issue_checklist: { subject: 'Outsider' } }
    end
    assert_response :forbidden
  end

  def test_toggle_forbidden_for_member_without_permission_on_that_project
    item = Issue.find(4).issue_checklists.create!(subject: 'Project 2 item')
    @request.session[:user_id] = 2
    post :toggle, params: { id: item.id }
    assert_response :forbidden
    assert_not item.reload.is_done?
  end

  def test_mutations_forbidden_on_a_private_issue_the_user_cannot_see
    Role.find(2).add_permission!(:manage_issue_checklists)
    private_issue = Issue.generate!(project_id: 1, author_id: 2, is_private: true, subject: 'Private host')
    item = private_issue.issue_checklists.create!(subject: 'Secret')
    @request.session[:user_id] = 3

    assert_no_difference 'IssueChecklist.count' do
      post :create, params: { issue_id: private_issue.id, issue_checklist: { subject: 'Extra' } }
    end
    assert_response :forbidden

    post :toggle, params: { id: item.id }
    assert_response :forbidden
    post :reorder, params: { id: item.id, direction: 'up' }
    assert_response :forbidden
    assert_no_difference 'IssueChecklist.count' do
      delete :destroy, params: { id: item.id }
    end
    assert_response :forbidden
    assert_not item.reload.is_done?
    assert_equal 'Secret', item.subject
  end

  def test_create_forbidden_when_issue_tracking_module_is_disabled
    EnabledModule.where(project_id: @issue.project_id, name: 'issue_tracking').delete_all
    @issue.project.reload
    @request.session[:user_id] = 2
    assert_no_difference 'IssueChecklist.count' do
      post :create, params: { issue_id: @issue.id, issue_checklist: { subject: 'Nope' } }
    end
    assert_response :forbidden
  end

  def test_admin_can_create_without_a_role_permission
    Role.all.each { |role| role.remove_permission!(:manage_issue_checklists) }
    @request.session[:user_id] = 1
    assert_difference 'IssueChecklist.count', 1 do
      post :create, params: { issue_id: @issue.id, issue_checklist: { subject: 'Admin item' } }
    end
    assert_redirected_to issue_path(@issue)
  end

  def test_create_rejects_a_missing_csrf_token
    ActionController::Base.allow_forgery_protection = true
    @request.session[:user_id] = 2
    assert_no_difference 'IssueChecklist.count' do
      post :create, params: { issue_id: @issue.id, issue_checklist: { subject: 'csrf' } }
    end
    assert_response 422
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  def test_destroy_rejects_a_missing_csrf_token
    item = @issue.issue_checklists.create!(subject: 'csrf')
    ActionController::Base.allow_forgery_protection = true
    @request.session[:user_id] = 2
    assert_no_difference 'IssueChecklist.count' do
      delete :destroy, params: { id: item.id }
    end
    assert_response 422
    assert IssueChecklist.exists?(item.id)
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  def test_reorder_moves_item_up_and_down
    first = @issue.issue_checklists.create!(subject: 'First')
    second = @issue.issue_checklists.create!(subject: 'Second')
    @request.session[:user_id] = 2

    post :reorder, params: { id: second.id, direction: 'up' }
    assert_redirected_to issue_path(@issue)
    assert_equal [second.id, first.id], @issue.issue_checklists.sorted.pluck(:id)

    post :reorder, params: { id: second.id, direction: 'down' }
    assert_equal [first.id, second.id], @issue.issue_checklists.sorted.pluck(:id)
  end

  def test_reorder_at_the_end_does_not_change_order
    first = @issue.issue_checklists.create!(subject: 'First')
    second = @issue.issue_checklists.create!(subject: 'Second')
    @request.session[:user_id] = 2
    post :reorder, params: { id: first.id, direction: 'up' }
    assert_equal [first.id, second.id], @issue.issue_checklists.sorted.pluck(:id)
    assert_nil flash[:error]
  end

  def test_reorder_rejects_unknown_direction
    item = @issue.issue_checklists.create!(subject: 'Only')
    @request.session[:user_id] = 2
    post :reorder, params: { id: item.id, direction: "up'); DROP TABLE issue_checklists;--", position: '4' }
    assert_redirected_to issue_path(@issue)
    assert_includes flash[:error], 'could not be moved'
    assert IssueChecklist.table_exists?
    assert_equal 1, item.reload.position
    assert_equal @issue.id, item.issue_id
  end

  def test_reorder_forbidden_without_permission
    first = @issue.issue_checklists.create!(subject: 'First')
    second = @issue.issue_checklists.create!(subject: 'Second')
    @request.session[:user_id] = 3
    post :reorder, params: { id: second.id, direction: 'up' }
    assert_response :forbidden
    assert_equal [first.id, second.id], @issue.issue_checklists.sorted.pluck(:id)
  end

  def test_json_format_does_not_create_or_render_an_item
    @request.session[:user_id] = 2
    assert_no_difference 'IssueChecklist.count' do
      post :create, params: {
        issue_id: @issue.id,
        issue_checklist: { subject: 'JSON' },
        format: :json
      }
    end
    assert_response :forbidden
    assert_not_includes response.body, 'JSON'
  end

  def test_mutating_actions_are_not_routable_with_get
    assert_routing(
      { method: :post, path: '/issues/1/checklists' },
      { controller: 'issue_checklists', action: 'create', issue_id: '1' }
    )
    assert_routing(
      { method: :post, path: '/issue_checklists/1/toggle' },
      { controller: 'issue_checklists', action: 'toggle', id: '1' }
    )
    assert_routing(
      { method: :post, path: '/issue_checklists/1/reorder' },
      { controller: 'issue_checklists', action: 'reorder', id: '1' }
    )
    assert_routing(
      { method: :delete, path: '/issue_checklists/1' },
      { controller: 'issue_checklists', action: 'destroy', id: '1' }
    )
    ['/issues/1/checklists', '/issue_checklists/1/toggle', '/issue_checklists/1/reorder', '/issue_checklists/1'].each do |path|
      assert_raises(ActionController::RoutingError) do
        Rails.application.routes.recognize_path(path, method: :get)
      end
    end
  end
end
