# frozen_string_literal: true

require File.expand_path('../../../test/test_helper', __dir__)

unless Issue.included_modules.include?(RedmineIssueChecklists::IssuePatch)
  Issue.include RedmineIssueChecklists::IssuePatch
end
