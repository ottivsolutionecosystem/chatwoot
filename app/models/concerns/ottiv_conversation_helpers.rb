# frozen_string_literal: true

# Concern que adiciona helpers otimizados para listagem de conversas
# Evita N+1 queries usando atributos pré-calculados
module OttivConversationHelpers
  extend ActiveSupport::Concern

  included do
    # Atributos virtuais que serão populados pelo finder otimizado
    attr_accessor :ottiv_last_message
    
    # Atributo para unread_count calculado via subquery
    # Definido como attribute para que o Rails reconheça quando vier de um SELECT
    attribute :ottiv_unread_count_value, :integer
  end

  # Retorna o unread_count pré-calculado ou calcula sob demanda
  def ottiv_unread_count
    return ottiv_unread_count_value if ottiv_unread_count_value.present?
    
    # Fallback: calcular sob demanda (causa query)
    unread_incoming_messages.count
  end

  class_methods do
    # Scope que pré-carrega dados para listagem otimizada
    # Usa subqueries para buscar última mensagem e unread_count de uma vez
    def ottiv_with_list_data
      # Subquery para contar mensagens não lidas
      # message_type = 0 corresponde a 'incoming' no enum do Message
      unread_count_sql = <<-SQL.squish
        (
          SELECT COUNT(*)
          FROM messages
          WHERE messages.conversation_id = conversations.id
            AND messages.account_id = conversations.account_id
            AND messages.message_type = 0
            AND messages.created_at > COALESCE(conversations.agent_last_seen_at, conversations.created_at - interval '1 second')
        )
      SQL

      select("conversations.*, #{unread_count_sql} as ottiv_unread_count_value")
    end

    # Pré-carrega últimas mensagens para um conjunto de conversas
    # Otimizado para evitar N+1
    def ottiv_preload_last_messages(conversations)
      return conversations if conversations.empty?

      conversation_ids = conversations.map(&:id)
      
      # Buscar última mensagem não-activity de cada conversa em uma única query
      # ✅ CORRIGIDO: DISTINCT ON requer ORDER BY começando com conversation_id
      # Usar except(:order) para remover o default scope do Message (created_at:asc)
      # Baseado no padrão usado em sort_handler.rb last_messaged_conversations
      last_messages = Message
        .except(:order) # ✅ Remove o default_scope que ordena por created_at
        .where(conversation_id: conversation_ids)
        .where.not(message_type: :activity)
        .order('conversation_id ASC, id DESC') # ✅ ORDER BY deve começar com conversation_id
        .select('DISTINCT ON (conversation_id) messages.*')
        .includes(:attachments) # ✅ Carregar attachments para evitar N+1 depois
        .index_by(&:conversation_id)

      # Popular o atributo ottiv_last_message em cada conversa
      conversations.each do |conv|
        conv.ottiv_last_message = last_messages[conv.id]
      end

      conversations
    end
  end
end

