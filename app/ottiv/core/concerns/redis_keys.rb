# frozen_string_literal: true

module Ottiv
  module Core
    module Concerns
      module RedisKeys
        extend ActiveSupport::Concern

        # Namespace base para todas as chaves Redis Ottiv Core
        REDIS_NAMESPACE = 'ottiv:core'

        # Chaves específicas
        module Keys
          # Cache de conversas
          CONVERSATION_LIST_CACHE = "#{REDIS_NAMESPACE}:conversations:list:%{account_id}:%{user_id}"

          # Cache de busca
          SEARCH_CACHE = "#{REDIS_NAMESPACE}:search:%{account_id}:%{query_hash}"

          # Mutex para operações
          CALENDAR_ITEM_MUTEX = "#{REDIS_NAMESPACE}:mutex:calendar_item:%{item_id}"
          SCHEDULED_MESSAGE_MUTEX = "#{REDIS_NAMESPACE}:mutex:scheduled_message:%{message_id}"

          # Notificações
          NOTIFICATION_QUEUE = "#{REDIS_NAMESPACE}:notifications:queue:%{user_id}"

          # Cache de configurações
          CONFIG_CACHE = "#{REDIS_NAMESPACE}:config:%{account_id}"
        end

        class_methods do
          def ottiv_redis_key(key_template, params = {})
            format(key_template, params)
          end
        end
      end
    end
  end
end

