# frozen_string_literal: true

require 'cgi'

class IssueChecklistsController < ApplicationController
  before_action :require_login
  before_action :find_issue, only: [:create]
  before_action :find_checklist, only: %i[destroy toggle reorder]
  before_action :authorize

  def create
    item = @issue.issue_checklists.build(checklist_params)
    if item.save
      safe_flash(:notice, l(:notice_issue_checklist_created))
    else
      safe_flash(:error, item.errors.full_messages.to_sentence)
    end
    redirect_to issue_path(@issue)
  end

  def toggle
    @checklist.update(is_done: !@checklist.is_done?)
    redirect_to issue_path(@issue)
  end

  def destroy
    @checklist.destroy
    safe_flash(:notice, l(:notice_issue_checklist_deleted))
    redirect_to issue_path(@issue)
  end

  def reorder
    unless @checklist.reorder!(params[:direction])
      safe_flash(:error, l(:error_issue_checklist_reorder))
    end
    redirect_to issue_path(@issue)
  end

  private

  # Match IssuesController#find_issue: 404 when the row is missing, 403 when
  # the user is not allowed to see that issue. authorize only checks the
  # project permission and would otherwise allow edits on a private issue.
  def find_issue
    @issue = Issue.find(params[:issue_id])
    raise Unauthorized unless @issue.visible?

    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_checklist
    @checklist = IssueChecklist.find(params[:id])
    @issue = @checklist.issue
    if @issue.nil?
      render_404
      return
    end
    raise Unauthorized unless @issue.visible?

    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Only the item text is assignable. is_done, position, and issue_id stay
  # under server control (toggle, reorder, and the nested association).
  def checklist_params
    raw = params[:issue_checklist]
    return ActionController::Parameters.new.permit(:subject) unless raw.is_a?(ActionController::Parameters)

    raw.permit(:subject)
  end

  # render_flash_messages marks flash strings html_safe, so user-influenced
  # validation text has to be escaped before it is stored.
  def safe_flash(key, message)
    flash[key] = CGI.escapeHTML(message.to_s)
  end
end
