class Api::Ottiv::OttivConfigsController < Api::BaseController
  def find
    account_id = request.headers['x-account'] || request.headers['HTTP_X_ACCOUNT']
    
    if account_id.blank?
      render json: { error: 'x-account header is required' }, status: :bad_request
      return
    end

    # Buscar dados da tabela config usando SQL direto
    config_data = fetch_config_data(account_id.to_i)
    
    if config_data.nil?
      render json: { error: 'Config not found' }, status: :not_found
      return
    end

    # Buscar attribute definitions
    attribute_ids = config_data['attributes'] || []
    attribute_definitions = fetch_attribute_definitions(account_id.to_i, attribute_ids)

    # Formatar resposta
    response_data = format_response(config_data, attribute_definitions)

    render json: response_data
  rescue StandardError => e
    Rails.logger.error("❌ [OttivConfig] Erro ao buscar config: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
  end

  private

  def fetch_config_data(account_id)
    query = <<-SQL
      SELECT 
        account_id,
        name,
        description,
        cnpj,
        street,
        number,
        complement,
        neighborhood,
        city,
        state,
        postal_code,
        country,
        integrations,
        ai_pipeline_id,
        ai_stages,
        currency,
        ai_id,
        team_credit_analyst_id,
        team_seller_id,
        seller_queue,
        inbox_id,
        attributes,
        proposal_template_id,
        token_chatwoot
      FROM config
      WHERE account_id = ?
    SQL

    sanitized_query = ActiveRecord::Base.sanitize_sql_array([query, account_id])
    result = ActiveRecord::Base.connection.exec_query(sanitized_query)
    return nil if result.empty?

    row = result.first
    
    # Parse JSONB fields se necessário
    row['integrations'] = parse_jsonb(row['integrations'])
    row['attributes'] = parse_jsonb(row['attributes'])
    
    # Normalizar arrays do PostgreSQL
    row['ai_stages'] = normalize_array(row['ai_stages'])
    row['seller_queue'] = normalize_array(row['seller_queue'])
    
    row
  end

  def fetch_attribute_definitions(account_id, attribute_ids)
    return { conversation: [], contact: [] } if attribute_ids.blank?

    # Buscar attribute definitions pelos IDs
    conversation_attrs = CustomAttributeDefinition
      .where(account_id: account_id, id: attribute_ids, attribute_model: :conversation_attribute)
      .map(&method(:format_attribute_definition))

    contact_attrs = CustomAttributeDefinition
      .where(account_id: account_id, id: attribute_ids, attribute_model: :contact_attribute)
      .map(&method(:format_attribute_definition))

    {
      conversation: conversation_attrs,
      contact: contact_attrs
    }
  end

  def format_attribute_definition(attr)
    {
      id: attr.id,
      attribute_display_name: attr.attribute_display_name,
      attribute_key: attr.attribute_key,
      attribute_display_type: attr.attribute_display_type,
      default_value: attr.default_value,
      attribute_model: attr.attribute_model == 'conversation_attribute' ? 0 : 1,
      attribute_description: attr.attribute_description,
      attribute_values: attr.attribute_values || [],
      regex_pattern: attr.regex_pattern,
      regex_cue: attr.regex_cue
    }
  end

  def parse_jsonb(value)
    return value if value.nil?
    return value if value.is_a?(Hash) || value.is_a?(Array)
    
    JSON.parse(value) rescue value
  end

  def normalize_array(value)
    return [] if value.nil?
    return value if value.is_a?(Array)
    
    # Se for string no formato PostgreSQL array "{1,2,3}"
    if value.is_a?(String) && value.start_with?('{') && value.end_with?('}')
      value = value[1..-2] # Remove { e }
      return value.split(',').map(&:strip).map { |v| v.gsub(/^"|"$/, '') }
    end
    
    # Tentar parsear como JSON
    JSON.parse(value) rescue []
  end

  def format_response(config_data, attribute_definitions)
    {
      account_id: config_data['account_id'],
      token_chatwoot: config_data['token_chatwoot'],
      name: config_data['name'],
      description: config_data['description'],
      cnpj: config_data['cnpj'],
      address: {
        street: config_data['street'],
        number: config_data['number'],
        complement: config_data['complement'],
        neighborhood: config_data['neighborhood'],
        city: config_data['city'],
        state: config_data['state'],
        postal_code: config_data['postal_code'],
        country: config_data['country']
      },
      currency: config_data['currency'] || 'BRL',
      integrations: config_data['integrations'] || {},
      ai_pipeline_id: config_data['ai_pipeline_id'],
      ai_stages: config_data['ai_stages'] || [],
      ai_id: config_data['ai_id'],
      team_credit_analyst_id: config_data['team_credit_analyst_id'],
      team_seller_id: config_data['team_seller_id'],
      seller_queue: config_data['seller_queue'] || [],
      inbox_id: config_data['inbox_id'],
      proposal_template_id: config_data['proposal_template_id'],
      idChatwoot: config_data['token_chatwoot'],
      attributes: config_data['attributes'] || [],
      attribute_definitions: attribute_definitions
    }
  end
end

