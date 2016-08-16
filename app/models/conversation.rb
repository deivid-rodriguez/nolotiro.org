# frozen_string_literal: true

class Conversation < ActiveRecord::Base
  validates :subject, presence: true, length: { maximum: 255 }

  has_many :messages, dependent: :destroy
  has_many :receipts, through: :messages

  belongs_to :originator, class_name: 'User'
  belongs_to :recipient, class_name: 'User'

  scope :involving, ->(user) do
    joins(:receipts).merge(Receipt.involving(user).untrashed).distinct
  end

  scope :unread_by, ->(user) do
    joins(:receipts).merge(Receipt.involving(user).unread).distinct
  end

  def self.start(sender:, recipient:, subject: '', body: '')
    conversation = new(subject: subject,
                       originator_id: sender.id,
                       recipient_id: recipient.id)

    conversation.envelope_for(sender: sender, recipient: recipient, body: body)

    conversation
  end

  def envelope_for(sender:, recipient:, body: '')
    message = messages.build(sender: sender, body: body)

    message.envelope_for(recipient)

    message
  end

  def reply(sender:, recipient:, body: '')
    self.updated_at = Time.zone.now

    envelope_for(sender: sender, recipient: recipient, body: body)
  end

  def interlocutor(user)
    user == originator ? recipient : originator
  end

  def messages_for(user)
    messages.involving(user)
  end

  def last_message
    @last_message ||= messages.last
  end

  def unread?(user)
    messages.unread_by(user).any?
  end

  delegate :mark_as_read, :move_to_trash, to: :receipts
end
