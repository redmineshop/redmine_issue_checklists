# frozen_string_literal: true

module RedmineIssueChecklists
  module IssuePatch
    def self.included(base)
      base.class_eval do
        has_many :issue_checklists,
                 class_name: 'IssueChecklist',
                 dependent: :destroy,
                 inverse_of: :issue

        after_create :copy_checklists_from_source
      end
    end

    private

    # Issue#copy_from records the source, including when the caller passes an
    # Issue object and skips Issue.visible. Copy rows only when this user can
    # see that source and may manage checklists on the destination project.
    def copy_checklists_from_source
      return unless copy?

      source = @copied_from
      return if source.blank?
      return unless source.visible?(User.current)
      return unless User.current.allowed_to?(:manage_issue_checklists, project)

      source.issue_checklists.sorted.limit(IssueChecklist::MAX_ITEMS_PER_ISSUE).each do |item|
        copy = issue_checklists.build(
          subject: item.subject,
          is_done: item.is_done,
          position: item.position
        )
        next if copy.save

        next unless logger

        logger.info(
          "Checklist item #{item.id} was not copied onto issue #{id}: " \
          "#{copy.errors.full_messages.join(', ')}"
        )
      end
    end
  end
end
