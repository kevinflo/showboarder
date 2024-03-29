class ExtLink < ActiveRecord::Base
  belongs_to :linkable, polymorphic: true
  validates :ext_site, presence: true
  before_save { 
    if self.url?
      self.url = PostRank::URI.clean(url)
      if self.url[self.url.length - 1] == "/"
        self.url = self.url[0..self.url.length-2]
      end
    end
  }
  
  after_save { # this is used instead of regular validation because nested forms must save ext_links and preventing this prevents show creation
    if !self.url?
      self.destroy!
    end
  }

end
