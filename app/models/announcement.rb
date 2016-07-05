# frozen_string_literal: true
class Announcement < ActiveRecord::Base
  has_many :dismissals, dependent: :destroy

  scope :current, -> do
    where('starts_at <= :now AND ends_at >= :now', now: Time.zone.now)
  end

  def self.pending_for(user)
    join = joins <<-SQL.squish
      LEFT OUTER JOIN dismissals
      ON dismissals.announcement_id = announcements.id
    SQL

    join.where('user_id IS NULL or user_id <> ?', user.id)
  end
end
