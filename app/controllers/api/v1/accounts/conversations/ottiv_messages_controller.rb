class Api::V1::Accounts::Conversations::OttivMessagesController < Api::V1::Accounts::Conversations::BaseController
  before_action :set_message, only: [:show]

  def show
    # Renderiza a mensagem usando a view show.json.jbuilder
  end

  private

  def set_message
    @message = @conversation.messages.find(params[:message_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Message not found' }, status: :not_found
  end
end

