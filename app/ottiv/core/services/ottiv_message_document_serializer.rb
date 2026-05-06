# frozen_string_literal: true

module Ottiv
  module Core
    module Services
      # Converte um registro Message do ActiveRecord num documento
      # pronto para indexação no Meilisearch (índice ottiv_messages_acc_{id}).
      #
      # Apenas mensagens incoming (0) e outgoing (1) são indexadas.
      # Mensagens privadas (private: true) são indexadas mas filtradas na busca
      # conforme permissão do usuário — decisão de produto.
      module OttivMessageDocumentSerializer
        module_function

        # Retorna nil se a mensagem não deve ser indexada.
        def call(message)
          return nil unless indexable?(message)

          conv = message.conversation
          {
            id:                             "msg_#{message.id}",
            message_id:                     message.id,
            conversation_id:                message.conversation_id,
            conversation_display_id:        conv&.display_id,
            contact_id:                     conv&.contact_id,
            inbox_id:                       message.inbox_id,
            content:                        message.content.to_s.strip,
            message_type:                   message.message_type,
            private:                        message.private?,
            created_at:                     message.created_at&.to_i,

            # Campos de conversa denormalizados (atualizados via fanout)
            conversation_status:            conv&.status,
            conversation_assignee_id:       conv&.assignee_id,
            conversation_priority:          conv&.priority,
            conversation_labels:            Array(conv&.label_list),
            conversation_last_activity_at:  conv&.last_activity_at&.to_i
          }
        end

        # Retorna apenas os campos conversation_* para partial update (fanout)
        def conversation_fields(message, conversation)
          {
            id:                            "msg_#{message.id}",
            conversation_status:           conversation.status,
            conversation_assignee_id:      conversation.assignee_id,
            conversation_priority:         conversation.priority,
            conversation_labels:           Array(conversation.label_list),
            conversation_last_activity_at: conversation.last_activity_at&.to_i
          }
        end

        def indexable?(message)
          message.message_type.in?(%w[incoming outgoing]) ||
            message.message_type.to_i.in?([0, 1])
        end
      end
    end
  end
end
