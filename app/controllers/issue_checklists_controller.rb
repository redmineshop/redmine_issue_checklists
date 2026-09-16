# frozen_string_literal: true

class IssueChecklistsController < ApplicationController
  before_action :require_login
  before_action :find_issue, only: [:create]
  before_action :find_checklist, only: %i[destroy toggle]
  before_action :authorize

  def create
    item = @issue.issue_checklists.build(checklist_params)
    if item.save
      flash[:notice] = l(:notice_issue_checklist_created)
    else
      flash[:error] = item.errors.full_messages.to_sentence
    end
    redirect_to issue_path(@issue)
  end

  def toggle
    @checklist.update(is_done: !@checklist.is_done?)
    redirect_to issue_path(@issue)
  end

  def destroy
    @checklist.destroy
    flash[:notice] = l(:notice_issue_checklist_deleted)
    redirect_to issue_path(@issue)
  end

  private

  def find_issue
    @issue = Issue.find(params[:issue_id])
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_checklist
    @checklist = IssueChecklist.find(params[:id])
    @issue = @checklist.issue
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def checklist_params
    params.require(:issue_checklist).permit(:subject)
  end
end
