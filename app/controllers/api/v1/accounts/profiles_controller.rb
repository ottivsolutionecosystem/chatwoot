class Api::V1::Accounts::ProfilesController < Api::V1::Accounts::BaseController
  before_action :set_user

  def custom_attributes
    custom_attrs = custom_attributes_params
    
    # Usar Current.account.id (já definido pelo EnsureCurrentAccountHelper via params[:account_id])
    account_id = Current.account&.id

    raise ActiveRecord::RecordNotFound, 'Account not found' unless account_id
    
    # Validar que o usuário pertence à account (já validado pelo EnsureCurrentAccountHelper, mas garantindo)
    account_user = @user.account_users.find_by(account_id: account_id)
    raise ActiveRecord::RecordNotFound, 'User does not belong to this account' unless account_user
    
    # Validar que todos os tokens enviados têm o mesmo account_id (se enviado)
    if custom_attrs[:wavoip_tokens].present?
      custom_attrs[:wavoip_tokens].each do |token|
        token_account_id = token[:account_id]&.to_i
        if token_account_id.present? && token_account_id != account_id
          raise ArgumentError, "Token account_id (#{token_account_id}) does not match current account (#{account_id})"
        end
      end
    end

    # Inicializar custom_attributes como hash vazio se for nil
    @user.custom_attributes ||= {}
    @user.custom_attributes['wavoip_tokens'] ||= []

    # Converter para array se ainda estiver no formato antigo (hash)
    if @user.custom_attributes['wavoip_tokens'].is_a?(Hash)
      old_hash = @user.custom_attributes['wavoip_tokens']
      @user.custom_attributes['wavoip_tokens'] = []
      # Converter hash para array com account_id
      old_hash.each do |acc_id, tokens|
        tokens.each do |token|
          @user.custom_attributes['wavoip_tokens'] << token.merge('account_id' => acc_id.to_i)
        end
      end
    end

    # Remover tokens da account atual
    @user.custom_attributes['wavoip_tokens'].reject! { |t| t['account_id'] == account_id }

    # Adicionar novos tokens com account_id (usar account_id do Current.account, não do token)
    if custom_attrs[:wavoip_tokens].present?
      custom_attrs[:wavoip_tokens].each do |token|
        # Remover account_id do token se presente e usar o account_id do Current.account
        token_without_account_id = token.is_a?(Hash) ? token.except(:account_id, 'account_id') : token.to_h.except(:account_id, 'account_id')
        @user.custom_attributes['wavoip_tokens'] << token_without_account_id.merge('account_id' => account_id)
      end
    end

    # Fazer merge dos outros custom_attributes (como phone_number) - global
    if custom_attrs[:phone_number].present?
      @user.custom_attributes['phone_number'] = custom_attrs[:phone_number]
    end

    @user.save!

    # Renderizar o profile atualizado
    render 'api/v1/profiles/show', format: :json
  end

  private

  def set_user
    @user = current_user
  end

  def custom_attributes_params
    permitted = params.require(:profile).permit(
      custom_attributes: [
        :phone_number,
        wavoip_tokens: [:token, :name, :isActive, :account_id]
      ]
    )
    custom_attrs = permitted[:custom_attributes] || {}

    # Converter wavoip_tokens de hash indexado para array e processar isActive
    if custom_attrs[:wavoip_tokens].present?
      if custom_attrs[:wavoip_tokens].is_a?(ActionController::Parameters) || custom_attrs[:wavoip_tokens].is_a?(Hash)
        # Quando vem como hash indexado (0, 1, 2...), converter para array
        custom_attrs[:wavoip_tokens] = custom_attrs[:wavoip_tokens].values.map do |token|
          token_params = token.is_a?(ActionController::Parameters) ? token.to_h : token
          # Converter isActive de string para boolean
          token_params[:isActive] = token_params[:isActive] == 'true' if token_params[:isActive].is_a?(String)
          # Converter account_id para integer se presente
          token_params[:account_id] = token_params[:account_id].to_i if token_params[:account_id].present?
          token_params
        end
      elsif custom_attrs[:wavoip_tokens].is_a?(Array)
        # Já é array, apenas processar isActive e account_id
        custom_attrs[:wavoip_tokens] = custom_attrs[:wavoip_tokens].map do |token|
          token_params = token.is_a?(ActionController::Parameters) ? token.to_h : token
          # Converter isActive de string para boolean
          token_params[:isActive] = token_params[:isActive] == 'true' if token_params[:isActive].is_a?(String)
          # Converter account_id para integer se presente
          token_params[:account_id] = token_params[:account_id].to_i if token_params[:account_id].present?
          token_params
        end
      end
    end

    custom_attrs.to_h
  end
end

