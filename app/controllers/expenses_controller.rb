class ExpensesController < ApplicationController
  before_action :set_event, only: [:new, :create, :index, :show]

  def new
    @expense = Expense.new
    @transaction = Transaction.new
  end

  def create
    @expense = Expense.new(expense_params)
    @expense.event_id = @event.id
    if @expense.save!
      @event.guests.each do |guest|
        next if guest.id == @expense.guest_id

        @transaction = Transaction.new
        @transaction.expense_id = @expense.id
        @transaction.payer = guest
        @transaction.payee = @expense.guest
        amount = @expense.amount / @event.guests.size
        @transaction.amount = amount
        @transaction.is_debt = true
        unless @transaction.save!
          render :new
        end
      end
      redirect_to event_expenses_path
    else
      render :new
    end
  end

  def index
    @expenses = @event.expenses
    filter_by_description if params[:search] && params[:search][:description].present?
    filter_by_guest if params[:search] && params[:search][:guest].present?
  end

  def show
    set_expense
    set_transactions
    settle_transactions
  end

  def destroy
    set_expense
    @expense.destroy
    redirect_to event_expenses_path
  end

  private

  def expense_params
    params.require(:expense).permit(:description, :amount, :guest_id)
  end

  def set_expense
    @expense = Expense.find(params[:id])
  end

  def set_event
    @event = Event.find(params[:event_id])
  end

  def set_transactions
    @transactions = []
    Transaction.where(expense_id: @expense.id).each do |transaction|
      @transactions << transaction
    end
    @transactions
  end

  def settle_transactions
    @transactions_hash = {}
    @transactions.each do |transaction|
      if transaction.is_debt == false
        if (@transactions_hash.key?(transaction.payer))
          @transactions_hash[transaction.payer] += transaction.amount
        else
          @transactions_hash[transaction.payer] = 0
          @transactions_hash[transaction.payer] += transaction.amount
        end
      end
    end
    @transactions.each do |transaction|
      if transaction.is_debt == true
        if (@transactions_hash.key?(transaction.payer))
          @transactions_hash[transaction.payer] -= transaction.amount
        else
          @transactions_hash[transaction.payer] = 0
          @transactions_hash[transaction.payer] -= transaction.amount
        end
      end
      @transactions_hash
    end
  end

  def filter_by_description
    @expenses = @expenses.where(description: params[:search][:description])
  end

  def filter_by_guest
    @expenses = @expenses.where(guest: params[:search][:guest])
  end
end