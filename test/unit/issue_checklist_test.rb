# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class IssueChecklistTest < ActiveSupport::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles, :issues,
           :trackers, :projects_trackers, :issue_statuses, :enumerations,
           :enabled_modules

  def setup
    @issue = Issue.find(1)
    @issue.issue_checklists.delete_all
  end

  def test_requires_subject
    item = @issue.issue_checklists.build(subject: '  ')
    assert_not item.valid?
    assert item.errors[:subject].present?
  end

  def test_strips_subject_and_assigns_position
    first = @issue.issue_checklists.create!(subject: '  Ship docs  ')
    second = @issue.issue_checklists.create!(subject: 'Ship package')

    assert_equal 'Ship docs', first.subject
    assert_equal 1, first.position
    assert_equal 2, second.position
  end

  def test_progress_for_counts_done
    @issue.issue_checklists.create!(subject: 'A', is_done: true)
    @issue.issue_checklists.create!(subject: 'B', is_done: false)
    @issue.issue_checklists.reload

    assert_equal [1, 2], IssueChecklist.progress_for(@issue)
  end

  def test_rejects_more_than_max_items
    IssueChecklist::MAX_ITEMS_PER_ISSUE.times do |i|
      @issue.issue_checklists.create!(subject: "Item #{i}")
    end

    extra = @issue.issue_checklists.build(subject: 'overflow')
    assert_not extra.valid?
    assert extra.errors[:base].present?
  end

  def test_issue_association_destroys_items
    assoc = Issue.reflect_on_association(:issue_checklists)
    assert assoc
    assert_equal :destroy, assoc.options[:dependent]
  end

  def test_sorted_scope_orders_by_position
    later = @issue.issue_checklists.create!(subject: 'Later', position: 3)
    earlier = @issue.issue_checklists.create!(subject: 'Earlier', position: 1)

    assert_equal [earlier.id, later.id], @issue.issue_checklists.sorted.pluck(:id)
  end
end
