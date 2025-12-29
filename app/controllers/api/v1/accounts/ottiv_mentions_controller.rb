class Api::V1::Accounts::OttivMentionsController < Api::V1::Accounts::BaseController
  def create
    conversation = Current.account.conversations.find(params[:conversation_id])
    mention = Mention.create!(
      conversation_id: conversation.id,
      account_id: Current.account.id,
      user_id: Current.user.id,
      **mention_params
    )

    render json: mention.as_json, status: :created
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: 'Conversation not found' }, status: :not_found
  rescue StandardError => e
    Rails.logger.error("❌ [OttivMentions] Erro ao criar mention: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
  end

  private

  def mention_params
    params.require(:mention).permit(:content, :mentioned_user_id)
  end
end

