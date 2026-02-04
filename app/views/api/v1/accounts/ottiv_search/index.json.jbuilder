json.data do
  json.results @results do |result|
    json.contact do
      json.id result[:contact][:id]
      json.name result[:contact][:name]
      json.email result[:contact][:email]
      json.phone_number result[:contact][:phone_number]
      json.identifier result[:contact][:identifier]
      json.thumbnail result[:contact][:thumbnail]
    end

    json.conversations result[:conversations] do |conversation|
      json.id conversation[:id]
      json.status conversation[:status]
      json.inbox_id conversation[:inbox_id]
      json.last_activity_at conversation[:last_activity_at]
      json.unread_count conversation[:unread_count]
      
      if conversation[:assignee]
        json.assignee do
          json.id conversation[:assignee][:id]
          json.name conversation[:assignee][:name]
          json.available_name conversation[:assignee][:available_name]
        end
      else
        json.assignee nil
      end
    end
  end

  json.messages @messages do |message|
    json.id message[:id]
    json.content message[:content]
    json.message_type message[:message_type]
    json.private message[:private]
    json.created_at message[:created_at]
    json.conversation_id message[:conversation_id]
    
    if message[:sender]
      json.sender do
        json.id message[:sender][:id]
        json.name message[:sender][:name]
      end
    else
      json.sender nil
    end

    if message[:conversation]
      json.conversation do
        json.id message[:conversation][:id]
        json.status message[:conversation][:status]
        json.contact do
          json.id message[:conversation][:contact][:id]
          json.name message[:conversation][:contact][:name]
          json.email message[:conversation][:contact][:email]
          json.phone_number message[:conversation][:contact][:phone_number]
          json.identifier message[:conversation][:contact][:identifier]
          json.thumbnail message[:conversation][:contact][:thumbnail]
        end
      end
    else
      json.conversation nil
    end
  end

  json.meta do
    json.total_contacts @meta[:total_contacts]
    json.total_conversations @meta[:total_conversations]
    json.total_messages @meta[:total_messages]
    json.page @meta[:page]
    json.per_page @meta[:per_page]
  end
end

