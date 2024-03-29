class Board < ActiveRecord::Base
  has_many :user_boards, foreign_key: "board_id", dependent: :destroy
  has_many :boarders, through: :user_boards, source: :boarder
  has_many :stages, dependent: :destroy
  has_many :shows, dependent: :destroy
  has_many :ext_links, as: :linkable, dependent: :destroy
  validates :vanity_url, presence: true, length: {minimum:4, maximum:20}
  validates :name, presence: true, length: {minimum:3, maximum:35}
  before_save { self.vanity_url = vanity_url.downcase }
  validates_format_of :vanity_url, :with => /[-a-z0-9_.]/
  accepts_nested_attributes_for :stages, :allow_destroy => true
  accepts_nested_attributes_for :shows, :allow_destroy => true
  accepts_nested_attributes_for :ext_links, :reject_if => :all_blank, :allow_destroy => true
  has_many :sales, as: :actionee
  has_attached_file :header_image, :s3_protocol => :https
  validates_attachment :header_image, :content_type => { :content_type => ["image/jpeg", "image/png"] }
  validates_with AttachmentSizeValidator, :attributes => :header_image, :less_than => 1.megabytes
  before_post_process :check_file_size
  has_many :email_subscriptions, :dependent => :destroy
  has_many :email_subscribers, :through => :email_subscriptions, :source => :email_subscriber, :source_type => "User"
  has_many :email_subscribers, :through => :email_subscriptions, :source => :email_subscriber, :source_type => "Guest"

  def check_file_size
    valid?
    errors[:image_file_size].blank?
  end

  def to_param
    vanity_url
  end

  def twitter_or_name
    if self.ext_links.where(ext_site: "Twitter") && self.ext_links.where(ext_site: "Twitter").count > 0
      twitter = "@" + self.ext_links.where(ext_site: "Twitter").first.url.split("/").last
      return twitter
    else
      return name
    end
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

  def stripe_connected?
    if self.boarders.first.stripe_recipient_id
      true
    else
      false
    end
  end

  def ext_links_fontawesomed
    links_html = ""
    self.ext_links.each do |e|
      if e.url && e.ext_site
        if e.ext_site == "Twitter"
          links_html = links_html + "<a href=\"#{e.url}\" target=\"_blank\"><i class=\"fa fa-twitter board-ext-link\"></i></a>"
        elsif e.ext_site == "Facebook"
          links_html = links_html + "<a href=\"#{e.url}\" target=\"_blank\"><i class=\"fa fa-facebook-square board-ext-link\"></i></a>"
        elsif e.ext_site == "Instagram"
          links_html = links_html + "<a href=\"#{e.url}\" target=\"_blank\"><i class=\"fa fa-instagram board-ext-link\"></i></a>"
        elsif e.ext_site == "Homepage"
          links_html = links_html + "<a href=\"#{e.url}\" target=\"_blank\"><i class=\"fa fa-home board-ext-link\"></i></a>"
        elsif e.ext_site == "Youtube"
          links_html = links_html + "<a href=\"#{e.url}\" target=\"_blank\"><i class=\"fa fa-youtube-play board-ext-link\"></i></a>"
        end
        if e != self.ext_links.last
          links_html = links_html + " "
        end
      end
    end
    if self.email && self.email != "" && self.email != " "
      links_html += "<a href=\"mailto:#{self.email}\" target=\"_blank\"><i class=\"fa fa-envelope board-ext-link\"></i></a>"
    end
    return links_html.html_safe
  end

  def self_zone
    place = self.stages.first.place
    result = GoogleTimezone.fetch(place.lat, place.lng, language: 'en', signature: ENV["GOOGLE_KEY"])
    self.update(timezone: result.time_zone_id)
  end
end