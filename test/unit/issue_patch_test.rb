# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class IssueChecklistIssuePatchTest < ActiveSupport::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles, :issues,
           :trackers, :projects_trackers, :issue_statuses, :enumerations,
           :enabled_modules

  def teardown
    User.current = nil
    super
  end

  def test_copy_copies_items_when_the_user_can_see_the_source_and_manage
    Role.find(1).add_permission!(:manage_issue_checklists)
    source = Issue.generate!(subject: 'Source')
    source.issue_checklists.create!(subject: 'Step A', is_done: true, position: 1)
    source.issue_checklists.create!(subject: 'Step B', is_done: false, position: 2)
    User.current = User.find(2)

    copy = source.copy
    copy.save!

    rows = copy.issue_checklists.sorted
    assert_equal ['Step A', 'Step B'], rows.map(&:subject)
    assert_equal [true, false], rows.map(&:is_done)
    assert_equal [1, 2], rows.map(&:position)
    assert_equal copy.id, rows.first.issue_id
  end

  def test_copy_skips_items_without_manage_permission_on_the_destination
    Role.find(1).remove_permission!(:manage_issue_checklists)
    source = Issue.generate!(subject: 'Source')
    source.issue_checklists.create!(subject: 'Step A')
    User.current = User.find(2)

    copy = source.copy
    copy.save!

    assert_empty copy.issue_checklists
  end

  def test_copy_skips_items_when_the_source_issue_is_not_visible
    Role.find(1).add_permission!(:manage_issue_checklists)
    Role.find(2).add_permission!(:manage_issue_checklists)
    private_issue = Issue.generate!(is_private: true, author_id: 2, subject: 'Hidden')
    private_issue.issue_checklists.create!(subject: 'Hidden step', is_done: true)
    User.current = User.find(3)

    copy = Issue.new.copy_from(private_issue)
    copy.save!

    assert_empty copy.issue_checklists
  end

  def test_plain_create_does_not_copy_items
    Role.find(1).add_permission!(:manage_issue_checklists)
    source = Issue.generate!(subject: 'Source')
    source.issue_checklists.create!(subject: 'Step A')
    User.current = User.find(2)

    created = Issue.generate!(subject: 'Fresh', author_id: 2)

    assert_empty created.issue_checklists
  end
end
