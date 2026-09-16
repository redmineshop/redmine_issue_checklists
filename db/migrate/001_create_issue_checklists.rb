# frozen_string_literal: true

class CreateIssueChecklists < ActiveRecord::Migration[6.1]
  def up
    create_table :issue_checklists do |t|
      t.integer :issue_id, null: false
      t.string :subject, null: false, limit: 255
      t.boolean :is_done, null: false, default: false
      t.integer :position, null: false
      t.timestamps
    end
    add_index :issue_checklists, %i[issue_id position]
    add_index :issue_checklists, :issue_id
  end

  def down
    drop_table :issue_checklists
  end
end
