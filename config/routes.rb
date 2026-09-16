# frozen_string_literal: true

post 'issues/:issue_id/checklists',
     to: 'issue_checklists#create',
     as: :issue_checklists

post 'issue_checklists/:id/toggle',
     to: 'issue_checklists#toggle',
     as: :toggle_issue_checklist

delete 'issue_checklists/:id',
       to: 'issue_checklists#destroy',
       as: :issue_checklist
