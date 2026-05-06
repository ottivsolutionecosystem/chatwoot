# frozen_string_literal: true

module Ottiv
  module Core
    module Services
      # Converte um registro Contact do ActiveRecord num documento
      # pronto para indexação no Meilisearch (índice ottiv_contacts_acc_{id}).
      #
      # phone_digits: número só com dígitos — permite bater "44 99999-0000"
      # com "(44)999990000" sem necessidade de regexp no Meilisearch.
      #
      # identifier não é campo searchable (alinhado com SPEC anterior).
      module OttivContactDocumentSerializer
        module_function

        def call(contact)
          {
            id:                       "contact_#{contact.id}",
            contact_id:               contact.id,
            name:                     contact.name.to_s.strip,
            email:                    contact.email.to_s.downcase.strip.presence,
            phone_number:             contact.phone_number.to_s.strip.presence,
            phone_digits:             digits_only(contact.phone_number),
            identifier:               contact.identifier.presence,
            thumbnail:                contact.avatar_url.presence,
            last_activity_at:         contact.last_activity_at&.to_i,
            has_resolved_conversation: contact.conversations
                                              .where(status: 'resolved')
                                              .exists?
          }
        end

        private

        def digits_only(phone)
          phone.to_s.gsub(/\D/, '').presence
        end
      end
    end
  end
end
