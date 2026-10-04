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

  def test_sorted_scope_breaks_ties_by_id
    first = @issue.issue_checklists.create!(subject: 'First', position: 1)
    second = @issue.issue_checklists.create!(subject: 'Second', position: 1)

    assert_equal [first.id, second.id], @issue.issue_checklists.sorted.pluck(:id)
  end

  def test_position_must_stay_a_positive_integer
    item = @issue.issue_checklists.create!(subject: 'Placed')
    item.position = 0
    assert_not item.valid?
    item.position = -3
    assert_not item.valid?
    item.position = 1.5
    assert_not item.valid?
  end

  def test_subject_length_limit
    assert_not @issue.issue_checklists.build(subject: 'a' * 256).valid?
    assert @issue.issue_checklists.build(subject: 'a' * 255).valid?
  end

  def test_stores_sql_metacharacters_as_text
    payload = "'); DROP TABLE issue_checklists;--"
    item = @issue.issue_checklists.create!(subject: payload)

    assert IssueChecklist.table_exists?
    assert_equal payload, item.reload.subject
    assert_equal 1, IssueChecklist.where(subject: payload).count
  end

  def test_reorder_swaps_neighbors_and_stops_at_the_ends
    first = @issue.issue_checklists.create!(subject: 'First')
    second = @issue.issue_checklists.create!(subject: 'Second')
    third = @issue.issue_checklists.create!(subject: 'Third')

    assert third.reorder!('up')
    assert_equal [first.id, third.id, second.id], @issue.issue_checklists.sorted.pluck(:id)

    assert first.reload.reorder!('up')
    assert_equal [first.id, third.id, second.id], @issue.issue_checklists.sorted.reload.pluck(:id)

    assert second.reload.reorder!('down')
    assert_equal [first.id, third.id, second.id], @issue.issue_checklists.sorted.pluck(:id)
  end

  def test_reorder_normalizes_duplicate_positions
    first = @issue.issue_checklists.create!(subject: 'First', position: 1)
    second = @issue.issue_checklists.create!(subject: 'Second', position: 1)

    assert second.reorder!('up')
    assert_equal [second.id, first.id], @issue.issue_checklists.sorted.pluck(:id)
    assert_equal [1, 2], @issue.issue_checklists.sorted.pluck(:position)
  end

  def test_reorder_rejects_unexpected_direction_without_writing
    item = @issue.issue_checklists.create!(subject: 'Only')
    other = Issue.find(2)
    other.issue_checklists.delete_all
    foreign = other.issue_checklists.create!(subject: 'Foreign')

    assert_not item.reorder!("up'); DROP TABLE issue_checklists;--")
    assert_not item.reorder!(nil)
    assert IssueChecklist.table_exists?
    assert_equal 1, item.reload.position
    assert_equal other.id, foreign.reload.issue_id
  end

  def test_reorder_does_not_take_items_from_another_issue
    mine = @issue.issue_checklists.create!(subject: 'Mine')
    other = Issue.find(2)
    other.issue_checklists.delete_all
    theirs = other.issue_checklists.create!(subject: 'Theirs')

    assert mine.reorder!('down')
    assert_equal [@issue.id, 'Mine'], [mine.reload.issue_id, mine.subject]
    assert_equal [other.id, 'Theirs'], [theirs.reload.issue_id, theirs.subject]
  end

  def test_destroying_issue_removes_checklist_rows
    issue = Issue.generate!(subject: 'Disposable')
    item = issue.issue_checklists.create!(subject: 'Gone')

    issue.destroy!

    assert_nil IssueChecklist.find_by(id: item.id)
  end
end
