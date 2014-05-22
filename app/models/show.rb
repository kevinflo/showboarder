class Show < ActiveRecord::Base
  belongs_to :stage, dependent: :destroy
  belongs_to :board, dependent: :destroy
  has_many :tickets

  def transact(actioner, state_before, state_after)
    Transaction.create(actioner_id:actioner.id, actioner_type:actioner.class.to_s, actionee_id:self.id, actionee_type:"Show", state_before:state_before, state_after:state_after)
  end

  def tickets_make
    if self.custom_capacity
      capacity = self.custom_capacity.to_i
    else
      capacity = self.board.stages.first.capacity.to_i
    end

    puts self.stage.capacity.to_i
    (1..capacity).each do |t|
      self.tickets.create(price:self.price_adv)
    end
  end

  def unsold_count
    return self.tickets.where(state:"open").count
  end

  def tickets_adjust(quantity)
    if self.tickets.count < quantity
      (self.tickets.count..quantity-1).each do |t|
        self.tickets.create
      end
    else
      if self.unsold_count > self.tickets.count - quantity
        self.tickets.each do |t|
          if t.bought_at == nil
            t.destroy
          end
          break if self.tickets.count == quantity
        end
      else
        flash[:error] = "Sorry, you cannot adjust capacity below the amount of tickets that have already sold."
        redirect_to show_path(@show)
      end
    end
  end

  def tickets_reserve(quantity, reserver_id = nil, reserver_type = nil)
    if self.unsold_count >= quantity
      reserve_code = ""
      #go through tickets of state that should be changed by state and change state buyer_id and buyer_type as appropriate via ticket state method 
      open = Ticket.where(show_id:self.id, state:"open")
      (0..quantity-1).each do |c|
        t = open[c]
        h = SecureRandom.hex(8)
        t.update_attributes(state:"reserved", ticket_owner_id:reserver_id, ticket_owner_type:reserver_type, reserved_at:DateTime.now, reserve_code: h)
        t.buy_or_die
        if reserve_code == ""
          reserve_code = h
        else
          reserve_code = reserve_code + "-" + h
        end
      end
      if reserver_id == nil
        return reserve_code
      end
    else
      raise "Sorry, not enough tickets are available at this time."
      # redirect to show_path(@show)
    end
  end

  def tickets_buy(quantity, buyer_id, buyer_type)
    reserved = Ticket.where(show_id:self.id, state:"reserved", ticket_owner_id:buyer_id, ticket_owner_type:buyer_type)
    if reserved.length >= quantity
      (0..quantity-1).each do |t|
        reserved[t].update_attributes(state:"owned", bought_at:Time.now, buy_method:"online")
      end
    else
      raise "Sorry, not enough tickets are reserved by this user or guest."
      # redirect to show_path(@show)
    end
  end

  # def tickets_state(state, quantity, buyer_id, buyer_type)
  #   if self.unsold_count <= quantity
  #     #go through tickets of state that should be changed by state and change state buyer_id and buyer_type as appropriate via ticket state method 
  #     self.tickets.each do |t|
  #       if state == "reserved"
  #         if t.state == "open"
  #           t.update_attributes(state:state,ticket_owner_id:buyer_id, ticket_owner_type:buyer_type)
  #           quantity = quantity - 1
  #         end
  #       end
  #       if state == "owned"
  #         if t.state == ("open" || "canceled")
  #           t.update_attributes(state:state,ticket_owner_id:buyer_id, ticket_owner_type:buyer_type)
  #           quantity = quantity - 1
  #         end
  #       end
  #       break if quantity == 1
  #     end
  #   else
  #     flash[:error] = "Sorry, not enough tickets are available at this time."
  #     redirect to show_path(@show)
  #   end
  # end
end
