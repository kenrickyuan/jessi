class EventsController < ApplicationController
  before_action :set_event, only: [:show, :edit, :update, :destroy]
  before_action :set_sidebar, only: [:show]

  def index
    @events = Event.where(user: current_user.id).order('start_time')
  end

  def show
    set_event_alert
    set_delete_alert
    set_event_link
  end

  def new
    @event = Event.new
  end

  def create
    @event = Event.new(event_params)
    @event.user = current_user
    guest1 = Guest.new(name: current_user.name, event: @event)
    guest1.save!

    if @event.save!
      redirect_to event_path(@event)
    else
      render :new
    end
  end

  def edit
  end

  def update
    @event.update(event_params)
    redirect_to event_path(@event)
  end

  def destroy
    @event.expenses.destroy_all
    @event.destroy!
    @events = Event.where(user: current_user.id).order('start_time')
    if @events.empty?
      redirect_to welcome_path
    else
      redirect_to event_path(@events.last)
    end
  end

  private

  def event_params
    params.require("event").permit(:start_time, :end_time, :title, :description, :location)
  end

  def set_event
    @event = Event.find(params[:id])
  end

  def set_event_link
    start_date = CGI.escape(@event.start_time.strftime("%m/%d/%Y %H:%M")) if @event.start_time.present?
    end_date = CGI.escape(@event.end_time.strftime("%m/%d/%Y %H:%M")) if @event.end_time.present?
    title = CGI.escape(@event.title)
    description = CGI.escape(@event.description)
    location = CGI.escape(@event.location)

    if @event.start_time.present? && @event.start_time < @event.end_time
      @link_google = "https://www.addevent.com/dir/?client=aBimVzdSwzJBZhEUtmws80704&start=#{start_date}&end=#{end_date}&title=#{title}&description=#{description}&location=#{location}&service=google"
      @link_apple = "https://www.addevent.com/dir/?client=aBimVzdSwzJBZhEUtmws80704&start=#{start_date}&end=#{end_date}&title=#{title}&description=#{description}&location=#{location}&service=apple"
      @share_message =
      "I created an event with jessi.io!\nClick the links below to push the event to your calendar\n \nApple calendar:\n#{@link_apple}\n \nGoogle calendar:\n#{@link_google}"
    else
      return
    end
    # client= key is the api key from addevent.com
  end

  def set_event_alert
    if @event.start_time.present? && @event.start_time < @event.end_time
      @alert_message = "alert('Event links saved to your clipboard, paste it to your guests!')"
    elsif !@event.start_time.present?
      @alert_message = "alert('Your event has no start time! I cannot create a calendar link without it!')"
    else
      @alert_message = "alert('Your event ends before it starts! I cannot create a calendar link for something like that!')"
    end
  end

  def set_delete_alert
    if @event.expenses.empty?
      @delete_message = "Are you sure?"
    else
      @delete_message = "This event still has expenses. If you proceed, these expenses will also be deleted. Are you sure?"
    end
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
