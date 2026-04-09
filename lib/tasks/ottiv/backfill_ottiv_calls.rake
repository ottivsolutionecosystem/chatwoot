# frozen_string_literal: true

namespace :ottiv do
  desc 'Backfill ottiv_calls a partir de mensagens privadas (compress / job Ottiv). Ver docs/ottiv_calls_backfill.md'
  task backfill_calls_from_messages: :environment do
    account_id = ENV['ACCOUNT_ID'].presence&.to_i
    if account_id.blank? || account_id.zero?
      abort 'Defina ACCOUNT_ID (ex.: ACCOUNT_ID=42 bundle exec rake ottiv:backfill_calls_from_messages)'
    end

    account = Account.find_by(id: account_id)
    abort "Account #{account_id} não encontrada" if account.blank?

    dry_run = ActiveModel::Type::Boolean.new.cast(ENV['DRY_RUN'])
    since = ENV['SINCE'].present? ? Time.zone.parse(ENV['SINCE']) : nil
    until_time = ENV['UNTIL'].present? ? Time.zone.parse(ENV['UNTIL']) : nil

    puts "Account ##{account.id} (#{account.name}) dry_run=#{dry_run} since=#{since.inspect} until=#{until_time.inspect}"

    stats = Ottiv::Core::Services::Calls::BackfillFromRecordingMessages.new(
      account: account,
      dry_run: dry_run,
      since: since,
      until_time: until_time
    ).perform

    puts stats.inspect
    puts "Concluído: criados=#{stats[:created]} duplicados=#{stats[:skipped_duplicate]} " \
         "sem_call_id=#{stats[:skipped_no_call_id]} sem_áudio=#{stats[:skipped_no_audio]} " \
         "escaneados=#{stats[:scanned]} erros=#{stats[:errors].size}"
    stats[:errors].first(20).each { |e| puts "  ERRO message_id=#{e[:message_id]}: #{e[:error]}" }
    puts '...' if stats[:errors].size > 20
  end
end
