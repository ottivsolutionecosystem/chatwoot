# frozen_string_literal: true

module Ottiv::Core
  module Services
    module Wavoip
      # Resolve a conversa correta para vincular uma chamada Wavoip:
      # - Normaliza o telefone para E.164.
      # - Localiza o contato pelo telefone ou cria via ContactInboxWithContactBuilder.
      # - Garante que existe um contact_inbox para a inbox informada.
      # - Reutiliza a última conversa do contato nessa inbox (order by last_activity_at).
      # - Se não houver conversa, cria uma nova atribuída ao agente autenticado.
      #
      # Retorna:
      #   { conversation_id: display_id, contact_id: id, created_new_conversation: bool }
      class ResolveCallConversationService
        E164_RE = /\A\+[1-9]\d{1,14}\z/

        attr_reader :account, :user, :inbox, :phone_raw, :contact_display_name

        def initialize(account:, user:, inbox:, phone_raw:, contact_display_name: nil)
          @account = account
          @user = user
          @inbox = inbox
          @phone_raw = phone_raw
          @contact_display_name = contact_display_name
        end

        def perform
          e164 = normalize_e164(phone_raw)
          raise ArgumentError, I18n.t('errors.contacts.phone_number.invalid') unless e164

          contact = find_contact(e164) || create_contact_with_inbox!(e164)
          ensure_contact_inbox!(contact)

          conversation, created = find_or_create_conversation!(contact)

          {
            conversation_id: conversation.display_id,
            contact_id: contact.id,
            created_new_conversation: created
          }
        end

        private

        def normalize_e164(raw)
          digits = raw.to_s.gsub(/\D/, '')
          return nil if digits.blank?

          candidate = "+#{digits}"
          return candidate if candidate.match?(E164_RE)

          nil
        end

        def find_contact(e164)
          account.contacts.find_by(phone_number: e164)
        end

        def display_name_for(e164)
          name = contact_display_name.to_s.strip
          return name if name.present?

          TelephoneNumber.parse(e164).international_number
        rescue StandardError
          e164
        end

        # Fonte do source_id depende do canal da inbox.
        # WhatsApp requer apenas dígitos sem '+'.
        # SMS / TwilioSms usa E.164.
        # Para os demais (API, WebWidget) passamos nil para o builder gerar UUID.
        def source_id_for(e164)
          case inbox.channel_type
          when 'Channel::Whatsapp'
            e164.delete('+')
          when 'Channel::Sms', 'Channel::TwilioSms'
            e164
          end
          # nil para outros canais → ContactInboxBuilder gera source_id automático
        end

        def create_contact_with_inbox!(e164)
          sid = source_id_for(e164)

          contact_inbox = ::ContactInboxWithContactBuilder.new(
            inbox: inbox,
            source_id: sid,
            contact_attributes: {
              name: display_name_for(e164),
              phone_number: e164
            }
          ).perform

          contact_inbox.contact
        end

        def ensure_contact_inbox!(contact)
          return if ::ContactInbox.exists?(contact_id: contact.id, inbox_id: inbox.id)

          ::ContactInboxBuilder.new(
            contact: contact,
            inbox: inbox,
            source_id: source_id_for(contact.phone_number)
          ).perform
        end

        def find_or_create_conversation!(contact)
          conv = account.conversations
                        .where(contact_id: contact.id, inbox_id: inbox.id)
                        .order(Arel.sql('last_activity_at DESC NULLS LAST'))
                        .first

          return [conv, false] if conv.present?

          contact_inbox = ::ContactInbox.find_by!(contact_id: contact.id, inbox_id: inbox.id)

          conv = ::ConversationBuilder.new(
            params: ::ActionController::Parameters.new(
              status: 'open',
              assignee_id: user.id
            ),
            contact_inbox: contact_inbox
          ).perform

          [conv, true]
        end
      end
    end
  end
end
