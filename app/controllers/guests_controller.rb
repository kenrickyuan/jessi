class GuestsController < ApplicationController
  before_action :set_guest, only: [:show, :edit, :update, :destroy]
  before_action :set_event, only: [:index, :show, :new, :create, :edit, :update]
  def index
    @guests = @event.guests
  end

  def show
  end

  def new
    @guest = Guest.new
  end

  def create
    guests = params[:guests]
    @errors = []
    guests.each do |guest|
      @guest = Guest.new(name: guest, event: @event)
        unless @guest.save
          @errors << "Error: #{@guest.errors.full_messages}"
        end
    end
    if @errors.empty?
      redirect_to event_guests_path(@event)
    else
      render :new
    end
  end

  def edit
    @guest.event = @event
  end

  def update
    @guest.update(guest_params)
    redirect_to event_guests_path(@event, @guest)
  end

  def destroy
    @guest.destroy
    @event = Event.find(params[:event_id])
    redirect_to event_guests_path(@event)
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def set_guest
    @guest = Guest.find(params[:id])
  end

  def guest_params
    params.require("guest").permit(:name, :description)
  end
end
