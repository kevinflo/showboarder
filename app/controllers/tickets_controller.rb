class TicketsController < ApplicationController
  def reserve
    @show = Show.find_by(id:params[:show_id])
    @quantity = params[:quantity].to_i
    @show.tickets_clear_expired_reservations

    if user_signed_in?
      @show.tickets_reserve(@quantity, current_user.id, current_user.class.to_s)
      redirect_to board_show_checkout_path(@show.board, @show)
    else
      @reserve_code = @show.tickets_reserve(@quantity, nil, nil)
      redirect_to board_show_checkout_path(@show.board, @show, reserve_code:@reserve_code)
    end
  end
end