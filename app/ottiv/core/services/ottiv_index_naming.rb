# frozen_string_literal: true

module Ottiv
  module Core
    module Services
      # Centraliza a geração de UIDs dos índices Meilisearch por tenant.
      #
      # Estratégia: índice por tenant → isolamento físico entre contas,
      # eliminando qualquer risco de vazamento entre tenants mesmo em bug
      # de filtro.
      #
      # Padrão de nomenclatura:
      #   ottiv_messages_acc_{account_id}
      #   ottiv_contacts_acc_{account_id}
      module OttivIndexNaming
        module_function

        def messages_uid(account_id)
          "ottiv_messages_acc_#{account_id}"
        end

        def contacts_uid(account_id)
          "ottiv_contacts_acc_#{account_id}"
        end

        # Retorna os dois UIDs da conta como Hash
        def all_uids(account_id)
          {
            messages: messages_uid(account_id),
            contacts: contacts_uid(account_id)
          }
        end

        # Extrai account_id de um UID (útil em tarefas de manutenção)
        def account_id_from_uid(uid)
          uid.to_s[/ottiv_(?:messages|contacts)_acc_(\d+)/, 1]&.to_i
        end
      end
    end
  end
end
