class TransactionsController < ApplicationController
  before_action :set_expense
  before_action :set_event

  def new
    @transaction = Transaction.new
    @all_guests = @expense.event.guests
    @guests = Array.wrap(@all_guests) - Array.wrap(@expense.guest)
  end

  def create
    @transaction = Transaction.new(transaction_params)
    @transaction.created_at = Time.now()
    @transaction.expense_id = @expense.id
    @transaction.payee = @expense.guest
    @transaction.payer = Guest.find(params[:transaction][:payer_id].to_i)
    if @transaction.save
      redirect_to event_expense_path(@event, @expense)
    else
      render :new
    end
  end

  def destroy
    @transaction = Transaction.find(params[:id])
    @transaction.destroy
    redirect_to event_expense_path(@event, @expense)
  end

  private

  def transaction_params
    params.require(:transaction).permit(:payer_id, :amount)
  end

  def set_expense
    @expense = Expense.find(params[:expense_id])
  end

  def set_event
    @event = @expense.event
  end
end
