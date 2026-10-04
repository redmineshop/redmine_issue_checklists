# frozen_string_literal: true

class IssueChecklist < ActiveRecord::Base
  MAX_ITEMS_PER_ISSUE = 50
  DIRECTIONS = %w[up down].freeze

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

  # Swap this row with its neighbor in the same issue. direction must be
  # "up" or "down". Returns false for anything else and does not write.
  # A move past either end is a no-op and returns true.
  def reorder!(direction)
    direction = direction.to_s
    return false unless DIRECTIONS.include?(direction)

    self.class.transaction do
      siblings = self.class.where(issue_id: issue_id).order(:position, :id).to_a
      index = siblings.index { |row| row.id == id }
      offset = direction == 'up' ? -1 : 1
      neighbor_index = index.nil? ? nil : index + offset
      in_range = !neighbor_index.nil? && neighbor_index >= 0 && neighbor_index < siblings.size
      if in_range
        siblings.each_with_index do |row, i|
          row.update_columns(position: i + 1) if row.position != i + 1
        end
        siblings[index].update_columns(position: neighbor_index + 1)
        siblings[neighbor_index].update_columns(position: index + 1)
      end
    end
    true
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
