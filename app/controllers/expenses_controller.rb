class ExpensesController < ApplicationController
  before_action :set_event, only: [:new, :create, :index, :show]
  before_action :set_sidebar, only: [:index]

  def new
    @expense = Expense.new
    @transaction = Transaction.new
  end

  def create
    @expense = Expense.new(expense_params)
    @expense.event_id = @event.id
    if @expense.save
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
    Transaction.where(expense_id: @expense.id).order(:created_at).each do |transaction|
      @transactions << transaction
    end
    @transactions
  end

  def set_transaction_details(transaction)
    transaction_details = {}
    transaction_details[:payer] = transaction.payer
    transaction_details[:payee] = transaction.payee
    transaction_details[:datetime] = transaction.created_at
    transaction_details[:amount] = transaction.amount
    transaction_details[:is_debt] = transaction.is_debt
    transaction_details
  end

  def settle_transactions
    @balance = Hash.new(0)
    @payment_transactions_hash = {}
    @payment_transactions = []
    @transactions.each do |transaction|
      transaction_details = set_transaction_details(transaction)
      @payment_transactions_hash[transaction.payer.id] = transaction_details
      @payment_transactions << transaction_details
      if transaction.is_debt
        @balance[transaction.payer.id] = transaction.amount
      else
        @balance[transaction.payer.id] -= transaction.amount
      end
      transaction_details[:difference] = @balance[transaction.payer.id]
    end
  end

  def filter_by_description
    @expenses = @expenses.where(description: params[:search][:description])
  end

  def filter_by_guest
    @expenses = @expenses.where(guest: params[:search][:guest])
  end

  def set_sidebar
    @events = Event.where(user: current_user.id).order('start_time')
    @past = []
    @pending = []
    @current = []
    @events.each do |event|
      if event.start_time.nil? || event.start_time > Time.now
        @pending << event
      elsif event.start_time < Time.now || event.end_time < Time.now
        @past << event
      else
        @current << event
      end
    end
  end
end
