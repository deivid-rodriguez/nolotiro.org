# frozen_string_literal: true

class CommentPolicy < ApplicationPolicy
  def create?
    record.ad.comments_enabled? &&
      !record.ad.delivered? &&
      user &&
      Blocking.none_between?(record.ad.user, user)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      not_spam = scope.from_legitimate_authors
      return not_spam unless user

      not_spam.from_authors_whitelisting(user)
    end
  end
end
