# frozen_string_literal: true

class IssueChecklist < ActiveRecord::Base
  MAX_ITEMS_PER_ISSUE = 50

  belongs_to :issue

  validates :issue, presence: true
  validates :subject, presence: true, length: { maximum: 255 }
  validates :position, numericality: { only_integer: true, greater_than: 0 }
  validate :within_item_limit, on: :create

  scope :sorted, -> { order(:position, :id) }
  scope :done, -> { where(is_done: true) }

  before_validation :normalize_subject
  before_validation :assign_position, on: :create

  def self.progress_for(issue)
    items = issue.issue_checklists.to_a
    total = items.size
    done = items.count(&:is_done?)
    [done, total]
  end

  private

  def normalize_subject
    self.subject = subject.to_s.strip
  end

  def assign_position
    return if issue.nil?
    return if position.present? && position.to_i.positive?

    self.position = issue.issue_checklists.maximum(:position).to_i + 1
  end

  def within_item_limit
    return if issue.nil?
    return if issue.issue_checklists.count < MAX_ITEMS_PER_ISSUE

    errors.add(:base, :too_many_items)
  end
end
