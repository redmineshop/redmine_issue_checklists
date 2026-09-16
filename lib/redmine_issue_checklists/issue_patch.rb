# frozen_string_literal: true

module RedmineIssueChecklists
  module IssuePatch
    def self.included(base)
      base.class_eval do
        has_many :issue_checklists,
                 class_name: 'IssueChecklist',
                 dependent: :destroy,
                 inverse_of: :issue
      end
    end
  end
end
