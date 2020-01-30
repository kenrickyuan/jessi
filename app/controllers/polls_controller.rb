class PollsController < ApplicationController
  before_action :set_poll, only: [:show, :edit, :update, :destroy, :set_poll_responses]
  before_action :set_event, only: [:create, :show, :destroy, :set_poll_responses]
  before_action :set_sidebar, only: [:index]

  # GET /polls
  # GET /polls.json
  def index
    @event = Event.find(params[:event_id])
    @polls = @event.polls
    @polls.each { |poll| set_poll_responses(poll) if poll.present? }
  end

  # GET /polls/1
  # GET /polls/1.json
  def show
    set_poll_responses(@poll) if @poll.present?
  end

  # GET /polls/new
  def new
    @poll = Poll.new
    @event = Event.find(params[:event_id])
  end

  # GET /polls/1/edit
  def edit
  end

  # POST /polls
  # POST /polls.json
  def create
    @poll = Poll.new(poll_params)
    @event = Event.find(params[:event_id])
    @poll.event = @event
    choices_array = []

    params["choices"].each do |choice|
      choices_array << { label:choice }
    end

    body = {
      "title": "#{@event.title}",
      "fields": [ {
        "title": "Choose:",
        "type": "multiple_choice",
        "properties": {
          "description": "#{@poll.question}",
          "allow_multiple_selection": true,
          "allow_other_choice": true,
          "choices": choices_array
          }
        }
      ]
    }

    typeform_api = Typeform.new
    response = typeform_api.create_form(body)
    @poll.link = response.parsed_response["_links"]["display"]
    @poll.typeform_id = response.parsed_response["id"]
    respond_to do |format|
      if @poll.save
        format.html { redirect_to event_polls_path(@event), notice: 'Poll was successfully created.' }
      else
        format.html { render :new }
      end
    # @poll.link = response.parsed_response["theme"]["href"]
    end
  end

  # PATCH/PUT /polls/1
  # PATCH/PUT /polls/1.json
  def update
    respond_to do |format|
      if @poll.update(poll_params)
        format.html { redirect_to @poll, notice: 'Poll was successfully updated.' }
        format.json { render :show, status: :ok, location: @poll }
      else
        format.html { render :edit }
        format.json { render json: @poll.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /polls/1
  # DELETE /polls/1.json
  def destroy
    typeform_api = Typeform.new
    id = @poll.typeform_id
    @poll.destroy
    typeform_api.delete_form(id)
    respond_to do |format|
      format.html { redirect_to event_polls_url(@event), notice: 'Poll was successfully destroyed.' }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_poll
    @poll = Poll.find(params[:id])
  end

  def set_event
    @event = Event.find(params[:event_id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def poll_params
    params.require(:poll).permit(:typeform_id, :event_id, :link, :form_title, :question)
  end

  def set_poll_responses(poll)
    typeform = poll.typeform_id
    typeform_api = Typeform.new
    response = typeform_api.responses(typeform)

    responses = []
    show = response.parsed_response["items"]
    if show.nil?
      poll.response_number = 0
    else
      show.each do |elements|
        # Some of the typeform responses are NULL, when someone submits a form without putting an answer in "other"
        if elements["answers"].nil? || elements["answers"].empty?
          next
        else
          # Refactor this later
          if elements["answers"].first["choices"]["other"].present?
            responses << elements["answers"].first["choices"]["other"]
          end
          if elements["answers"].first["choices"]["labels"].present?
            responses << elements["answers"].first["choices"]["labels"]
          end
        end
      end
      answer_count = Hash.new(0)
      responses.flatten.each do |label|
        answer_count[label] += 1
      end

      length = 0
      answer_count.each do |key, value|
        length += value
      end
      poll.responses = answer_count
      poll.response_number = length

      @sum = 0
      @sorted_answer_count = answer_count.sort_by {|k, v| -v}
      answer_count.each do |key, value|
        @sum += value
      end
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
