class Sale < ActiveRecord::Base
  # has_paper_trail

  belongs_to :actioner, polymorphic: true
  belongs_to :actionee, polymorphic: true
  has_many :charges
  has_one :subscription

  validates_uniqueness_of :guid

  before_save :populate_guid  

  def to_param
    guid
  end

  include AASM

  aasm column: 'state', skip_validation_on_save: true do
    state :pending, initial: true
    state :processing
    state :finished
    state :errored
    state :refunded

    event :process, after: :charge_card do
      transitions from: :pending, to: :processing
    end

    event :finish, after: :send_receipt do
      transitions from: :processing, to: :finished
    end

    event :fail do
      transitions from: :processing, to: :errored
    end

    event :refund, after: :send_refund_email do
      transitions from: :finished, to: :refunded
    end
  end

  

  def charge_card #new version
    begin
      #######################################################################
      ########################## FOR TICKET PURCHASE ########################
      #######################################################################
      if self.actionee_type == "Cart"
        owners = Hash.new { |hash, key| hash[key] =  []} # hash so tickets in cart can be grouped by board owner for efficient stripe charge creation
        if actioner.class.to_s == "User"
          if actioner.stripe_id?
            customer = Stripe::Customer.retrieve(actioner.stripe_id)
            customer.card = self.stripe_token
            customer.save

          else

            customer = Stripe::Customer.create(
              card: self.stripe_token,
              email: actioner.email,
              description: actionee.tickets.count.to_s + " ticket purchase. TRANSACTION : " + self.guid.to_s #maybe add more detail here
            )            
            actioner.update(stripe_id:customer.id)

          end
        else
          customer = Stripe::Customer.create(
              card: self.stripe_token,
              email: actioner.email,
              description: actionee.tickets.count.to_s + " ticket purchase. TRANSACTION : " + self.guid.to_s #maybe add more detail here
            )
        end

        actionee.tickets.each do |t| # separate tickets by board owners
          owners[t.show.board.owner.stripe_access_key] = owners[t.show.board.owner.stripe_access_key] << t.guid
        end

        owners.each do |o| # go through owners and make a charge for each one
          tickets_by_owner = Cart.create #array to temporarily store tickets for each owner to avoid having to look them up in the database by GUID again
          amount = 0
          desc_b = "" #these build pieces of the description string with each ticket.  _b board _s show _t ticket
          desc_s = ""
          desc_t = ""

          owners[o[0]].each do |t| #go through the tickets for the owner to make the charge
            ticket = Ticket.find_by(guid:t)
            tickets_by_owner.tickets << ticket
            desc_b = desc_b + ticket.show.board.name.to_s + " "
            desc_s = desc_s + ticket.show.id.to_s + " "
            desc_t = desc_t + t.to_s + " "
            amount = amount + (ticket.price*100).to_i
          end

          connect_token = Stripe::Token.create({ #make stripe token for each owner
              customer:customer.id
            }, o[0]
          )

          if charge = Stripe::Charge.create( # make charge with each stripe token
            {
              card: connect_token.id,
              amount: amount,
              currency: "usd",
              description: "Ticket purchase. BOARDS: " + desc_b + "SHOWS: " + desc_s + "TICKETS: " + desc_t + "TRANSACTION: " + self.guid.to_s
            },
            o[0]
          )
            tickets_by_owner.tickets.each do |t|
              t.buy(actioner)
            end

            Charge.create(sale:self, stripe_id:charge.id, amount:amount, actionee:tickets_by_owner) # create charge object that belongs to this sale
          end
        end        

        self.update_attributes(
          stripe_id:       charge.id
        )

        Card.create(user_id:actioner.id,
          stripe_id:charge.card.id,
          last4:charge.card.last4,
          expiration:Date.new(charge.card.exp_year, charge.card.exp_month, 1),
          brand: charge.card.type
          )

        if actioner.class.to_s == "User"
          self.actioner.update_attributes(
            stripe_id:customer.id,
            # card_last4:      charge.card.last4,
            email:customer.email.downcase,
            # card_expiration: Date.new(charge.card.exp_year, charge.card.exp_month, 1),
            # card_type:       charge.card.type,      
            )
        end
        self.finish!
      #######################################################################
      ######################## FOR BOARD SUBSCRIPTION #######################
      #######################################################################
      elsif actionee_type == "Board"
        if actioner.stripe_id #if user has associated stripe account, retrieve it
          customer = Stripe::Customer.retrieve(actioner.stripe_id)

          if token_type == "card"
            card = customer.cards.retrieve(stripe_token)
          else
            card = customer.cards.create(stripe_token)
          end

        else
          if token_type == "card"
            raise "Token type of card when user does not have associated stripe account"
          end

          customer = Stripe::Customer.create(
            :card => stripe_token,
            :email => actioner.email
          )

          card = customer.cards.retrieve(customer.cards.first.id)

          actioner.update_attributes(stripe_id:customer.id)
        end

        if sub = customer.subscriptions.create(
            plan: plan
            )

          actioner.board_role_assign(actionee, "owner")
          actionee.update(paid_tier:1, paid_at:Time.now)
          Subscription.create(user_id:actioner.id, board_id:actionee.id, paid_at: DateTime.now, paid_until: DateTime.now + 1.month, plan: plan, stripe_id: sub.id)

          # Card.create(user_id:actioner.id, #todo
          #   stripe_id:sub.card.id,
          #   last4:sub.card.last4,
          #   expiration:Date.new(sub.card.exp_year, sub.card.exp_month, 1),
          #   brand: sub.card.type
          #   )          
          # actionee.user_boards.find_by(boarder_id:actioner.id).update_attributes(role:"owner")
          self.finish!
        end       
        
      #######################################################################
      ######################### FOR SHOW PURCHASE ###########################
      ###################### Might support this later #######################
      elsif actionee_type == "Show"
        # if actioner.stripe_id
        self.update_attributes(error:"Sorry, this transaction is currently unsupported") 
        self.fail!
      end

    rescue Stripe::StripeError => e
      self.update_attributes(error: e.message)
      self.fail!
    end
  end

  def charge_card
    begin
      ################## THE PART THAT SETS THE CUSTOMER AND CARD ###################
      if actioner_type == "User" #Customer and card for user

        if actioner.stripe_id #If user has an associated stripe customer, retrieve it
          customer = Stripe::Customer.retrieve(actioner.stripe_id)

          if token_type == "card" #If purchase is being made with saved card 
            card = customer.cards.retrieve(stripe_token)
          
          else #Else use the token to create the stripe card
            card = customer.cards.create(card:stripe_token)
          end

        else #If user does not have an associated stripe customer, create one for it and save it to the user
          customer = Stripe::Customer.create(
            email: actioner.email,
            description: "Actionee type: " + actionee_type + " Transaction ID: " + guid
            )

          card = customer.cards.create(card: stripe_token)
        end

        if stripe_remember_card
          actioner.update(stripe_default_card: card.id)

          if token_type == "token"
            Card.create(user_id: actioner.id,
              stripe_id: card.id,
              last4: card.last4,
              expiration: Date.new(card.exp_year, card.exp_month, 1),
              brand: card.type
              )
          end
        end

      else # Customer and card for guest
        customer = Stripe::Customer.create(
          email: actioner.email,
          description: "Guest - Actionee type: " + actionee_type + " Transaction ID: " + guid
          )

        card = Customer::Cards.create(card: stripe_token)
      end

      ################## THE PART THAT SETS THE CHARGE OR SUBSCRIPTION ###################
      if actionee_type == "Cart" #Creates charges for tickets
        owners = Hash.new { |hash, key| hash[key] =  []} # hash so tickets in cart can be grouped by board owner for efficient stripe charge creation

        actionee.tickets.each do |t| # separate tickets by board owners
          owners[t.show.board.owner.stripe_access_key] = owners[t.show.board.owner.stripe_access_key] << t.guid
        end

        owners.each do |o| # go through owners and make a charge for each one
          tickets_by_owner = Cart.create #array to temporarily store tickets for each owner to avoid having to look them up in the database by GUID again
          amount = 0
          desc_b = "" #these build pieces of the description string with each ticket.  _b board _s show _t ticket
          desc_s = ""
          desc_t = ""

          owners[o[0]].each do |t| #go through the tickets for the owner to make the charge
            ticket = Ticket.find_by(guid:t)
            tickets_by_owner.tickets << ticket
            desc_b = desc_b + ticket.show.board.name.to_s + " "
            desc_s = desc_s + ticket.show.id.to_s + " "
            desc_t = desc_t + t.to_s + " "
            amount = amount + (ticket.price*100).to_i
          end

          connect_token = Stripe::Token.create({ #make stripe token for each owner
              customer:customer.id,
              card: card.id
            }, o[0]
          )

          if charge = Stripe::Charge.create( # make charge with each stripe token
            {
              card: connect_token.id,
              amount: amount,
              currency: "usd",
              description: "Ticket purchase. BOARDS: " + desc_b + "SHOWS: " + desc_s + "TICKETS: " + desc_t + "TRANSACTION: " + self.guid.to_s
            },
            o[0]
          )
            tickets_by_owner.tickets.each do |t|
              t.buy(actioner)
            end

            Charge.create(sale:self, stripe_id:charge.id, amount:amount, actionee:tickets_by_owner, actioner:actioner) # create charge object that belongs to this sale
          end
        end

      else #Creates subscription for boards
        if sub = customer.subscriptions.create(
            plan: plan,
            card: card.id
            )

          actioner.board_role_assign(actionee, "owner")
          actionee.update(paid_tier:1, paid_at:Time.now)
          Subscription.create(user_id:actioner.id, board_id:actionee.id, paid_at: DateTime.now, paid_until: DateTime.now + 1.month, plan: plan, stripe_id: sub.id)
        end
      end

    rescue Stripe::StripeError => e
      self.update_attributes(error: e.message)
      self.fail!
    end    
  end

  def self.create_for_cart(options={})
    sale = new do |s|
      s.actioner = options[:actioner]
      s.actionee = options[:actionee]
      s.stripe_token = options[:stripe_token]
      s.stripe_remember_card = options[:stripe_remember_card]
      # total = 0

      # t.actionee.tickets.each do |e|
      #   total = total + (e.price * 100).to_i
      # end

      # t.amount = total
    end
      # t.opt_in = options[:opt_in]
    #   t.affiliate_id = options[:affiliate].try(:id)

    #   if options[:coupon_id]
    #     t.coupon = Coupon.find(options[:coupon_id])
    #     t.amount = options[:product].price * (1 - t.coupon.percent_off / 100.0)
    #   else
    #     t.amount = options[:product].price
    #   end
    # end
    sale
  end

  def self.create_for_board(options={})
    sale = new do |s|
      s.actioner = options[:actioner]
      s.actionee = options[:actionee]
      s.stripe_token = options[:stripe_token]
      s.plan = options[:plan]
      s.stripe_remember_card = options[:stripe_remember_card]
    end

    sale
  end

  def self.create_for_show(options={})
  end

  def queue_job!
    PaymentsWorker.perform_async(guid)
  end

  def token_type
    type = ""
    beginning = stripe_token[0..2]
    if beginning == "car"
      type = "card"
    elsif beginning == "tok"
      type = "token"
    end
    return type
  end

  def send_receipt
    # ReceiptMailer.delay.receipt(self.id)
    # MailchimpWorker.perform_async(guid) if Rails.configuration.mailchimp[:enabled]
  end

  def populate_guid
    if new_record?
      while !valid? || self.guid.nil?
        self.guid = SecureRandom.random_number(1_000_000_000_000_000_000).to_s(32)
      end
    end
  end

  
end