# frozen_string_literal: true

require 'test_helper'

class ConversationTest < ActiveSupport::TestCase
  def setup
    super

    @user, @recipient = create_list(:user, 2)

    @conversation = create(:conversation, originator: @user,
                                          recipient: @recipient)
  end

  def test_unread_by_scope_returns_unread_conversations_only
    assert_equal 0, Conversation.unread_by(@user).size
    assert_equal 1, Conversation.unread_by(@recipient).size
  end

  def test_mark_as_read_does_what_its_name_indicates
    @conversation.mark_as_read(@recipient)

    assert_equal 0, Conversation.unread_by(@user).size
    assert_equal 0, Conversation.unread_by(@recipient).size
  end

  def test_unread_by_scope_excludes_deleted_conversations
    @conversation.move_to_trash(@recipient)

    assert_equal 0, Conversation.unread_by(@user).size
    assert_equal 0, Conversation.unread_by(@recipient).size
  end

  def test_unread_by_scope_excludes_conversations_with_blockers
    create(:blocking, blocker: @user, blocked: @recipient)

    assert_equal 0, Conversation.unread_by(@user).size
  end

  def test_reply_touches_the_conversation_timestamp
    @conversation.update!(updated_at: 1.hour.ago)
    @conversation.reply(sender: @user, recipient: @recipient, body: 'Hey!')

    assert_in_delta @conversation.updated_at, Time.zone.now, 1.second
  end

  def test_involving_lists_conversations_with_users_not_blocking_a_user
    other = create(:user)
    other_conversation = create(:conversation, originator: other,
                                               recipient: @user)

    assert_equal [@conversation, other_conversation],
                 Conversation.involving(@user)

    create(:blocking, blocker: @recipient, blocked: @user)
    assert_equal [other_conversation], Conversation.involving(@user)

    create(:blocking, blocker: other, blocked: @user)
    assert_empty Conversation.involving(@user)
  end

  def test_involving_includes_orphan_conversations
    @recipient.destroy

    assert_equal [@conversation], Conversation.involving(@user)
  end

  def test_involving_excludes_deleted_conversations
    @conversation.move_to_trash(@user)

    assert_empty Conversation.involving(@user)
  end

  def test_involving_includes_started_conversations
    assert_equal [@conversation], Conversation.involving(@user)
  end

  def test_involving_includes_received_conversations
    @conversation.update!(originator: @recipient, recipient: @user)

    assert_equal [@conversation], Conversation.involving(@user)
  end

  def test_involving_excludes_started_conversations_with_blockers
    create(:blocking, blocker: @recipient, blocked: @user)

    assert_empty Conversation.involving(@user)
  end

  def test_involving_includes_started_conversations_with_blocked_users
    create(:blocking, blocker: @user, blocked: @recipient)

    assert_equal [@conversation], Conversation.involving(@user)
  end

  def test_involving_excludes_received_conversations_with_blockers
    @conversation.update!(originator: @recipient, recipient: @user)
    create(:blocking, blocker: @recipient, blocked: @user)

    assert_empty Conversation.involving(@user)
  end

  def test_involving_includes_received_conversations_with_blocked_users
    @conversation.update!(originator: @recipient, recipient: @user)
    create(:blocking, blocker: @user, blocked: @recipient)

    assert_equal [@conversation], Conversation.involving(@user)
  end

  def test_involving_includes_started_conversations_with_deleted_users
    @recipient.destroy

    assert_equal [@conversation], Conversation.involving(@user)
  end

  def test_involving_includes_received_conversations_with_deleted_users
    @conversation.update!(originator: @recipient, recipient: @user)
    @recipient.destroy

    assert_equal [@conversation], Conversation.involving(@user)
  end

  def test_interlocutor_returns_nil_for_orphan_conversations_w_one_msg
    @recipient.destroy

    assert_nil @conversation.reload.interlocutor(@user)
  end

  def test_interlocutor_returns_nil_for_orphan_conversations_w_several_msgs
    @conversation.reply(sender: @recipient, recipient: @user, body: 'Hei!')
    @conversation.save!

    @recipient.destroy
    assert_nil @conversation.reload.interlocutor(@user)
  end

  def test_interlocutor_returns_nil_for_orphan_conversations_w_several_sent_msgs
    @conversation.reply(sender: @user, recipient: @recipient, body: 'Hei!')
    @conversation.save!

    @recipient.destroy
    assert_nil @conversation.reload.interlocutor(@user)
  end

  def test_recipient_when_she_has_sent_messages_and_originator_no_longer_there
    @conversation.reply(sender: @recipient, recipient: @user, body: 'Hei!')
    @conversation.save!

    @user.destroy

    assert_equal @recipient, @conversation.reload.recipient
  end

  def test_recipient_when_no_sent_messages_and_originator_no_longer_there
    @user.destroy

    assert_equal @recipient, @conversation.reload.recipient
  end
end