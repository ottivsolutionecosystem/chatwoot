class AddSeriesIdToOttivScheduledMessages < ActiveRecord::Migration[7.0]
  def up
    add_column :ottiv_scheduled_messages, :series_id, :string, limit: 36

    add_index :ottiv_scheduled_messages, :series_id,
              name: 'idx_ottiv_scheduled_messages_series_id'

    # Backfill: assign a new series_id to every existing recurrent scheduled
    # message that is still pending (status = 0 = scheduled) and recurrent
    # (recurrence != 0). Since we cannot determine which historic records
    # belonged to the same series, each remaining scheduled record starts a
    # fresh series going forward.
    execute <<~SQL
      UPDATE ottiv_scheduled_messages
      SET    series_id = gen_random_uuid()::text
      WHERE  recurrence <> 0
        AND  status     = 0
        AND  series_id  IS NULL
    SQL
  end

  def down
    remove_index :ottiv_scheduled_messages, name: 'idx_ottiv_scheduled_messages_series_id'
    remove_column :ottiv_scheduled_messages, :series_id
  end
end
