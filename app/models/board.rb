class Board < ActiveRecord::Base
  has_many :user_boards, foreign_key: "board_id", dependent: :destroy
  has_many :boarders, through: :user_boards, source: :boarder
  has_many :stages
  has_many :shows
  has_many :subscriptions
  validates :vanity_url, presence: true, length: {minimum:4, maximum:30}
  before_save { self.vanity_url = vanity_url.downcase }
  validates_format_of :vanity_url, :with => /[-a-z0-9_.]/
  accepts_nested_attributes_for :stages, :allow_destroy => true
  accepts_nested_attributes_for :shows, :allow_destroy => true
  has_many :sales, as: :actionee
  
  # has_many :reverse_user_boards, foreign_key: "board_id",
  #                                  class_name:  "UserBoard",
  #                                  dependent:   :destroy
  # has_many :boarders, through: :reverse_user_boards, source: :boarder  
  def to_param
    vanity_url
  end

  def owner
    User.find_by_id(user_boards.find_by(board_id:self.id, role:"owner").boarder_id)
  end

  def boarder?(user)
    user_boards.find_by(boarder_id: user.id)
  end

  def board_role(user)
    user_boards.find_by(boarder_id: user.id).role
  end

  def paid?
    # user_boards.where(board_id:self.id, role:"owner").length > 0
    if self.paid_tier != 0
      return true
    else
      return false
    end
  end

  def self_zone
    self.update(timezone: ActiveSupport::TimeZone[self.stages.first.place.utc_offset/60].to_s)
  end
end
