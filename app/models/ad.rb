class Ad < ActiveRecord::Base

  belongs_to :user, foreign_key: 'user_owner', :counter_cache => true
  has_many :comments, class_name: 'Comment', foreign_key: 'ads_id'

  # TODO: validations

  # legacy database: has a column with value "type", rails doesn't like that
  # the "type" column is no longer need it by rails, so we don't care about it
  self.inheritance_column = nil 

  default_scope { order('date_created DESC') }

  has_attached_file :image, :styles => {:thumb => "100x90>"}

  scope :give, -> { where(type: 1) }
  scope :want, -> { where(type: 2) }

  scope :available, -> { where(status: 1) }
  scope :booked, -> { where(status: 2) }
  scope :delivered, -> { where(status: 3) }

  def slug
    title.parameterize
  end

  def type_string
    case type
    when 1
      I18n.t('nlt.give')
    when 2
      I18n.t('nlt.want')
    else
      I18n.t('nlt.give')
    end 
  end

  def status_class
    case status
    when 1
      'available'
    when 2
      'booked' 
    when 3
      'delivered' 
    else
      'available'
    end 
  end

  def status_string
    case status
    when 1
      I18n.t('nlt.available')
    when 2
      I18n.t('nlt.booked') 
    when 3
      I18n.t('nlt.delivered') 
    else
      I18n.t('nlt.available')
    end 
  end

end
