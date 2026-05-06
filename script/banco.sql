CREATE TABLE "public"."access_tokens" (
  "id" SERIAL,
  "owner_type" VARCHAR NULL,
  "owner_id" BIGINT NULL,
  "token" VARCHAR NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "access_tokens_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."account_saml_settings" (
  "id" SERIAL,
  "account_id" BIGINT NOT NULL,
  "sso_url" VARCHAR NULL,
  "certificate" TEXT NULL,
  "sp_entity_id" VARCHAR NULL,
  "idp_entity_id" VARCHAR NULL,
  "role_mappings" JSON NULL DEFAULT '{}'::json ,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "account_saml_settings_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."account_users" (
  "id" SERIAL,
  "account_id" BIGINT NULL,
  "user_id" BIGINT NULL,
  "role" INTEGER NULL DEFAULT 0 ,
  "inviter_id" BIGINT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "active_at" TIMESTAMP NULL,
  "availability" INTEGER NOT NULL DEFAULT 0 ,
  "auto_offline" BOOLEAN NOT NULL DEFAULT true ,
  "custom_role_id" BIGINT NULL,
  "agent_capacity_policy_id" BIGINT NULL,
  CONSTRAINT "account_users_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."accounts" (
  "id" SERIAL,
  "name" VARCHAR NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "locale" INTEGER NULL DEFAULT 0 ,
  "domain" VARCHAR(100) NULL,
  "support_email" VARCHAR(100) NULL,
  "feature_flags" BIGINT NOT NULL DEFAULT 0 ,
  "auto_resolve_duration" INTEGER NULL,
  "limits" JSONB NULL DEFAULT '{}'::jsonb ,
  "custom_attributes" JSONB NULL DEFAULT '{}'::jsonb ,
  "status" INTEGER NULL DEFAULT 0 ,
  "internal_attributes" JSONB NOT NULL DEFAULT '{}'::jsonb ,
  "settings" JSONB NULL DEFAULT '{}'::jsonb ,
  CONSTRAINT "accounts_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."action_mailbox_inbound_emails" (
  "id" SERIAL,
  "status" INTEGER NOT NULL DEFAULT 0 ,
  "message_id" VARCHAR NOT NULL,
  "message_checksum" VARCHAR NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "action_mailbox_inbound_emails_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."active_storage_attachments" (
  "id" SERIAL,
  "name" VARCHAR NOT NULL,
  "record_type" VARCHAR NOT NULL,
  "record_id" BIGINT NOT NULL,
  "blob_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  CONSTRAINT "active_storage_attachments_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."active_storage_blobs" (
  "id" SERIAL,
  "key" VARCHAR NOT NULL,
  "filename" VARCHAR NOT NULL,
  "content_type" VARCHAR NULL,
  "metadata" TEXT NULL,
  "byte_size" BIGINT NOT NULL,
  "checksum" VARCHAR NULL,
  "created_at" TIMESTAMP NOT NULL,
  "service_name" VARCHAR NOT NULL,
  CONSTRAINT "active_storage_blobs_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."active_storage_variant_records" (
  "id" SERIAL,
  "blob_id" BIGINT NOT NULL,
  "variation_digest" VARCHAR NOT NULL,
  CONSTRAINT "active_storage_variant_records_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."agent_bot_inboxes" (
  "id" SERIAL,
  "inbox_id" INTEGER NULL,
  "agent_bot_id" INTEGER NULL,
  "status" INTEGER NULL DEFAULT 0 ,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "account_id" INTEGER NULL,
  CONSTRAINT "agent_bot_inboxes_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."agent_bots" (
  "id" SERIAL,
  "name" VARCHAR NULL,
  "description" VARCHAR NULL,
  "outgoing_url" VARCHAR NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "account_id" BIGINT NULL,
  "bot_type" INTEGER NULL DEFAULT 0 ,
  "bot_config" JSONB NULL DEFAULT '{}'::jsonb ,
  CONSTRAINT "agent_bots_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."agent_capacity_policies" (
  "id" SERIAL,
  "account_id" BIGINT NOT NULL,
  "name" VARCHAR(255) NOT NULL,
  "description" TEXT NULL,
  "exclusion_rules" JSONB NOT NULL DEFAULT '{}'::jsonb ,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "agent_capacity_policies_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."applied_slas" (
  "id" SERIAL,
  "account_id" BIGINT NOT NULL,
  "sla_policy_id" BIGINT NOT NULL,
  "conversation_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "sla_status" INTEGER NULL DEFAULT 0 ,
  CONSTRAINT "applied_slas_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."ar_internal_metadata" (
  "key" VARCHAR NOT NULL,
  "value" VARCHAR NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "ar_internal_metadata_pkey" PRIMARY KEY ("key")
);
CREATE TABLE "public"."article_embeddings" (
  "id" SERIAL,
  "article_id" BIGINT NOT NULL,
  "term" TEXT NOT NULL,
  "embedding" USER-DEFINED NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "article_embeddings_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."articles" (
  "id" SERIAL,
  "account_id" INTEGER NOT NULL,
  "portal_id" INTEGER NOT NULL,
  "category_id" INTEGER NULL,
  "folder_id" INTEGER NULL,
  "title" VARCHAR NULL,
  "description" TEXT NULL,
  "content" TEXT NULL,
  "status" INTEGER NULL,
  "views" INTEGER NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "author_id" BIGINT NULL,
  "associated_article_id" BIGINT NULL,
  "meta" JSONB NULL DEFAULT '{}'::jsonb ,
  "slug" VARCHAR NOT NULL,
  "position" INTEGER NULL,
  "locale" VARCHAR NOT NULL DEFAULT 'en'::character varying ,
  CONSTRAINT "articles_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."assignment_policies" (
  "id" SERIAL,
  "account_id" BIGINT NOT NULL,
  "name" VARCHAR(255) NOT NULL,
  "description" TEXT NULL,
  "assignment_order" INTEGER NOT NULL DEFAULT 0 ,
  "conversation_priority" INTEGER NOT NULL DEFAULT 0 ,
  "fair_distribution_limit" INTEGER NOT NULL DEFAULT 100 ,
  "fair_distribution_window" INTEGER NOT NULL DEFAULT 3600 ,
  "enabled" BOOLEAN NOT NULL DEFAULT true ,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "assignment_policies_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."attachments" (
  "id" SERIAL,
  "file_type" INTEGER NULL DEFAULT 0 ,
  "external_url" VARCHAR NULL,
  "coordinates_lat" DOUBLE PRECISION NULL DEFAULT 0.0 ,
  "coordinates_long" DOUBLE PRECISION NULL DEFAULT 0.0 ,
  "message_id" INTEGER NOT NULL,
  "account_id" INTEGER NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "fallback_title" VARCHAR NULL,
  "extension" VARCHAR NULL,
  "meta" JSONB NULL DEFAULT '{}'::jsonb ,
  CONSTRAINT "attachments_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."audits" (
  "id" SERIAL,
  "auditable_id" BIGINT NULL,
  "auditable_type" VARCHAR NULL,
  "associated_id" BIGINT NULL,
  "associated_type" VARCHAR NULL,
  "user_id" BIGINT NULL,
  "user_type" VARCHAR NULL,
  "username" VARCHAR NULL,
  "action" VARCHAR NULL,
  "audited_changes" JSONB NULL,
  "version" INTEGER NULL DEFAULT 0 ,
  "comment" VARCHAR NULL,
  "remote_address" VARCHAR NULL,
  "request_uuid" VARCHAR NULL,
  "created_at" TIMESTAMP NULL,
  CONSTRAINT "audits_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."automation_rules" (
  "id" SERIAL,
  "account_id" BIGINT NOT NULL,
  "name" VARCHAR NOT NULL,
  "description" TEXT NULL,
  "event_name" VARCHAR NOT NULL,
  "conditions" JSONB NOT NULL DEFAULT '"{}"'::jsonb ,
  "actions" JSONB NOT NULL DEFAULT '"{}"'::jsonb ,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "active" BOOLEAN NOT NULL DEFAULT true ,
  CONSTRAINT "automation_rules_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."campaigns" (
  "id" SERIAL,
  "display_id" INTEGER NOT NULL,
  "title" VARCHAR NOT NULL,
  "description" TEXT NULL,
  "message" TEXT NOT NULL,
  "sender_id" INTEGER NULL,
  "enabled" BOOLEAN NULL DEFAULT true ,
  "account_id" BIGINT NOT NULL,
  "inbox_id" BIGINT NOT NULL,
  "trigger_rules" JSONB NULL DEFAULT '{}'::jsonb ,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "campaign_type" INTEGER NOT NULL DEFAULT 0 ,
  "campaign_status" INTEGER NOT NULL DEFAULT 0 ,
  "audience" JSONB NULL DEFAULT '[]'::jsonb ,
  "scheduled_at" TIMESTAMP NULL,
  "trigger_only_during_business_hours" BOOLEAN NULL DEFAULT false ,
  "template_params" JSONB NULL,
  CONSTRAINT "campaigns_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."canned_responses" (
  "id" SERIAL,
  "account_id" INTEGER NOT NULL,
  "short_code" VARCHAR NULL,
  "content" TEXT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "canned_responses_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."captain_assistant_responses" (
  "id" SERIAL,
  "question" VARCHAR NOT NULL,
  "answer" TEXT NOT NULL,
  "embedding" USER-DEFINED NULL,
  "assistant_id" BIGINT NOT NULL,
  "documentable_id" BIGINT NULL,
  "account_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "status" INTEGER NOT NULL DEFAULT 1 ,
  "documentable_type" VARCHAR NULL,
  CONSTRAINT "captain_assistant_responses_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."captain_assistants" (
  "id" SERIAL,
  "name" VARCHAR NOT NULL,
  "account_id" BIGINT NOT NULL,
  "description" VARCHAR NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "config" JSONB NOT NULL DEFAULT '{}'::jsonb ,
  "response_guidelines" JSONB NULL DEFAULT '[]'::jsonb ,
  "guardrails" JSONB NULL DEFAULT '[]'::jsonb ,
  CONSTRAINT "captain_assistants_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."captain_custom_tools" (
  "id" SERIAL,
  "account_id" BIGINT NOT NULL,
  "slug" VARCHAR NOT NULL,
  "title" VARCHAR NOT NULL,
  "description" TEXT NULL,
  "http_method" VARCHAR NOT NULL DEFAULT 'GET'::character varying ,
  "endpoint_url" TEXT NOT NULL,
  "request_template" TEXT NULL,
  "response_template" TEXT NULL,
  "auth_type" VARCHAR NULL DEFAULT 'none'::character varying ,
  "auth_config" JSONB NULL DEFAULT '{}'::jsonb ,
  "param_schema" JSONB NULL DEFAULT '[]'::jsonb ,
  "enabled" BOOLEAN NOT NULL DEFAULT true ,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "captain_custom_tools_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."captain_documents" (
  "id" SERIAL,
  "name" VARCHAR NULL,
  "external_link" VARCHAR NOT NULL,
  "content" TEXT NULL,
  "assistant_id" BIGINT NOT NULL,
  "account_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "status" INTEGER NOT NULL DEFAULT 0 ,
  "metadata" JSONB NULL DEFAULT '{}'::jsonb ,
  CONSTRAINT "captain_documents_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."captain_inboxes" (
  "id" SERIAL,
  "captain_assistant_id" BIGINT NOT NULL,
  "inbox_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "captain_inboxes_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."captain_scenarios" (
  "id" SERIAL,
  "title" VARCHAR NULL,
  "description" TEXT NULL,
  "instruction" TEXT NULL,
  "tools" JSONB NULL DEFAULT '[]'::jsonb ,
  "enabled" BOOLEAN NOT NULL DEFAULT true ,
  "assistant_id" BIGINT NOT NULL,
  "account_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "captain_scenarios_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."categories" (
  "id" SERIAL,
  "account_id" INTEGER NOT NULL,
  "portal_id" INTEGER NOT NULL,
  "name" VARCHAR NULL,
  "description" TEXT NULL,
  "position" INTEGER NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "locale" VARCHAR NULL DEFAULT 'en'::character varying ,
  "slug" VARCHAR NOT NULL,
  "parent_category_id" BIGINT NULL,
  "associated_category_id" BIGINT NULL,
  "icon" VARCHAR NULL DEFAULT ''::character varying ,
  CONSTRAINT "categories_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."channel_api" (
  "id" SERIAL,
  "account_id" INTEGER NOT NULL,
  "webhook_url" VARCHAR NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "identifier" VARCHAR NULL,
  "hmac_token" VARCHAR NULL,
  "hmac_mandatory" BOOLEAN NULL DEFAULT false ,
  "additional_attributes" JSONB NULL DEFAULT '{}'::jsonb ,
  CONSTRAINT "channel_api_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."channel_email" (
  "id" SERIAL,
  "account_id" INTEGER NOT NULL,
  "email" VARCHAR NOT NULL,
  "forward_to_email" VARCHAR NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "imap_enabled" BOOLEAN NULL DEFAULT false ,
  "imap_address" VARCHAR NULL DEFAULT ''::character varying ,
  "imap_port" INTEGER NULL DEFAULT 0 ,
  "imap_login" VARCHAR NULL DEFAULT ''::character varying ,
  "imap_password" VARCHAR NULL DEFAULT ''::character varying ,
  "imap_enable_ssl" BOOLEAN NULL DEFAULT true ,
  "smtp_enabled" BOOLEAN NULL DEFAULT false ,
  "smtp_address" VARCHAR NULL DEFAULT ''::character varying ,
  "smtp_port" INTEGER NULL DEFAULT 0 ,
  "smtp_login" VARCHAR NULL DEFAULT ''::character varying ,
  "smtp_password" VARCHAR NULL DEFAULT ''::character varying ,
  "smtp_domain" VARCHAR NULL DEFAULT ''::character varying ,
  "smtp_enable_starttls_auto" BOOLEAN NULL DEFAULT true ,
  "smtp_authentication" VARCHAR NULL DEFAULT 'login'::character varying ,
  "smtp_openssl_verify_mode" VARCHAR NULL DEFAULT 'none'::character varying ,
  "smtp_enable_ssl_tls" BOOLEAN NULL DEFAULT false ,
  "provider_config" JSONB NULL DEFAULT '{}'::jsonb ,
  "provider" VARCHAR NULL,
  "verified_for_sending" BOOLEAN NOT NULL DEFAULT false ,
  CONSTRAINT "channel_email_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."channel_facebook_pages" (
  "id" SERIAL,
  "page_id" VARCHAR NOT NULL,
  "user_access_token" VARCHAR NOT NULL,
  "page_access_token" VARCHAR NOT NULL,
  "account_id" INTEGER NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "instagram_id" VARCHAR NULL,
  CONSTRAINT "channel_facebook_pages_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."channel_instagram" (
  "id" SERIAL,
  "access_token" VARCHAR NOT NULL,
  "expires_at" TIMESTAMP NOT NULL,
  "account_id" INTEGER NOT NULL,
  "instagram_id" VARCHAR NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "channel_instagram_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."channel_line" (
  "id" SERIAL,
  "account_id" INTEGER NOT NULL,
  "line_channel_id" VARCHAR NOT NULL,
  "line_channel_secret" VARCHAR NOT NULL,
  "line_channel_token" VARCHAR NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "channel_line_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."channel_sms" (
  "id" SERIAL,
  "account_id" INTEGER NOT NULL,
  "phone_number" VARCHAR NOT NULL,
  "provider" VARCHAR NULL DEFAULT 'default'::character varying ,
  "provider_config" JSONB NULL DEFAULT '{}'::jsonb ,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "channel_sms_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."channel_telegram" (
  "id" SERIAL,
  "bot_name" VARCHAR NULL,
  "account_id" INTEGER NOT NULL,
  "bot_token" VARCHAR NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "channel_telegram_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."channel_twilio_sms" (
  "id" SERIAL,
  "phone_number" VARCHAR NULL,
  "auth_token" VARCHAR NOT NULL,
  "account_sid" VARCHAR NOT NULL,
  "account_id" INTEGER NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "medium" INTEGER NULL DEFAULT 0 ,
  "messaging_service_sid" VARCHAR NULL,
  "api_key_sid" VARCHAR NULL,
  "content_templates" JSONB NULL DEFAULT '{}'::jsonb ,
  "content_templates_last_updated" TIMESTAMP NULL,
  CONSTRAINT "channel_twilio_sms_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."channel_twitter_profiles" (
  "id" SERIAL,
  "profile_id" VARCHAR NOT NULL,
  "twitter_access_token" VARCHAR NOT NULL,
  "twitter_access_token_secret" VARCHAR NOT NULL,
  "account_id" INTEGER NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "tweets_enabled" BOOLEAN NULL DEFAULT true ,
  CONSTRAINT "channel_twitter_profiles_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."channel_voice" (
  "id" SERIAL,
  "phone_number" VARCHAR NOT NULL,
  "provider" VARCHAR NOT NULL DEFAULT 'twilio'::character varying ,
  "provider_config" JSONB NOT NULL,
  "account_id" INTEGER NOT NULL,
  "additional_attributes" JSONB NULL DEFAULT '{}'::jsonb ,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "channel_voice_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."channel_web_widgets" (
  "id" SERIAL,
  "website_url" VARCHAR NULL,
  "account_id" INTEGER NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "website_token" VARCHAR NULL,
  "widget_color" VARCHAR NULL DEFAULT '#1f93ff'::character varying ,
  "welcome_title" VARCHAR NULL,
  "welcome_tagline" VARCHAR NULL,
  "feature_flags" INTEGER NOT NULL DEFAULT 7 ,
  "reply_time" INTEGER NULL DEFAULT 0 ,
  "hmac_token" VARCHAR NULL,
  "pre_chat_form_enabled" BOOLEAN NULL DEFAULT false ,
  "pre_chat_form_options" JSONB NULL DEFAULT '{}'::jsonb ,
  "hmac_mandatory" BOOLEAN NULL DEFAULT false ,
  "continuity_via_email" BOOLEAN NOT NULL DEFAULT true ,
  "allowed_domains" TEXT NULL DEFAULT ''::text ,
  CONSTRAINT "channel_web_widgets_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."channel_whatsapp" (
  "id" SERIAL,
  "account_id" INTEGER NOT NULL,
  "phone_number" VARCHAR NOT NULL,
  "provider" VARCHAR NULL DEFAULT 'default'::character varying ,
  "provider_config" JSONB NULL DEFAULT '{}'::jsonb ,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "message_templates" JSONB NULL DEFAULT '{}'::jsonb ,
  "message_templates_last_updated" TIMESTAMP NULL,
  CONSTRAINT "channel_whatsapp_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."companies" (
  "id" SERIAL,
  "name" VARCHAR NOT NULL,
  "domain" VARCHAR NULL,
  "description" TEXT NULL,
  "account_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "companies_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."config" (
  "account_id" INTEGER NOT NULL,
  "name" VARCHAR(255) NOT NULL,
  "description" TEXT NULL,
  "cnpj" VARCHAR(20) NULL,
  "street" VARCHAR(255) NULL,
  "number" VARCHAR(50) NULL,
  "complement" VARCHAR(100) NULL,
  "neighborhood" VARCHAR(100) NULL,
  "city" VARCHAR(100) NULL,
  "state" VARCHAR(50) NULL,
  "postal_code" VARCHAR(20) NULL,
  "country" VARCHAR(100) NULL,
  "created_at" TIMESTAMP WITH TIME ZONE NULL DEFAULT now() ,
  "updated_at" TIMESTAMP WITH TIME ZONE NULL DEFAULT now() ,
  "integrations" JSONB NULL,
  "ai_pipeline_id" INTEGER NULL,
  "ai_stages" ARRAY NULL,
  "currency" VARCHAR(5) NULL DEFAULT 'BRL'::character varying ,
  "ai_id" INTEGER NULL,
  "team_credit_analyst_id" INTEGER NULL,
  "team_seller_id" INTEGER NULL,
  "seller_queue" ARRAY NULL,
  "inbox_id" INTEGER NULL,
  "attributes" JSONB NULL,
  "proposal_template_id" INTEGER NULL,
  "time_zone" VARCHAR(20) NULL DEFAULT 'America/Sao_Paulo'::character varying ,
  "has_scheduling" BOOLEAN NULL DEFAULT false ,
  "time_assessment_id" INTEGER NULL,
  "token_chatwoot" TEXT NULL,
  "team_sdr_id" INTEGER NULL,
  "vehicle_table" VARCHAR(250) NULL,
  "inbox_email_id" INTEGER NULL,
  "token_bot" TEXT NULL,
  "responsible_inactive" INTEGER NULL,
  "whatsapp_grup_id" TEXT NULL,
  "instance_whatsapp" TEXT NULL,
  "transfer_queue" ARRAY NULL,
  "trigger_message_website" VARCHAR(250) NULL,
  "api_openrouter" TEXT NULL,
  "api_openai" TEXT NULL,
  CONSTRAINT "config_pkey" PRIMARY KEY ("account_id")
);
CREATE TABLE "public"."config_credit_analyst" (
  "id" SERIAL,
  "user_id" INTEGER NULL,
  "cached_label_list" TEXT NULL,
  CONSTRAINT "PK_config_credit_analyst" PRIMARY KEY ("id")
);
CREATE TABLE "public"."contact_inboxes" (
  "id" SERIAL,
  "contact_id" BIGINT NULL,
  "inbox_id" BIGINT NULL,
  "source_id" VARCHAR NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "hmac_verified" BOOLEAN NULL DEFAULT false ,
  "pubsub_token" VARCHAR NULL,
  CONSTRAINT "contact_inboxes_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."contacts" (
  "id" SERIAL,
  "name" VARCHAR NULL DEFAULT ''::character varying ,
  "email" VARCHAR NULL,
  "phone_number" VARCHAR NULL,
  "account_id" INTEGER NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "additional_attributes" JSONB NULL DEFAULT '{}'::jsonb ,
  "identifier" VARCHAR NULL,
  "custom_attributes" JSONB NULL DEFAULT '{}'::jsonb ,
  "last_activity_at" TIMESTAMP NULL,
  "contact_type" INTEGER NULL DEFAULT 0 ,
  "middle_name" VARCHAR NULL DEFAULT ''::character varying ,
  "last_name" VARCHAR NULL DEFAULT ''::character varying ,
  "location" VARCHAR NULL DEFAULT ''::character varying ,
  "country_code" VARCHAR NULL DEFAULT ''::character varying ,
  "blocked" BOOLEAN NOT NULL DEFAULT false ,
  "company_id" BIGINT NULL,
  CONSTRAINT "contacts_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."conversation_participants" (
  "id" SERIAL,
  "account_id" BIGINT NOT NULL,
  "user_id" BIGINT NOT NULL,
  "conversation_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "conversation_participants_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."conversations" (
  "id" SERIAL,
  "account_id" INTEGER NOT NULL,
  "inbox_id" INTEGER NOT NULL,
  "status" INTEGER NOT NULL DEFAULT 0 ,
  "assignee_id" INTEGER NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "contact_id" BIGINT NULL,
  "display_id" INTEGER NOT NULL,
  "contact_last_seen_at" TIMESTAMP NULL,
  "agent_last_seen_at" TIMESTAMP NULL,
  "additional_attributes" JSONB NULL DEFAULT '{}'::jsonb ,
  "contact_inbox_id" BIGINT NULL,
  "uuid" UUID NOT NULL DEFAULT gen_random_uuid() ,
  "identifier" VARCHAR NULL,
  "last_activity_at" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ,
  "team_id" BIGINT NULL,
  "campaign_id" BIGINT NULL,
  "snoozed_until" TIMESTAMP NULL,
  "custom_attributes" JSONB NULL DEFAULT '{}'::jsonb ,
  "assignee_last_seen_at" TIMESTAMP NULL,
  "first_reply_created_at" TIMESTAMP NULL,
  "priority" INTEGER NULL,
  "sla_policy_id" BIGINT NULL,
  "waiting_since" TIMESTAMP NULL,
  "cached_label_list" TEXT NULL,
  CONSTRAINT "conversations_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."copilot_messages" (
  "id" SERIAL,
  "copilot_thread_id" BIGINT NOT NULL,
  "account_id" BIGINT NOT NULL,
  "message" JSONB NOT NULL DEFAULT '{}'::jsonb ,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "message_type" INTEGER NULL DEFAULT 0 ,
  CONSTRAINT "copilot_messages_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."copilot_threads" (
  "id" SERIAL,
  "title" VARCHAR NOT NULL,
  "user_id" BIGINT NOT NULL,
  "account_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "assistant_id" INTEGER NULL,
  CONSTRAINT "copilot_threads_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."core_chat_histories" (
  "id" SERIAL,
  "session_id" VARCHAR(255) NOT NULL,
  "message" JSONB NOT NULL,
  CONSTRAINT "core_chat_histories_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."csat_survey_responses" (
  "id" SERIAL,
  "account_id" BIGINT NOT NULL,
  "conversation_id" BIGINT NOT NULL,
  "message_id" BIGINT NOT NULL,
  "rating" INTEGER NOT NULL,
  "feedback_message" TEXT NULL,
  "contact_id" BIGINT NOT NULL,
  "assigned_agent_id" BIGINT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "csat_survey_responses_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."custom_attribute_definitions" (
  "id" SERIAL,
  "attribute_display_name" VARCHAR NULL,
  "attribute_key" VARCHAR NULL,
  "attribute_display_type" INTEGER NULL DEFAULT 0 ,
  "default_value" INTEGER NULL,
  "attribute_model" INTEGER NULL DEFAULT 0 ,
  "account_id" BIGINT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "attribute_description" TEXT NULL,
  "attribute_values" JSONB NULL DEFAULT '[]'::jsonb ,
  "regex_pattern" VARCHAR NULL,
  "regex_cue" VARCHAR NULL,
  CONSTRAINT "custom_attribute_definitions_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."custom_filters" (
  "id" SERIAL,
  "name" VARCHAR NOT NULL,
  "filter_type" INTEGER NOT NULL DEFAULT 0 ,
  "query" JSONB NOT NULL DEFAULT '"{}"'::jsonb ,
  "account_id" BIGINT NOT NULL,
  "user_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "custom_filters_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."custom_roles" (
  "id" SERIAL,
  "name" VARCHAR NULL,
  "description" VARCHAR NULL,
  "account_id" BIGINT NOT NULL,
  "permissions" ARRAY NULL DEFAULT '{}'::text[] ,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "custom_roles_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."dashboard_apps" (
  "id" SERIAL,
  "title" VARCHAR NOT NULL,
  "content" JSONB NULL DEFAULT '[]'::jsonb ,
  "account_id" BIGINT NOT NULL,
  "user_id" BIGINT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "dashboard_apps_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."data_imports" (
  "id" SERIAL,
  "account_id" BIGINT NOT NULL,
  "data_type" VARCHAR NOT NULL,
  "status" INTEGER NOT NULL DEFAULT 0 ,
  "processing_errors" TEXT NULL,
  "total_records" INTEGER NULL,
  "processed_records" INTEGER NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "data_imports_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."deal_activities" (
  "id" SERIAL,
  "deal_id" INTEGER NOT NULL,
  "type" USER-DEFINED NOT NULL,
  "title" VARCHAR(255) NOT NULL,
  "description" TEXT NULL,
  "lead_id" INTEGER NULL,
  "assignee_id" INTEGER NULL,
  "duration_minutes" INTEGER NULL,
  "outcome" USER-DEFINED NULL DEFAULT 'pendente'::activity_outcome_enum ,
  "metadata" JSONB NULL,
  CONSTRAINT "deal_activities_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."deal_closing_checklists" (
  "id" SERIAL,
  "deal_id" INTEGER NOT NULL,
  "has_trade_in" BOOLEAN NOT NULL DEFAULT false ,
  "trade_in_has_debts" BOOLEAN NULL DEFAULT false ,
  "requested_payoff" BOOLEAN NULL DEFAULT false ,
  "received_spare_key" BOOLEAN NOT NULL DEFAULT false ,
  "spare_key_note" TEXT NULL,
  "received_manual" BOOLEAN NOT NULL DEFAULT false ,
  "manual_note" TEXT NULL,
  "created_at" TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ,
  CONSTRAINT "deal_closing_checklists_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "deal_closing_checklists_deal_id_key" UNIQUE ("deal_id")
);
CREATE TABLE "public"."deal_phase" (
  "id" SERIAL,
  "contact_id" INTEGER NULL,
  "deal_id" INTEGER NULL,
  "resume" TEXT NULL,
  "name" TEXT NULL,
  "city" TEXT NULL,
  "body_type" TEXT NULL,
  "investment" VARCHAR(250) NULL,
  "desired_model" VARCHAR(250) NULL,
  "link" BOOLEAN NULL,
  "chosen_model" BOOLEAN NULL,
  "confirmed_appointment" BOOLEAN NULL,
  "title" VARCHAR(250) NULL,
  "source" VARCHAR(250) NULL,
  "selected_vehicle_id" INTEGER NULL,
  "full_payment" VARCHAR(50) NOT NULL DEFAULT 0 ,
  "to_finance" VARCHAR(50) NOT NULL DEFAULT 0 ,
  "trade_in" VARCHAR(50) NOT NULL DEFAULT 0 ,
  "human_transfer" VARCHAR(50) NOT NULL DEFAULT 0 ,
  "appointment" VARCHAR(50) NOT NULL DEFAULT 0 ,
  "vehicle_data" VARCHAR(50) NOT NULL DEFAULT 0 ,
  "vehicle_photos" VARCHAR(50) NOT NULL DEFAULT 0 ,
  "customer_data" VARCHAR(50) NOT NULL DEFAULT 0 ,
  "down_payment" VARCHAR(50) NOT NULL DEFAULT 0 ,
  "phase" INTEGER NULL,
  "next_action" TEXT NULL,
  "payment" TEXT NULL,
  CONSTRAINT "PK_deal_phase" PRIMARY KEY ("id")
);
CREATE TABLE "public"."deal_products" (
  "id" SERIAL,
  "deal_id" INTEGER NOT NULL,
  "product_id" INTEGER NULL,
  "price" NUMERIC NOT NULL,
  "description" TEXT NULL,
  "plate" VARCHAR(20) NULL,
  "title" VARCHAR(250) NULL,
  "promotion_price" NUMERIC NULL,
  "fabric_year" INTEGER NULL,
  "year" INTEGER NULL,
  "mileage" VARCHAR(50) NULL,
  CONSTRAINT "deal_products_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."deal_proposal_items" (
  "id" SERIAL,
  "proposal_id" INTEGER NOT NULL,
  "description" TEXT NOT NULL,
  "amount" NUMERIC NOT NULL DEFAULT 0 ,
  "type" USER-DEFINED NOT NULL,
  CONSTRAINT "deal_proposal_items_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."deal_proposals" (
  "id" SERIAL,
  "deal_id" INTEGER NOT NULL,
  "subtotal" NUMERIC NOT NULL DEFAULT 0 ,
  "discount_total" NUMERIC NOT NULL DEFAULT 0 ,
  "final_value" NUMERIC NOT NULL DEFAULT 0 ,
  "currency" VARCHAR(10) NULL DEFAULT 'BRL'::character varying ,
  "created_at" TIMESTAMP NULL DEFAULT now() ,
  "updated_at" TIMESTAMP NULL DEFAULT now() ,
  CONSTRAINT "deal_proposals_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."deal_registration" (
  "id" SERIAL,
  "deal_id" INTEGER NOT NULL,
  "description" TEXT NULL,
  "created_at" TIMESTAMP NOT NULL DEFAULT now() ,
  "action_type" VARCHAR(100) NOT NULL,
  CONSTRAINT "deal_registration_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."deals" (
  "id" SERIAL,
  "account_id" INTEGER NOT NULL,
  "title" VARCHAR(255) NOT NULL,
  "description" TEXT NULL,
  "value" NUMERIC NULL,
  "currency" VARCHAR(10) NULL DEFAULT 'BRL'::character varying ,
  "stage_id" INTEGER NOT NULL,
  "pipeline_id" INTEGER NOT NULL,
  "contact_id" INTEGER NULL,
  "assignee_id" INTEGER NULL,
  "lost_reason" TEXT NULL,
  "created_at" TIMESTAMP NULL DEFAULT now() ,
  "updated_at" TIMESTAMP NULL DEFAULT now() ,
  "delete_at" TIMESTAMP NULL,
  "delete_user_id" INTEGER NULL,
  "status" VARCHAR(50) NULL DEFAULT 'Captura Fria'::character varying ,
  "score" INTEGER NULL,
  "conversation_id" INTEGER NULL,
  "fase" INTEGER NULL,
  "position" NUMERIC NULL,
  "credit_analyst_id" INTEGER NULL,
  "system_conversations" UUID NULL,
  "source" VARCHAR(250) NULL DEFAULT 'INDEFINIDO'::character varying ,
  "lead_value" NUMERIC NULL,
  "expected_close_date" TIMESTAMP NULL,
  "financial" VARCHAR(250) NULL,
  "returns" INTEGER NULL,
  "source_id" INTEGER NULL DEFAULT 0 ,
  CONSTRAINT "deals_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."documents" (
  "id" SERIAL,
  "content" TEXT NULL,
  "metadata" JSONB NULL,
  "embedding" USER-DEFINED NULL,
  CONSTRAINT "documents_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."email_templates" (
  "id" SERIAL,
  "name" VARCHAR NOT NULL,
  "body" TEXT NOT NULL,
  "account_id" INTEGER NULL,
  "template_type" INTEGER NULL DEFAULT 1 ,
  "locale" INTEGER NOT NULL DEFAULT 0 ,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "email_templates_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."folders" (
  "id" SERIAL,
  "account_id" INTEGER NOT NULL,
  "category_id" INTEGER NOT NULL,
  "name" VARCHAR NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "folders_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."followup_scheduling" (
  "id" SERIAL,
  "account_id" INTEGER NULL,
  "conversation_id" INTEGER NULL,
  "appointment" TIMESTAMP WITH TIME ZONE NULL,
  "followup_position" INTEGER NULL DEFAULT 0 ,
  "status" INTEGER NULL DEFAULT 0 ,
  "contact_id" INTEGER NULL,
  "shipping_time" TIMESTAMP WITH TIME ZONE NULL,
  "display_id" INTEGER NULL,
  "inbox_id" INTEGER NULL,
  CONSTRAINT "PK_followup_scheduling" PRIMARY KEY ("id")
);
CREATE TABLE "public"."inbox_assignment_policies" (
  "id" SERIAL,
  "inbox_id" BIGINT NOT NULL,
  "assignment_policy_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "inbox_assignment_policies_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."inbox_capacity_limits" (
  "id" SERIAL,
  "agent_capacity_policy_id" BIGINT NOT NULL,
  "inbox_id" BIGINT NOT NULL,
  "conversation_limit" INTEGER NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "inbox_capacity_limits_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."inbox_members" (
  "id" SERIAL,
  "user_id" INTEGER NOT NULL,
  "inbox_id" INTEGER NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "inbox_members_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."inboxes" (
  "id" SERIAL,
  "channel_id" INTEGER NOT NULL,
  "account_id" INTEGER NOT NULL,
  "name" VARCHAR NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "channel_type" VARCHAR NULL,
  "enable_auto_assignment" BOOLEAN NULL DEFAULT true ,
  "greeting_enabled" BOOLEAN NULL DEFAULT false ,
  "greeting_message" VARCHAR NULL,
  "email_address" VARCHAR NULL,
  "working_hours_enabled" BOOLEAN NULL DEFAULT false ,
  "out_of_office_message" VARCHAR NULL,
  "timezone" VARCHAR NULL DEFAULT 'UTC'::character varying ,
  "enable_email_collect" BOOLEAN NULL DEFAULT true ,
  "csat_survey_enabled" BOOLEAN NULL DEFAULT false ,
  "allow_messages_after_resolved" BOOLEAN NULL DEFAULT true ,
  "auto_assignment_config" JSONB NULL DEFAULT '{}'::jsonb ,
  "lock_to_single_conversation" BOOLEAN NOT NULL DEFAULT false ,
  "portal_id" BIGINT NULL,
  "sender_name_type" INTEGER NOT NULL DEFAULT 0 ,
  "business_name" VARCHAR NULL,
  "csat_config" JSONB NOT NULL DEFAULT '{}'::jsonb ,
  CONSTRAINT "inboxes_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."installation_configs" (
  "id" SERIAL,
  "name" VARCHAR NOT NULL,
  "serialized_value" JSONB NOT NULL DEFAULT '{}'::jsonb ,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "locked" BOOLEAN NOT NULL DEFAULT true ,
  CONSTRAINT "installation_configs_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."integrations_hooks" (
  "id" SERIAL,
  "status" INTEGER NULL DEFAULT 1 ,
  "inbox_id" INTEGER NULL,
  "account_id" INTEGER NULL,
  "app_id" VARCHAR NULL,
  "hook_type" INTEGER NULL DEFAULT 0 ,
  "reference_id" VARCHAR NULL,
  "access_token" VARCHAR NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "settings" JSONB NULL DEFAULT '{}'::jsonb ,
  CONSTRAINT "integrations_hooks_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."labels" (
  "id" SERIAL,
  "title" VARCHAR NULL,
  "description" TEXT NULL,
  "color" VARCHAR NOT NULL DEFAULT '#1f93ff'::character varying ,
  "show_on_sidebar" BOOLEAN NULL,
  "account_id" BIGINT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "labels_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."leaves" (
  "id" SERIAL,
  "account_id" BIGINT NOT NULL,
  "user_id" BIGINT NOT NULL,
  "start_date" DATE NOT NULL,
  "end_date" DATE NOT NULL,
  "leave_type" INTEGER NOT NULL DEFAULT 0 ,
  "status" INTEGER NOT NULL DEFAULT 0 ,
  "reason" TEXT NULL,
  "approved_by_id" BIGINT NULL,
  "approved_at" TIMESTAMP NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "leaves_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."log_chat" (
  "id" SERIAL,
  "messages_id" INTEGER NOT NULL,
  "conversation_id" INTEGER NOT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now() ,
  "account_id" INTEGER NOT NULL DEFAULT 0 ,
  CONSTRAINT "log_chat_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."macros" (
  "id" SERIAL,
  "account_id" BIGINT NOT NULL,
  "name" VARCHAR NOT NULL,
  "visibility" INTEGER NULL DEFAULT 0 ,
  "created_by_id" BIGINT NULL,
  "updated_by_id" BIGINT NULL,
  "actions" JSONB NOT NULL DEFAULT '{}'::jsonb ,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "macros_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."mentions" (
  "id" SERIAL,
  "user_id" BIGINT NOT NULL,
  "conversation_id" BIGINT NOT NULL,
  "account_id" BIGINT NOT NULL,
  "mentioned_at" TIMESTAMP NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "mentions_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."messages" (
  "id" SERIAL,
  "content" TEXT NULL,
  "account_id" INTEGER NOT NULL,
  "inbox_id" INTEGER NOT NULL,
  "conversation_id" INTEGER NOT NULL,
  "message_type" INTEGER NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "private" BOOLEAN NOT NULL DEFAULT false ,
  "status" INTEGER NULL DEFAULT 0 ,
  "source_id" VARCHAR NULL,
  "content_type" INTEGER NOT NULL DEFAULT 0 ,
  "content_attributes" JSON NULL DEFAULT '{}'::json ,
  "sender_type" VARCHAR NULL,
  "sender_id" BIGINT NULL,
  "external_source_ids" JSONB NULL DEFAULT '{}'::jsonb ,
  "additional_attributes" JSONB NULL DEFAULT '{}'::jsonb ,
  "processed_message_content" TEXT NULL,
  "sentiment" JSONB NULL DEFAULT '{}'::jsonb ,
  "is_scheduled" BOOLEAN NOT NULL DEFAULT false ,
  CONSTRAINT "messages_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."notes" (
  "id" SERIAL,
  "content" TEXT NOT NULL,
  "account_id" BIGINT NOT NULL,
  "contact_id" BIGINT NOT NULL,
  "user_id" BIGINT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "notes_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."notification_settings" (
  "id" SERIAL,
  "account_id" INTEGER NULL,
  "user_id" INTEGER NULL,
  "email_flags" INTEGER NOT NULL DEFAULT 0 ,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "push_flags" INTEGER NOT NULL DEFAULT 0 ,
  CONSTRAINT "notification_settings_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."notification_subscriptions" (
  "id" SERIAL,
  "user_id" BIGINT NOT NULL,
  "subscription_type" INTEGER NOT NULL,
  "subscription_attributes" JSONB NOT NULL DEFAULT '{}'::jsonb ,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "identifier" TEXT NULL,
  CONSTRAINT "notification_subscriptions_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."notifications" (
  "id" SERIAL,
  "account_id" BIGINT NOT NULL,
  "user_id" BIGINT NOT NULL,
  "notification_type" INTEGER NOT NULL,
  "primary_actor_type" VARCHAR NOT NULL,
  "primary_actor_id" BIGINT NOT NULL,
  "secondary_actor_type" VARCHAR NULL,
  "secondary_actor_id" BIGINT NULL,
  "read_at" TIMESTAMP NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "snoozed_until" TIMESTAMP NULL,
  "last_activity_at" TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ,
  "meta" JSONB NULL DEFAULT '{}'::jsonb ,
  CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."ottiv_calendar_item_contacts" (
  "id" SERIAL,
  "ottiv_calendar_item_id" BIGINT NOT NULL,
  "contact_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "ottiv_calendar_item_contacts_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."ottiv_calendar_item_participants" (
  "id" SERIAL,
  "ottiv_calendar_item_id" BIGINT NOT NULL,
  "user_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "ottiv_calendar_item_participants_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."ottiv_calendar_items" (
  "id" SERIAL,
  "item_type" INTEGER NOT NULL DEFAULT 0 ,
  "title" VARCHAR NOT NULL,
  "description" TEXT NULL,
  "start_at" TIMESTAMP NOT NULL,
  "end_at" TIMESTAMP NULL,
  "location" VARCHAR NULL,
  "status" INTEGER NOT NULL DEFAULT 0 ,
  "user_id" BIGINT NOT NULL,
  "account_id" BIGINT NOT NULL,
  "conversation_id" BIGINT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "ottiv_calendar_items_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."ottiv_calls" (
  "id" SERIAL,
  "account_id" BIGINT NOT NULL,
  "provider" VARCHAR NOT NULL,
  "provider_call_id" VARCHAR NOT NULL,
  "conversation_id" BIGINT NULL,
  "user_id" BIGINT NULL,
  "direction" VARCHAR NULL,
  "status" VARCHAR NOT NULL DEFAULT 'open'::character varying ,
  "started_at" TIMESTAMP NULL,
  "ended_at" TIMESTAMP NULL,
  "duration_seconds" INTEGER NULL,
  "metadata" JSONB NOT NULL DEFAULT '{}'::jsonb ,
  "recording_message_id" BIGINT NULL,
  "recording_attachment_id" BIGINT NULL,
  "recording_job_enqueued_at" TIMESTAMP NULL,
  "recording_failure_reason" TEXT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "ottiv_calls_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."ottiv_cost_types" (
  "id" SERIAL,
  "name" VARCHAR NOT NULL,
  "category" INTEGER NOT NULL DEFAULT 0 ,
  "description" TEXT NULL,
  "account_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "ottiv_cost_types_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."ottiv_notification_settings" (
  "id" SERIAL,
  "account_id" INTEGER NULL,
  "user_id" INTEGER NULL,
  "email_flags" INTEGER NOT NULL DEFAULT 0 ,
  "push_flags" INTEGER NOT NULL DEFAULT 0 ,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "ottiv_notification_settings_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."ottiv_notification_subscriptions" (
  "id" SERIAL,
  "user_id" BIGINT NOT NULL,
  "subscription_type" INTEGER NOT NULL,
  "subscription_attributes" JSONB NOT NULL DEFAULT '{}'::jsonb ,
  "identifier" TEXT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "ottiv_notification_subscriptions_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."ottiv_notifications" (
  "id" SERIAL,
  "account_id" BIGINT NOT NULL,
  "user_id" BIGINT NOT NULL,
  "notification_type" INTEGER NOT NULL,
  "primary_actor_type" VARCHAR NOT NULL,
  "primary_actor_id" BIGINT NOT NULL,
  "secondary_actor_type" VARCHAR NULL,
  "secondary_actor_id" BIGINT NULL,
  "read_at" TIMESTAMP NULL,
  "snoozed_until" TIMESTAMP NULL,
  "last_activity_at" TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ,
  "meta" JSONB NULL DEFAULT '{}'::jsonb ,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "ottiv_notifications_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."ottiv_portal_costs" (
  "id" SERIAL,
  "portal_id" BIGINT NOT NULL,
  "cost_type_id" BIGINT NOT NULL,
  "amount" NUMERIC NOT NULL DEFAULT 0.0 ,
  "reference_period_start" DATE NOT NULL,
  "reference_period_end" DATE NOT NULL,
  "description" TEXT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "ottiv_portal_costs_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."ottiv_portals" (
  "id" SERIAL,
  "name" VARCHAR NOT NULL,
  "slug" VARCHAR NOT NULL,
  "source_id" VARCHAR NULL,
  "active" BOOLEAN NOT NULL DEFAULT true ,
  "account_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "ottiv_portals_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."ottiv_reminders" (
  "id" SERIAL,
  "ottiv_calendar_item_id" BIGINT NOT NULL,
  "notify_at" TIMESTAMP NOT NULL,
  "channel" INTEGER NOT NULL DEFAULT 0 ,
  "sent" BOOLEAN NOT NULL DEFAULT false ,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "ottiv_reminders_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."ottiv_scheduled_message_occurrences" (
  "id" SERIAL,
  "ottiv_scheduled_message_id" BIGINT NOT NULL,
  "sent_at" TIMESTAMP NULL,
  "status" INTEGER NOT NULL DEFAULT 0 ,
  "error_message" TEXT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "ottiv_scheduled_message_occurrences_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."ottiv_scheduled_messages" (
  "id" SERIAL,
  "title" VARCHAR NULL,
  "message_type" INTEGER NOT NULL DEFAULT 0 ,
  "content" TEXT NULL,
  "media_url" VARCHAR NULL,
  "audio_url" VARCHAR NULL,
  "quick_reply_id" BIGINT NULL,
  "account_id" BIGINT NOT NULL,
  "conversation_id" BIGINT NULL,
  "contact_id" BIGINT NULL,
  "send_at" TIMESTAMP NOT NULL,
  "timezone" VARCHAR NOT NULL DEFAULT 'UTC'::character varying ,
  "recurrence" INTEGER NOT NULL DEFAULT 0 ,
  "status" INTEGER NOT NULL DEFAULT 0 ,
  "created_by" BIGINT NOT NULL,
  "sent_at" TIMESTAMP NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "ottiv_scheduled_messages_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."ottiv_skill_agents" (
  "id" SERIAL,
  "account_id" BIGINT NOT NULL,
  "skill_id" BIGINT NOT NULL,
  "agent_id" BIGINT NOT NULL,
  "last_assigned_at" TIMESTAMP NULL,
  "active" BOOLEAN NOT NULL DEFAULT true ,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "ottiv_skill_agents_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."ottiv_skills" (
  "id" SERIAL,
  "account_id" BIGINT NOT NULL,
  "type" VARCHAR NOT NULL,
  "name" VARCHAR NOT NULL,
  "active" BOOLEAN NOT NULL DEFAULT true ,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "ottiv_skills_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."ottiv_user_contacts" (
  "id" SERIAL,
  "user_id" BIGINT NOT NULL,
  "contact_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "ottiv_user_contacts_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."pipeline_stages" (
  "id" SERIAL,
  "account_id" INTEGER NOT NULL,
  "pipeline_id" INTEGER NOT NULL,
  "name" VARCHAR(255) NOT NULL,
  "description" TEXT NULL,
  "color" VARCHAR(7) NULL,
  "position" INTEGER NOT NULL,
  "probability" INTEGER NULL,
  "is_final" BOOLEAN NULL DEFAULT false ,
  "deals_count" INTEGER NULL DEFAULT 0 ,
  "total_value" NUMERIC NULL DEFAULT 0 ,
  "created_at" TIMESTAMP NULL DEFAULT now() ,
  "updated_at" TIMESTAMP NULL DEFAULT now() ,
  CONSTRAINT "pipeline_stages_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."pipelines" (
  "id" SERIAL,
  "account_id" INTEGER NOT NULL,
  "name" VARCHAR(255) NOT NULL,
  "description" TEXT NULL,
  "is_active" BOOLEAN NULL DEFAULT true ,
  "created_at" TIMESTAMP WITH TIME ZONE NULL DEFAULT now() ,
  "updated_at" TIMESTAMP WITH TIME ZONE NULL DEFAULT now() ,
  CONSTRAINT "pipelines_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."platform_app_permissibles" (
  "id" SERIAL,
  "platform_app_id" BIGINT NOT NULL,
  "permissible_type" VARCHAR NOT NULL,
  "permissible_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "platform_app_permissibles_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."platform_apps" (
  "id" SERIAL,
  "name" VARCHAR NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "platform_apps_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."portals" (
  "id" SERIAL,
  "account_id" INTEGER NOT NULL,
  "name" VARCHAR NOT NULL,
  "slug" VARCHAR NOT NULL,
  "custom_domain" VARCHAR NULL,
  "color" VARCHAR NULL,
  "homepage_link" VARCHAR NULL,
  "page_title" VARCHAR NULL,
  "header_text" TEXT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "config" JSONB NULL DEFAULT '{"allowed_locales": ["en"]}'::jsonb ,
  "archived" BOOLEAN NULL DEFAULT false ,
  "channel_web_widget_id" BIGINT NULL,
  "ssl_settings" JSONB NOT NULL DEFAULT '{}'::jsonb ,
  CONSTRAINT "portals_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."portals_members" (
  "portal_id" BIGINT NOT NULL,
  "user_id" BIGINT NOT NULL
);
CREATE TABLE "public"."products" (
  "id" SERIAL,
  "account_id" INTEGER NOT NULL,
  "date" DATE NULL,
  "last_update" TIMESTAMP NULL,
  "title" VARCHAR(255) NULL,
  "description" TEXT NULL,
  "price" NUMERIC NULL,
  "promotion_price" NUMERIC NULL,
  "currency" VARCHAR(10) NULL DEFAULT 'BRL'::character varying ,
  "images" ARRAY NULL DEFAULT '{}'::text[] ,
  "images_large" ARRAY NULL DEFAULT '{}'::text[] ,
  "videos" ARRAY NULL DEFAULT '{}'::text[] ,
  "created_at" TIMESTAMP NULL DEFAULT now() ,
  "updated_at" TIMESTAMP NULL DEFAULT now() ,
  "status" USER-DEFINED NOT NULL DEFAULT 'disponivel'::product_status ,
  "delete_at" TIMESTAMP NULL,
  "delete_user_id" INTEGER NULL,
  "vehicle_id" BIGINT NULL,
  "category" VARCHAR(100) NULL,
  "accessories" TEXT NULL,
  "make" VARCHAR(100) NULL,
  "base_model" VARCHAR(100) NULL,
  "body_type" VARCHAR(100) NULL,
  "model" VARCHAR(255) NULL,
  "year" INTEGER NULL,
  "fabric_year" INTEGER NULL,
  "hp" VARCHAR(50) NULL,
  "condition" VARCHAR(50) NULL,
  "mileage" VARCHAR(50) NULL,
  "fuel" VARCHAR(50) NULL,
  "gear" VARCHAR(50) NULL,
  "plate" VARCHAR(20) NULL,
  "doors" INTEGER NULL,
  "color" VARCHAR(50) NULL,
  "seller" VARCHAR(100) NULL,
  "seller_cnpj" VARCHAR(20) NULL,
  "phone" VARCHAR(20) NULL,
  "location_country" VARCHAR(10) NULL,
  "location_state" VARCHAR(100) NULL,
  "location_city" VARCHAR(100) NULL,
  "zip_code" VARCHAR(20) NULL,
  "neighborhood" VARCHAR(100) NULL,
  "location_street" VARCHAR(150) NULL,
  "location_number" VARCHAR(20) NULL,
  "chassi" VARCHAR(50) NULL,
  "motorization" VARCHAR(50) NULL,
  "mvs" VARCHAR(255) NULL,
  "fipe" VARCHAR(50) NULL,
  "pericia" TEXT NULL,
  "destaque" SMALLINT NULL,
  "valor_fipe" NUMERIC NULL,
  "integration" VARCHAR(50) NULL,
  "sold_at" TIMESTAMP NULL,
  "slug" VARCHAR(300) NULL,
  CONSTRAINT "products_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."proposal_template_items" (
  "id" SERIAL,
  "template_id" INTEGER NOT NULL,
  "description" TEXT NOT NULL,
  "default_amount" NUMERIC NOT NULL DEFAULT 0 ,
  "type" USER-DEFINED NOT NULL,
  CONSTRAINT "proposal_template_items_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."proposal_templates" (
  "id" SERIAL,
  "account_id" INTEGER NOT NULL,
  "name" VARCHAR(255) NOT NULL,
  "description" TEXT NULL,
  "created_at" TIMESTAMP NULL DEFAULT now() ,
  "updated_at" TIMESTAMP NULL DEFAULT now() ,
  CONSTRAINT "proposal_templates_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."related_categories" (
  "id" SERIAL,
  "category_id" BIGINT NULL,
  "related_category_id" BIGINT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "related_categories_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."reporting_events" (
  "id" SERIAL,
  "name" VARCHAR NULL,
  "value" DOUBLE PRECISION NULL,
  "account_id" INTEGER NULL,
  "inbox_id" INTEGER NULL,
  "user_id" INTEGER NULL,
  "conversation_id" INTEGER NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "value_in_business_hours" DOUBLE PRECISION NULL,
  "event_start_time" TIMESTAMP NULL,
  "event_end_time" TIMESTAMP NULL,
  CONSTRAINT "reporting_events_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."schema_migrations" (
  "version" VARCHAR NOT NULL,
  CONSTRAINT "schema_migrations_pkey" PRIMARY KEY ("version")
);
CREATE TABLE "public"."service_category" (
  "id" SERIAL,
  "account_id" INTEGER NULL,
  "name" VARCHAR(255) NOT NULL,
  "created_at" TIMESTAMP NULL DEFAULT now() ,
  "updated_at" TIMESTAMP NULL DEFAULT now() ,
  CONSTRAINT "service_category_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."service_media" (
  "id" SERIAL,
  "account_id" INTEGER NOT NULL,
  "service_order_id" INTEGER NOT NULL,
  "photo_url" VARCHAR(500) NULL,
  "description" TEXT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE NULL DEFAULT now() ,
  "updated_at" TIMESTAMP WITH TIME ZONE NULL DEFAULT now() ,
  "type" VARCHAR(20) NULL,
  "url" TEXT NULL,
  CONSTRAINT "service_photos_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."service_notes" (
  "id" SERIAL,
  "account_id" INTEGER NOT NULL,
  "service_order_id" INTEGER NOT NULL,
  "note_text" TEXT NULL,
  "created_by" VARCHAR(255) NULL,
  "created_at" TIMESTAMP WITH TIME ZONE NULL DEFAULT now() ,
  "updated_at" TIMESTAMP WITH TIME ZONE NULL DEFAULT now() ,
  "delete_at" TIMESTAMP NULL,
  "delete_user_id" INTEGER NULL,
  CONSTRAINT "service_notes_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."service_order_attachments" (
  "id" SERIAL,
  "account_id" INTEGER NOT NULL,
  "service_order_id" INTEGER NOT NULL,
  "file_name" VARCHAR(255) NOT NULL,
  "file_url" TEXT NOT NULL,
  "uploaded_by" INTEGER NULL,
  "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now() ,
  "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now() ,
  "deleted_at" TIMESTAMP WITH TIME ZONE NULL,
  CONSTRAINT "service_order_attachments_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."service_orders" (
  "id" SERIAL,
  "account_id" INTEGER NOT NULL,
  "vehicle_id" BIGINT NULL,
  "workshop_id" INTEGER NOT NULL,
  "service_type_id" INTEGER NOT NULL,
  "reported_problem" TEXT NULL,
  "estimated_start_date" DATE NULL,
  "completed_date" DATE NULL,
  "canceled_date" DATE NULL,
  "estimated_end_date" DATE NULL,
  "total_cost" NUMERIC NULL,
  "labor_cost" NUMERIC NULL,
  "parts_cost" NUMERIC NULL,
  "created_by" VARCHAR(255) NULL,
  "created_at" TIMESTAMP WITH TIME ZONE NULL DEFAULT now() ,
  "updated_at" TIMESTAMP WITH TIME ZONE NULL DEFAULT now() ,
  "delete_at" TIMESTAMP NULL,
  "delete_user_id" INTEGER NULL,
  "service_category_id" INTEGER NOT NULL,
  "vehicle_description" TEXT NULL,
  "observation" TEXT NULL,
  "plate" VARCHAR(20) NULL,
  "status" VARCHAR(20) NULL DEFAULT 'open'::character varying ,
  "canceled_info" TEXT NULL,
  "completed_info" TEXT NULL,
  CONSTRAINT "service_orders_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."service_parts" (
  "id" SERIAL,
  "account_id" INTEGER NOT NULL,
  "service_order_id" INTEGER NOT NULL,
  "name" VARCHAR(255) NULL,
  "part_number" VARCHAR(100) NULL,
  "quantity" INTEGER NULL DEFAULT 1 ,
  "unit_price" NUMERIC NULL,
  "total_price" NUMERIC NULL,
  "supplier" VARCHAR(255) NULL,
  "installed_at" TIMESTAMP WITH TIME ZONE NULL,
  "created_at" TIMESTAMP WITH TIME ZONE NULL DEFAULT now() ,
  "updated_at" TIMESTAMP WITH TIME ZONE NULL DEFAULT now() ,
  CONSTRAINT "service_parts_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."service_types" (
  "id" SERIAL,
  "account_id" INTEGER NULL,
  "name" VARCHAR(255) NOT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE NULL DEFAULT now() ,
  "updated_at" TIMESTAMP WITH TIME ZONE NULL DEFAULT now() ,
  CONSTRAINT "service_types_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."sla_events" (
  "id" SERIAL,
  "applied_sla_id" BIGINT NOT NULL,
  "conversation_id" BIGINT NOT NULL,
  "account_id" BIGINT NOT NULL,
  "sla_policy_id" BIGINT NOT NULL,
  "inbox_id" BIGINT NOT NULL,
  "event_type" INTEGER NULL,
  "meta" JSONB NULL DEFAULT '{}'::jsonb ,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "sla_events_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."sla_policies" (
  "id" SERIAL,
  "name" VARCHAR NOT NULL,
  "first_response_time_threshold" DOUBLE PRECISION NULL,
  "next_response_time_threshold" DOUBLE PRECISION NULL,
  "only_during_business_hours" BOOLEAN NULL DEFAULT false ,
  "account_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "description" VARCHAR NULL,
  "resolution_time_threshold" DOUBLE PRECISION NULL,
  CONSTRAINT "sla_policies_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."source" (
  "id" SERIAL,
  "name" VARCHAR(255) NOT NULL,
  CONSTRAINT "sources_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "sources_name_unique" UNIQUE ("name")
);
CREATE TABLE "public"."taggings" (
  "id" SERIAL,
  "tag_id" INTEGER NULL,
  "taggable_type" VARCHAR NULL,
  "taggable_id" INTEGER NULL,
  "tagger_type" VARCHAR NULL,
  "tagger_id" INTEGER NULL,
  "context" VARCHAR(128) NULL,
  "created_at" TIMESTAMP NULL,
  CONSTRAINT "taggings_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."tags" (
  "id" SERIAL,
  "name" VARCHAR NULL,
  "taggings_count" INTEGER NULL DEFAULT 0 ,
  CONSTRAINT "tags_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."team_members" (
  "id" SERIAL,
  "team_id" BIGINT NOT NULL,
  "user_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "team_members_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."teams" (
  "id" SERIAL,
  "name" VARCHAR NOT NULL,
  "description" TEXT NULL,
  "allow_auto_assign" BOOLEAN NULL DEFAULT true ,
  "account_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  CONSTRAINT "teams_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."undefined" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid() ,
  "content" TEXT NULL,
  "metadata" JSONB NULL,
  "embedding" USER-DEFINED NULL,
  CONSTRAINT "undefined_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."users" (
  "id" SERIAL,
  "provider" VARCHAR NOT NULL DEFAULT 'email'::character varying ,
  "uid" VARCHAR NOT NULL DEFAULT ''::character varying ,
  "encrypted_password" VARCHAR NOT NULL DEFAULT ''::character varying ,
  "reset_password_token" VARCHAR NULL,
  "reset_password_sent_at" TIMESTAMP NULL,
  "remember_created_at" TIMESTAMP NULL,
  "sign_in_count" INTEGER NOT NULL DEFAULT 0 ,
  "current_sign_in_at" TIMESTAMP NULL,
  "last_sign_in_at" TIMESTAMP NULL,
  "current_sign_in_ip" VARCHAR NULL,
  "last_sign_in_ip" VARCHAR NULL,
  "confirmation_token" VARCHAR NULL,
  "confirmed_at" TIMESTAMP NULL,
  "confirmation_sent_at" TIMESTAMP NULL,
  "unconfirmed_email" VARCHAR NULL,
  "name" VARCHAR NOT NULL,
  "display_name" VARCHAR NULL,
  "email" VARCHAR NULL,
  "tokens" JSON NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "pubsub_token" VARCHAR NULL,
  "availability" INTEGER NULL DEFAULT 0 ,
  "ui_settings" JSONB NULL DEFAULT '{}'::jsonb ,
  "custom_attributes" JSONB NULL DEFAULT '{}'::jsonb ,
  "type" VARCHAR NULL,
  "message_signature" TEXT NULL,
  "otp_secret" VARCHAR NULL,
  "consumed_timestep" INTEGER NULL,
  "otp_required_for_login" BOOLEAN NOT NULL DEFAULT false ,
  "otp_backup_codes" TEXT NULL,
  CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."vector_federal_car" (
  "id" SERIAL,
  "content" TEXT NULL,
  "metadata" JSONB NULL,
  "embedding" USER-DEFINED NULL,
  CONSTRAINT "vector_federal_car_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."vector_r4_motors" (
  "id" SERIAL,
  "content" TEXT NULL,
  "metadata" JSONB NULL,
  "embedding" USER-DEFINED NULL,
  CONSTRAINT "vector_r4_motors_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."webhooks" (
  "id" SERIAL,
  "account_id" INTEGER NULL,
  "inbox_id" INTEGER NULL,
  "url" VARCHAR NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "webhook_type" INTEGER NULL DEFAULT 0 ,
  "subscriptions" JSONB NULL DEFAULT '["conversation_status_changed", "conversation_updated", "conversation_created", "contact_created", "contact_updated", "message_created", "message_updated", "webwidget_triggered"]'::jsonb ,
  "name" VARCHAR NULL,
  CONSTRAINT "webhooks_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."working_hours" (
  "id" SERIAL,
  "inbox_id" BIGINT NULL,
  "account_id" BIGINT NULL,
  "day_of_week" INTEGER NOT NULL,
  "closed_all_day" BOOLEAN NULL DEFAULT false ,
  "open_hour" INTEGER NULL,
  "open_minutes" INTEGER NULL,
  "close_hour" INTEGER NULL,
  "close_minutes" INTEGER NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "open_all_day" BOOLEAN NULL DEFAULT false ,
  CONSTRAINT "working_hours_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."workshop_notifications" (
  "id" SERIAL,
  "account_id" INTEGER NOT NULL,
  "type" USER-DEFINED NOT NULL,
  "title" VARCHAR(255) NULL,
  "message" TEXT NULL,
  "recipient_id" VARCHAR(255) NULL,
  "service_order_id" INTEGER NULL,
  "is_read" BOOLEAN NULL DEFAULT false ,
  "scheduled_for" TIMESTAMP WITH TIME ZONE NULL,
  "created_at" TIMESTAMP WITH TIME ZONE NULL DEFAULT now() ,
  "updated_at" TIMESTAMP WITH TIME ZONE NULL DEFAULT now() ,
  CONSTRAINT "workshop_notifications_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."workshops" (
  "id" SERIAL,
  "account_id" INTEGER NOT NULL,
  "name" VARCHAR(255) NOT NULL,
  "email" VARCHAR(255) NULL,
  "phone" VARCHAR(50) NULL,
  "hourly_rate" NUMERIC NULL,
  "is_active" BOOLEAN NULL DEFAULT true ,
  "total_services_completed" INTEGER NULL DEFAULT 0 ,
  "average_rating" NUMERIC NULL DEFAULT 0 ,
  "created_at" TIMESTAMP WITH TIME ZONE NULL DEFAULT now() ,
  "updated_at" TIMESTAMP WITH TIME ZONE NULL DEFAULT now() ,
  "delete_at" TIMESTAMP NULL,
  "delete_user_id" INTEGER NULL,
  "responsible_person" VARCHAR(100) NULL,
  "responsible_position" VARCHAR(100) NULL,
  "responsible_phone" VARCHAR(50) NULL,
  "responsible_email" VARCHAR(100) NULL,
  CONSTRAINT "workshops_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "index_access_tokens_on_token"
ON "public"."access_tokens" (
  "token" ASC
);
CREATE INDEX "index_access_tokens_on_owner_type_and_owner_id"
ON "public"."access_tokens" (
  "owner_type" ASC,
  "owner_id" ASC
);
CREATE INDEX "index_account_saml_settings_on_account_id"
ON "public"."account_saml_settings" (
  "account_id" ASC
);
CREATE INDEX "index_account_users_on_user_id"
ON "public"."account_users" (
  "user_id" ASC
);
CREATE UNIQUE INDEX "uniq_user_id_per_account_id"
ON "public"."account_users" (
  "account_id" ASC,
  "user_id" ASC
);
CREATE INDEX "index_account_users_on_custom_role_id"
ON "public"."account_users" (
  "custom_role_id" ASC
);
CREATE INDEX "index_account_users_on_account_id"
ON "public"."account_users" (
  "account_id" ASC
);
CREATE INDEX "index_account_users_on_agent_capacity_policy_id"
ON "public"."account_users" (
  "agent_capacity_policy_id" ASC
);
CREATE INDEX "index_accounts_on_status"
ON "public"."accounts" (
  "status" ASC
);
CREATE UNIQUE INDEX "index_action_mailbox_inbound_emails_uniqueness"
ON "public"."action_mailbox_inbound_emails" (
  "message_id" ASC,
  "message_checksum" ASC
);
CREATE UNIQUE INDEX "index_active_storage_attachments_uniqueness"
ON "public"."active_storage_attachments" (
  "record_type" ASC,
  "record_id" ASC,
  "name" ASC,
  "blob_id" ASC
);
CREATE INDEX "index_active_storage_attachments_on_blob_id"
ON "public"."active_storage_attachments" (
  "blob_id" ASC
);
CREATE UNIQUE INDEX "index_active_storage_blobs_on_key"
ON "public"."active_storage_blobs" (
  "key" ASC
);
CREATE UNIQUE INDEX "index_active_storage_variant_records_uniqueness"
ON "public"."active_storage_variant_records" (
  "blob_id" ASC,
  "variation_digest" ASC
);
CREATE INDEX "index_agent_bots_on_account_id"
ON "public"."agent_bots" (
  "account_id" ASC
);
CREATE INDEX "index_agent_capacity_policies_on_account_id"
ON "public"."agent_capacity_policies" (
  "account_id" ASC
);
CREATE INDEX "index_applied_slas_on_sla_policy_id"
ON "public"."applied_slas" (
  "sla_policy_id" ASC
);
CREATE INDEX "index_applied_slas_on_conversation_id"
ON "public"."applied_slas" (
  "conversation_id" ASC
);
CREATE INDEX "index_applied_slas_on_account_id"
ON "public"."applied_slas" (
  "account_id" ASC
);
CREATE UNIQUE INDEX "index_applied_slas_on_account_sla_policy_conversation"
ON "public"."applied_slas" (
  "account_id" ASC,
  "sla_policy_id" ASC,
  "conversation_id" ASC
);
CREATE INDEX "index_article_embeddings_on_embedding"
ON "public"."article_embeddings" (
  "embedding" ASC
);
CREATE INDEX "index_articles_on_portal_id"
ON "public"."articles" (
  "portal_id" ASC
);
CREATE UNIQUE INDEX "index_articles_on_slug"
ON "public"."articles" (
  "slug" ASC
);
CREATE INDEX "index_articles_on_status"
ON "public"."articles" (
  "status" ASC
);
CREATE INDEX "index_articles_on_views"
ON "public"."articles" (
  "views" ASC
);
CREATE INDEX "index_articles_on_account_id"
ON "public"."articles" (
  "account_id" ASC
);
CREATE INDEX "index_articles_on_author_id"
ON "public"."articles" (
  "author_id" ASC
);
CREATE INDEX "index_articles_on_associated_article_id"
ON "public"."articles" (
  "associated_article_id" ASC
);
CREATE INDEX "index_assignment_policies_on_account_id"
ON "public"."assignment_policies" (
  "account_id" ASC
);
CREATE INDEX "index_assignment_policies_on_enabled"
ON "public"."assignment_policies" (
  "enabled" ASC
);
CREATE UNIQUE INDEX "index_assignment_policies_on_account_id_and_name"
ON "public"."assignment_policies" (
  "account_id" ASC,
  "name" ASC
);
CREATE INDEX "index_attachments_on_account_id"
ON "public"."attachments" (
  "account_id" ASC
);
CREATE INDEX "index_attachments_on_message_id"
ON "public"."attachments" (
  "message_id" ASC
);
CREATE INDEX "index_audits_on_request_uuid"
ON "public"."audits" (
  "request_uuid" ASC
);
CREATE INDEX "user_index"
ON "public"."audits" (
  "user_id" ASC,
  "user_type" ASC
);
CREATE INDEX "auditable_index"
ON "public"."audits" (
  "auditable_type" ASC,
  "auditable_id" ASC,
  "version" ASC
);
CREATE INDEX "associated_index"
ON "public"."audits" (
  "associated_type" ASC,
  "associated_id" ASC
);
CREATE INDEX "index_audits_on_created_at"
ON "public"."audits" (
  "created_at" ASC
);
CREATE INDEX "index_automation_rules_on_account_id"
ON "public"."automation_rules" (
  "account_id" ASC
);
CREATE INDEX "index_campaigns_on_inbox_id"
ON "public"."campaigns" (
  "inbox_id" ASC
);
CREATE INDEX "index_campaigns_on_account_id"
ON "public"."campaigns" (
  "account_id" ASC
);
CREATE INDEX "index_campaigns_on_campaign_status"
ON "public"."campaigns" (
  "campaign_status" ASC
);
CREATE INDEX "index_campaigns_on_campaign_type"
ON "public"."campaigns" (
  "campaign_type" ASC
);
CREATE INDEX "index_campaigns_on_scheduled_at"
ON "public"."campaigns" (
  "scheduled_at" ASC
);
CREATE INDEX "idx_cap_asst_resp_on_documentable"
ON "public"."captain_assistant_responses" (
  "documentable_id" ASC,
  "documentable_type" ASC
);
CREATE INDEX "vector_idx_knowledge_entries_embedding"
ON "public"."captain_assistant_responses" (
  "embedding" ASC
);
CREATE INDEX "index_captain_assistant_responses_on_status"
ON "public"."captain_assistant_responses" (
  "status" ASC
);
CREATE INDEX "index_captain_assistant_responses_on_account_id"
ON "public"."captain_assistant_responses" (
  "account_id" ASC
);
CREATE INDEX "index_captain_assistant_responses_on_assistant_id"
ON "public"."captain_assistant_responses" (
  "assistant_id" ASC
);
CREATE INDEX "index_captain_assistants_on_account_id"
ON "public"."captain_assistants" (
  "account_id" ASC
);
CREATE INDEX "index_captain_custom_tools_on_account_id"
ON "public"."captain_custom_tools" (
  "account_id" ASC
);
CREATE UNIQUE INDEX "index_captain_custom_tools_on_account_id_and_slug"
ON "public"."captain_custom_tools" (
  "account_id" ASC,
  "slug" ASC
);
CREATE INDEX "index_captain_documents_on_account_id"
ON "public"."captain_documents" (
  "account_id" ASC
);
CREATE UNIQUE INDEX "index_captain_documents_on_assistant_id_and_external_link"
ON "public"."captain_documents" (
  "assistant_id" ASC,
  "external_link" ASC
);
CREATE INDEX "index_captain_documents_on_assistant_id"
ON "public"."captain_documents" (
  "assistant_id" ASC
);
CREATE INDEX "index_captain_documents_on_status"
ON "public"."captain_documents" (
  "status" ASC
);
CREATE INDEX "index_captain_inboxes_on_inbox_id"
ON "public"."captain_inboxes" (
  "inbox_id" ASC
);
CREATE UNIQUE INDEX "index_captain_inboxes_on_captain_assistant_id_and_inbox_id"
ON "public"."captain_inboxes" (
  "captain_assistant_id" ASC,
  "inbox_id" ASC
);
CREATE INDEX "index_captain_inboxes_on_captain_assistant_id"
ON "public"."captain_inboxes" (
  "captain_assistant_id" ASC
);
CREATE INDEX "index_captain_scenarios_on_assistant_id_and_enabled"
ON "public"."captain_scenarios" (
  "assistant_id" ASC,
  "enabled" ASC
);
CREATE INDEX "index_captain_scenarios_on_assistant_id"
ON "public"."captain_scenarios" (
  "assistant_id" ASC
);
CREATE INDEX "index_captain_scenarios_on_account_id"
ON "public"."captain_scenarios" (
  "account_id" ASC
);
CREATE INDEX "index_captain_scenarios_on_enabled"
ON "public"."captain_scenarios" (
  "enabled" ASC
);
CREATE INDEX "index_categories_on_locale"
ON "public"."categories" (
  "locale" ASC
);
CREATE UNIQUE INDEX "index_categories_on_slug_and_locale_and_portal_id"
ON "public"."categories" (
  "slug" ASC,
  "locale" ASC,
  "portal_id" ASC
);
CREATE INDEX "index_categories_on_parent_category_id"
ON "public"."categories" (
  "parent_category_id" ASC
);
CREATE INDEX "index_categories_on_locale_and_account_id"
ON "public"."categories" (
  "locale" ASC,
  "account_id" ASC
);
CREATE INDEX "index_categories_on_associated_category_id"
ON "public"."categories" (
  "associated_category_id" ASC
);
CREATE UNIQUE INDEX "index_channel_api_on_identifier"
ON "public"."channel_api" (
  "identifier" ASC
);
CREATE UNIQUE INDEX "index_channel_api_on_hmac_token"
ON "public"."channel_api" (
  "hmac_token" ASC
);
CREATE UNIQUE INDEX "index_channel_email_on_email"
ON "public"."channel_email" (
  "email" ASC
);
CREATE UNIQUE INDEX "index_channel_email_on_forward_to_email"
ON "public"."channel_email" (
  "forward_to_email" ASC
);
CREATE INDEX "index_channel_facebook_pages_on_page_id"
ON "public"."channel_facebook_pages" (
  "page_id" ASC
);
CREATE UNIQUE INDEX "index_channel_facebook_pages_on_page_id_and_account_id"
ON "public"."channel_facebook_pages" (
  "page_id" ASC,
  "account_id" ASC
);
CREATE UNIQUE INDEX "index_channel_instagram_on_instagram_id"
ON "public"."channel_instagram" (
  "instagram_id" ASC
);
CREATE UNIQUE INDEX "index_channel_line_on_line_channel_id"
ON "public"."channel_line" (
  "line_channel_id" ASC
);
CREATE UNIQUE INDEX "index_channel_sms_on_phone_number"
ON "public"."channel_sms" (
  "phone_number" ASC
);
CREATE UNIQUE INDEX "index_channel_telegram_on_bot_token"
ON "public"."channel_telegram" (
  "bot_token" ASC
);
CREATE UNIQUE INDEX "index_channel_twilio_sms_on_messaging_service_sid"
ON "public"."channel_twilio_sms" (
  "messaging_service_sid" ASC
);
CREATE UNIQUE INDEX "index_channel_twilio_sms_on_phone_number"
ON "public"."channel_twilio_sms" (
  "phone_number" ASC
);
CREATE UNIQUE INDEX "index_channel_twilio_sms_on_account_sid_and_phone_number"
ON "public"."channel_twilio_sms" (
  "account_sid" ASC,
  "phone_number" ASC
);
CREATE UNIQUE INDEX "index_channel_twitter_profiles_on_account_id_and_profile_id"
ON "public"."channel_twitter_profiles" (
  "account_id" ASC,
  "profile_id" ASC
);
CREATE INDEX "index_channel_voice_on_account_id"
ON "public"."channel_voice" (
  "account_id" ASC
);
CREATE UNIQUE INDEX "index_channel_voice_on_phone_number"
ON "public"."channel_voice" (
  "phone_number" ASC
);
CREATE UNIQUE INDEX "index_channel_web_widgets_on_hmac_token"
ON "public"."channel_web_widgets" (
  "hmac_token" ASC
);
CREATE UNIQUE INDEX "index_channel_web_widgets_on_website_token"
ON "public"."channel_web_widgets" (
  "website_token" ASC
);
CREATE UNIQUE INDEX "index_channel_whatsapp_on_phone_number"
ON "public"."channel_whatsapp" (
  "phone_number" ASC
);
CREATE INDEX "index_companies_on_name_and_account_id"
ON "public"."companies" (
  "name" ASC,
  "account_id" ASC
);
CREATE UNIQUE INDEX "index_companies_on_account_and_domain"
ON "public"."companies" (
  "account_id" ASC,
  "domain" ASC
);
CREATE INDEX "index_companies_on_account_id"
ON "public"."companies" (
  "account_id" ASC
);
CREATE INDEX "idx_config_integrations_type_stock"
ON "public"."config" (

);
CREATE INDEX "idx_config_integrations_gin"
ON "public"."config" (
  "integrations" ASC
);
CREATE INDEX "idx_config_integrations_gin_full"
ON "public"."config" (
  "integrations" ASC
);
CREATE INDEX "index_contact_inboxes_on_source_id"
ON "public"."contact_inboxes" (
  "source_id" ASC
);
CREATE INDEX "index_contact_inboxes_on_contact_id"
ON "public"."contact_inboxes" (
  "contact_id" ASC
);
CREATE UNIQUE INDEX "index_contact_inboxes_on_inbox_id_and_source_id"
ON "public"."contact_inboxes" (
  "inbox_id" ASC,
  "source_id" ASC
);
CREATE INDEX "index_contact_inboxes_on_inbox_id"
ON "public"."contact_inboxes" (
  "inbox_id" ASC
);
CREATE UNIQUE INDEX "index_contact_inboxes_on_pubsub_token"
ON "public"."contact_inboxes" (
  "pubsub_token" ASC
);
CREATE INDEX "index_contacts_on_phone_digits_trgm"
ON "public"."contacts" (

);
CREATE INDEX "index_contacts_on_lower_email_account_id"
ON "public"."contacts" (
  "account_id" ASC
);
CREATE INDEX "index_contacts_on_nonempty_fields"
ON "public"."contacts" (
  "account_id" ASC,
  "email" ASC,
  "phone_number" ASC,
  "identifier" ASC
);
CREATE INDEX "index_contacts_on_account_id_and_last_activity_at"
ON "public"."contacts" (
  "account_id" ASC,
  "last_activity_at" DESC
);
CREATE INDEX "index_contacts_on_account_id"
ON "public"."contacts" (
  "account_id" ASC
);
CREATE INDEX "index_resolved_contact_account_id"
ON "public"."contacts" (
  "account_id" ASC
);
CREATE INDEX "index_contacts_on_blocked"
ON "public"."contacts" (
  "blocked" ASC
);
CREATE UNIQUE INDEX "uniq_email_per_account_contact"
ON "public"."contacts" (
  "email" ASC,
  "account_id" ASC
);
CREATE UNIQUE INDEX "uniq_identifier_per_account_contact"
ON "public"."contacts" (
  "identifier" ASC,
  "account_id" ASC
);
CREATE INDEX "index_contacts_on_name_email_phone_number_identifier"
ON "public"."contacts" (
  "name" ASC,
  "email" ASC,
  "phone_number" ASC,
  "identifier" ASC
);
CREATE INDEX "index_contacts_on_phone_number_and_account_id"
ON "public"."contacts" (
  "phone_number" ASC,
  "account_id" ASC
);
CREATE INDEX "index_contacts_on_account_id_and_contact_type"
ON "public"."contacts" (
  "account_id" ASC,
  "contact_type" ASC
);
CREATE INDEX "index_contacts_on_company_id"
ON "public"."contacts" (
  "company_id" ASC
);
CREATE INDEX "index_contacts_on_name_trgm_unaccent"
ON "public"."contacts" (

);
CREATE INDEX "index_conversation_participants_on_account_id"
ON "public"."conversation_participants" (
  "account_id" ASC
);
CREATE INDEX "index_conversation_participants_on_user_id"
ON "public"."conversation_participants" (
  "user_id" ASC
);
CREATE UNIQUE INDEX "index_conversation_participants_on_user_id_and_conversation_id"
ON "public"."conversation_participants" (
  "user_id" ASC,
  "conversation_id" ASC
);
CREATE INDEX "index_conversation_participants_on_conversation_id"
ON "public"."conversation_participants" (
  "conversation_id" ASC
);
CREATE INDEX "index_conversations_on_status_and_account_id"
ON "public"."conversations" (
  "status" ASC,
  "account_id" ASC
);
CREATE INDEX "index_conversations_on_contact_id"
ON "public"."conversations" (
  "contact_id" ASC
);
CREATE INDEX "index_conversations_on_campaign_id"
ON "public"."conversations" (
  "campaign_id" ASC
);
CREATE INDEX "index_conversations_on_assignee_id_and_account_id"
ON "public"."conversations" (
  "assignee_id" ASC,
  "account_id" ASC
);
CREATE INDEX "index_conversations_on_account_id"
ON "public"."conversations" (
  "account_id" ASC
);
CREATE INDEX "conv_acid_inbid_stat_asgnid_idx"
ON "public"."conversations" (
  "account_id" ASC,
  "inbox_id" ASC,
  "status" ASC,
  "assignee_id" ASC
);
CREATE INDEX "index_conversations_on_id_and_account_id"
ON "public"."conversations" (
  "account_id" ASC,
  "id" ASC
);
CREATE UNIQUE INDEX "index_conversations_on_account_id_and_display_id"
ON "public"."conversations" (
  "account_id" ASC,
  "display_id" ASC
);
CREATE INDEX "index_conversations_on_first_reply_created_at"
ON "public"."conversations" (
  "first_reply_created_at" ASC
);
CREATE INDEX "index_conversations_on_contact_inbox_id"
ON "public"."conversations" (
  "contact_inbox_id" ASC
);
CREATE INDEX "index_conversations_on_inbox_id"
ON "public"."conversations" (
  "inbox_id" ASC
);
CREATE INDEX "index_conversations_on_priority"
ON "public"."conversations" (
  "priority" ASC
);
CREATE INDEX "index_conversations_on_account_assignee_activity"
ON "public"."conversations" (
  "account_id" ASC,
  "assignee_id" ASC,
  "last_activity_at" DESC
);
CREATE INDEX "index_conversations_on_account_status_activity"
ON "public"."conversations" (
  "account_id" ASC,
  "status" ASC,
  "last_activity_at" DESC
);
CREATE INDEX "index_conversations_unassigned_by_activity"
ON "public"."conversations" (
  "account_id" ASC,
  "last_activity_at" DESC
);
CREATE INDEX "index_conversations_on_account_inbox_activity"
ON "public"."conversations" (
  "account_id" ASC,
  "inbox_id" ASC,
  "last_activity_at" DESC
);
CREATE INDEX "index_conversations_on_account_contact_activity"
ON "public"."conversations" (
  "account_id" ASC,
  "contact_id" ASC,
  "last_activity_at" DESC
);
CREATE INDEX "index_conversations_on_waiting_since"
ON "public"."conversations" (
  "waiting_since" ASC
);
CREATE UNIQUE INDEX "index_conversations_on_uuid"
ON "public"."conversations" (
  "uuid" ASC
);
CREATE INDEX "index_conversations_on_status_and_priority"
ON "public"."conversations" (
  "status" ASC,
  "priority" ASC
);
CREATE INDEX "index_conversations_on_team_id"
ON "public"."conversations" (
  "team_id" ASC
);
CREATE INDEX "index_conversations_on_identifier_and_account_id"
ON "public"."conversations" (
  "identifier" ASC,
  "account_id" ASC
);
CREATE INDEX "index_copilot_messages_on_copilot_thread_id"
ON "public"."copilot_messages" (
  "copilot_thread_id" ASC
);
CREATE INDEX "index_copilot_messages_on_account_id"
ON "public"."copilot_messages" (
  "account_id" ASC
);
CREATE INDEX "index_copilot_threads_on_account_id"
ON "public"."copilot_threads" (
  "account_id" ASC
);
CREATE INDEX "index_copilot_threads_on_user_id"
ON "public"."copilot_threads" (
  "user_id" ASC
);
CREATE INDEX "index_copilot_threads_on_assistant_id"
ON "public"."copilot_threads" (
  "assistant_id" ASC
);
CREATE INDEX "index_csat_survey_responses_on_conversation_id"
ON "public"."csat_survey_responses" (
  "conversation_id" ASC
);
CREATE INDEX "index_csat_survey_responses_on_contact_id"
ON "public"."csat_survey_responses" (
  "contact_id" ASC
);
CREATE INDEX "index_csat_survey_responses_on_assigned_agent_id"
ON "public"."csat_survey_responses" (
  "assigned_agent_id" ASC
);
CREATE UNIQUE INDEX "index_csat_survey_responses_on_message_id"
ON "public"."csat_survey_responses" (
  "message_id" ASC
);
CREATE INDEX "index_csat_survey_responses_on_account_id"
ON "public"."csat_survey_responses" (
  "account_id" ASC
);
CREATE UNIQUE INDEX "attribute_key_model_index"
ON "public"."custom_attribute_definitions" (
  "attribute_key" ASC,
  "attribute_model" ASC,
  "account_id" ASC
);
CREATE INDEX "index_custom_attribute_definitions_on_account_id"
ON "public"."custom_attribute_definitions" (
  "account_id" ASC
);
CREATE INDEX "index_custom_filters_on_account_id"
ON "public"."custom_filters" (
  "account_id" ASC
);
CREATE INDEX "index_custom_filters_on_user_id"
ON "public"."custom_filters" (
  "user_id" ASC
);
CREATE INDEX "index_custom_roles_on_account_id"
ON "public"."custom_roles" (
  "account_id" ASC
);
CREATE INDEX "index_dashboard_apps_on_user_id"
ON "public"."dashboard_apps" (
  "user_id" ASC
);
CREATE INDEX "index_dashboard_apps_on_account_id"
ON "public"."dashboard_apps" (
  "account_id" ASC
);
CREATE INDEX "index_data_imports_on_account_id"
ON "public"."data_imports" (
  "account_id" ASC
);
CREATE INDEX "idx_deal_registration_deal_id"
ON "public"."deal_registration" (
  "deal_id" ASC
);
CREATE INDEX "idx_deals_account_id"
ON "public"."deals" (
  "account_id" ASC
);
CREATE INDEX "idx_deals_stage_position"
ON "public"."deals" (
  "stage_id" ASC,
  "position" DESC
);
CREATE INDEX "idx_deals_stage_id"
ON "public"."deals" (
  "stage_id" ASC
);
CREATE INDEX "idx_deals_pipeline_id"
ON "public"."deals" (
  "pipeline_id" ASC
);
CREATE INDEX "idx_deals_contact_id"
ON "public"."deals" (
  "contact_id" ASC
);
CREATE INDEX "idx_deals_assignee_id"
ON "public"."deals" (
  "assignee_id" ASC
);
CREATE UNIQUE INDEX "index_email_templates_on_name_and_account_id"
ON "public"."email_templates" (
  "name" ASC,
  "account_id" ASC
);
CREATE INDEX "index_inbox_assignment_policies_on_assignment_policy_id"
ON "public"."inbox_assignment_policies" (
  "assignment_policy_id" ASC
);
CREATE UNIQUE INDEX "index_inbox_assignment_policies_on_inbox_id"
ON "public"."inbox_assignment_policies" (
  "inbox_id" ASC
);
CREATE UNIQUE INDEX "idx_on_agent_capacity_policy_id_inbox_id_71c7ec4caf"
ON "public"."inbox_capacity_limits" (
  "agent_capacity_policy_id" ASC,
  "inbox_id" ASC
);
CREATE INDEX "index_inbox_capacity_limits_on_agent_capacity_policy_id"
ON "public"."inbox_capacity_limits" (
  "agent_capacity_policy_id" ASC
);
CREATE INDEX "index_inbox_capacity_limits_on_inbox_id"
ON "public"."inbox_capacity_limits" (
  "inbox_id" ASC
);
CREATE UNIQUE INDEX "index_inbox_members_on_inbox_id_and_user_id"
ON "public"."inbox_members" (
  "inbox_id" ASC,
  "user_id" ASC
);
CREATE INDEX "index_inbox_members_on_inbox_id"
ON "public"."inbox_members" (
  "inbox_id" ASC
);
CREATE INDEX "index_inboxes_on_account_id"
ON "public"."inboxes" (
  "account_id" ASC
);
CREATE INDEX "index_inboxes_on_portal_id"
ON "public"."inboxes" (
  "portal_id" ASC
);
CREATE INDEX "index_inboxes_on_channel_id_and_channel_type"
ON "public"."inboxes" (
  "channel_id" ASC,
  "channel_type" ASC
);
CREATE UNIQUE INDEX "index_installation_configs_on_name_and_created_at"
ON "public"."installation_configs" (
  "name" ASC,
  "created_at" ASC
);
CREATE UNIQUE INDEX "index_installation_configs_on_name"
ON "public"."installation_configs" (
  "name" ASC
);
CREATE UNIQUE INDEX "index_labels_on_title_and_account_id"
ON "public"."labels" (
  "title" ASC,
  "account_id" ASC
);
CREATE INDEX "index_labels_on_account_id"
ON "public"."labels" (
  "account_id" ASC
);
CREATE INDEX "index_leaves_on_approved_by_id"
ON "public"."leaves" (
  "approved_by_id" ASC
);
CREATE INDEX "index_leaves_on_account_id"
ON "public"."leaves" (
  "account_id" ASC
);
CREATE INDEX "index_leaves_on_user_id"
ON "public"."leaves" (
  "user_id" ASC
);
CREATE INDEX "index_leaves_on_account_id_and_status"
ON "public"."leaves" (
  "account_id" ASC,
  "status" ASC
);
CREATE INDEX "idx_log_chat_conversation_id"
ON "public"."log_chat" (
  "conversation_id" ASC
);
CREATE INDEX "idx_log_chat_created_at"
ON "public"."log_chat" (
  "created_at" ASC
);
CREATE INDEX "idx_log_chat_messages_id"
ON "public"."log_chat" (
  "messages_id" ASC
);
CREATE INDEX "index_macros_on_account_id"
ON "public"."macros" (
  "account_id" ASC
);
CREATE INDEX "index_mentions_on_user_id"
ON "public"."mentions" (
  "user_id" ASC
);
CREATE UNIQUE INDEX "index_mentions_on_user_id_and_conversation_id"
ON "public"."mentions" (
  "user_id" ASC,
  "conversation_id" ASC
);
CREATE INDEX "index_mentions_on_conversation_id"
ON "public"."mentions" (
  "conversation_id" ASC
);
CREATE INDEX "index_mentions_on_account_id"
ON "public"."mentions" (
  "account_id" ASC
);
CREATE INDEX "index_messages_on_additional_attributes_campaign_id"
ON "public"."messages" (

);
CREATE INDEX "index_messages_on_created_at"
ON "public"."messages" (
  "created_at" ASC
);
CREATE INDEX "index_messages_on_conversation_id_desc_non_activity"
ON "public"."messages" (
  "conversation_id" ASC,
  "id" DESC
);
CREATE INDEX "index_messages_on_conversation_id"
ON "public"."messages" (
  "conversation_id" ASC
);
CREATE INDEX "index_messages_on_conversation_account_type_created"
ON "public"."messages" (
  "conversation_id" ASC,
  "account_id" ASC,
  "message_type" ASC,
  "created_at" ASC
);
CREATE INDEX "index_messages_on_content"
ON "public"."messages" (
  "content" ASC
);
CREATE INDEX "index_messages_on_account_id"
ON "public"."messages" (
  "account_id" ASC
);
CREATE INDEX "index_messages_on_account_id_and_inbox_id"
ON "public"."messages" (
  "account_id" ASC,
  "inbox_id" ASC
);
CREATE INDEX "idx_messages_account_scheduled_created"
ON "public"."messages" (
  "account_id" ASC,
  "is_scheduled" ASC,
  "created_at" ASC
);
CREATE INDEX "index_messages_on_account_created_type"
ON "public"."messages" (
  "account_id" ASC,
  "created_at" ASC,
  "message_type" ASC
);
CREATE INDEX "index_messages_on_content_trgm_unaccent"
ON "public"."messages" (

);
CREATE INDEX "idx_messages_account_content_created"
ON "public"."messages" (
  "account_id" ASC,
  "content_type" ASC,
  "created_at" ASC
);
CREATE INDEX "index_messages_on_inbox_id"
ON "public"."messages" (
  "inbox_id" ASC
);
CREATE INDEX "index_messages_on_sender_type_and_sender_id"
ON "public"."messages" (
  "sender_type" ASC,
  "sender_id" ASC
);
CREATE INDEX "index_messages_on_source_id"
ON "public"."messages" (
  "source_id" ASC
);
CREATE INDEX "index_notes_on_account_id"
ON "public"."notes" (
  "account_id" ASC
);
CREATE INDEX "index_notes_on_contact_id"
ON "public"."notes" (
  "contact_id" ASC
);
CREATE INDEX "index_notes_on_user_id"
ON "public"."notes" (
  "user_id" ASC
);
CREATE UNIQUE INDEX "by_account_user"
ON "public"."notification_settings" (
  "account_id" ASC,
  "user_id" ASC
);
CREATE INDEX "index_notification_subscriptions_on_user_id"
ON "public"."notification_subscriptions" (
  "user_id" ASC
);
CREATE UNIQUE INDEX "index_notification_subscriptions_on_identifier"
ON "public"."notification_subscriptions" (
  "identifier" ASC
);
CREATE INDEX "idx_notifications_performance"
ON "public"."notifications" (
  "user_id" ASC,
  "account_id" ASC,
  "snoozed_until" ASC,
  "read_at" ASC
);
CREATE INDEX "uniq_secondary_actor_per_account_notifications"
ON "public"."notifications" (
  "secondary_actor_type" ASC,
  "secondary_actor_id" ASC
);
CREATE INDEX "index_notifications_on_user_id"
ON "public"."notifications" (
  "user_id" ASC
);
CREATE INDEX "index_notifications_on_account_id"
ON "public"."notifications" (
  "account_id" ASC
);
CREATE INDEX "index_notifications_on_last_activity_at"
ON "public"."notifications" (
  "last_activity_at" ASC
);
CREATE INDEX "uniq_primary_actor_per_account_notifications"
ON "public"."notifications" (
  "primary_actor_type" ASC,
  "primary_actor_id" ASC
);
CREATE UNIQUE INDEX "idx_calendar_item_contacts_unique"
ON "public"."ottiv_calendar_item_contacts" (
  "ottiv_calendar_item_id" ASC,
  "contact_id" ASC
);
CREATE UNIQUE INDEX "idx_calendar_item_participants_unique"
ON "public"."ottiv_calendar_item_participants" (
  "ottiv_calendar_item_id" ASC,
  "user_id" ASC
);
CREATE INDEX "idx_ottiv_calendar_items_account_user_start"
ON "public"."ottiv_calendar_items" (
  "account_id" ASC,
  "user_id" ASC,
  "start_at" ASC
);
CREATE INDEX "idx_ottiv_calendar_items_status_start"
ON "public"."ottiv_calendar_items" (
  "status" ASC,
  "start_at" ASC
);
CREATE INDEX "idx_ottiv_calendar_items_conversation"
ON "public"."ottiv_calendar_items" (
  "conversation_id" ASC
);
CREATE INDEX "index_ottiv_calls_on_user_id"
ON "public"."ottiv_calls" (
  "user_id" ASC
);
CREATE INDEX "index_ottiv_calls_on_conversation_id"
ON "public"."ottiv_calls" (
  "conversation_id" ASC
);
CREATE INDEX "index_ottiv_calls_on_account_id_and_status"
ON "public"."ottiv_calls" (
  "account_id" ASC,
  "status" ASC
);
CREATE UNIQUE INDEX "index_ottiv_calls_on_account_provider_call"
ON "public"."ottiv_calls" (
  "account_id" ASC,
  "provider" ASC,
  "provider_call_id" ASC
);
CREATE INDEX "index_ottiv_calls_on_account_id"
ON "public"."ottiv_calls" (
  "account_id" ASC
);
CREATE INDEX "index_ottiv_calls_on_recording_message_id"
ON "public"."ottiv_calls" (
  "recording_message_id" ASC
);
CREATE UNIQUE INDEX "index_ottiv_cost_types_on_account_id_and_name"
ON "public"."ottiv_cost_types" (
  "account_id" ASC,
  "name" ASC
);
CREATE INDEX "index_ottiv_cost_types_on_account_id"
ON "public"."ottiv_cost_types" (
  "account_id" ASC
);
CREATE INDEX "index_ottiv_cost_types_on_category"
ON "public"."ottiv_cost_types" (
  "category" ASC
);
CREATE UNIQUE INDEX "by_account_user_ottiv"
ON "public"."ottiv_notification_settings" (
  "account_id" ASC,
  "user_id" ASC
);
CREATE INDEX "index_ottiv_notification_subscriptions_on_user_id"
ON "public"."ottiv_notification_subscriptions" (
  "user_id" ASC
);
CREATE UNIQUE INDEX "index_ottiv_notification_subscriptions_on_identifier"
ON "public"."ottiv_notification_subscriptions" (
  "identifier" ASC
);
CREATE INDEX "uniq_primary_actor_per_account_ottiv_notifications"
ON "public"."ottiv_notifications" (
  "primary_actor_type" ASC,
  "primary_actor_id" ASC
);
CREATE INDEX "index_ottiv_notifications_on_account_id"
ON "public"."ottiv_notifications" (
  "account_id" ASC
);
CREATE INDEX "index_ottiv_notifications_on_user_id"
ON "public"."ottiv_notifications" (
  "user_id" ASC
);
CREATE INDEX "index_ottiv_notifications_on_last_activity_at"
ON "public"."ottiv_notifications" (
  "last_activity_at" ASC
);
CREATE INDEX "uniq_secondary_actor_per_account_ottiv_notifications"
ON "public"."ottiv_notifications" (
  "secondary_actor_type" ASC,
  "secondary_actor_id" ASC
);
CREATE INDEX "idx_ottiv_notifications_performance"
ON "public"."ottiv_notifications" (
  "user_id" ASC,
  "account_id" ASC,
  "snoozed_until" ASC,
  "read_at" ASC
);
CREATE INDEX "index_ottiv_portal_costs_on_reference_period_end"
ON "public"."ottiv_portal_costs" (
  "reference_period_end" ASC
);
CREATE INDEX "index_ottiv_portal_costs_on_cost_type_id"
ON "public"."ottiv_portal_costs" (
  "cost_type_id" ASC
);
CREATE INDEX "index_ottiv_portal_costs_on_reference_period_start"
ON "public"."ottiv_portal_costs" (
  "reference_period_start" ASC
);
CREATE INDEX "index_ottiv_portal_costs_on_portal_and_period"
ON "public"."ottiv_portal_costs" (
  "portal_id" ASC,
  "reference_period_start" ASC,
  "reference_period_end" ASC
);
CREATE INDEX "index_ottiv_portal_costs_on_portal_id"
ON "public"."ottiv_portal_costs" (
  "portal_id" ASC
);
CREATE INDEX "index_ottiv_portals_on_account_id"
ON "public"."ottiv_portals" (
  "account_id" ASC
);
CREATE UNIQUE INDEX "index_ottiv_portals_on_account_id_and_slug"
ON "public"."ottiv_portals" (
  "account_id" ASC,
  "slug" ASC
);
CREATE INDEX "index_ottiv_portals_on_active"
ON "public"."ottiv_portals" (
  "active" ASC
);
CREATE INDEX "idx_ottiv_reminders_sent_notify"
ON "public"."ottiv_reminders" (
  "sent" ASC,
  "notify_at" ASC
);
CREATE INDEX "idx_ottiv_reminders_calendar_item"
ON "public"."ottiv_reminders" (
  "ottiv_calendar_item_id" ASC
);
CREATE INDEX "idx_ottiv_sched_msg_occ_message"
ON "public"."ottiv_scheduled_message_occurrences" (
  "ottiv_scheduled_message_id" ASC
);
CREATE INDEX "idx_ottiv_scheduled_messages_creator"
ON "public"."ottiv_scheduled_messages" (
  "created_by" ASC
);
CREATE INDEX "idx_ottiv_scheduled_messages_account_conv"
ON "public"."ottiv_scheduled_messages" (
  "account_id" ASC,
  "conversation_id" ASC
);
CREATE INDEX "idx_ottiv_scheduled_messages_status_send"
ON "public"."ottiv_scheduled_messages" (
  "status" ASC,
  "send_at" ASC
);
CREATE INDEX "idx_ottiv_skill_agents_lru_lookup"
ON "public"."ottiv_skill_agents" (
  "account_id" ASC,
  "skill_id" ASC,
  "active" ASC,
  "last_assigned_at" ASC
);
CREATE INDEX "index_ottiv_skill_agents_on_account_id"
ON "public"."ottiv_skill_agents" (
  "account_id" ASC
);
CREATE INDEX "index_ottiv_skill_agents_on_agent_id"
ON "public"."ottiv_skill_agents" (
  "agent_id" ASC
);
CREATE INDEX "index_ottiv_skill_agents_on_skill_id"
ON "public"."ottiv_skill_agents" (
  "skill_id" ASC
);
CREATE UNIQUE INDEX "idx_ottiv_skill_agents_account_skill_agent"
ON "public"."ottiv_skill_agents" (
  "account_id" ASC,
  "skill_id" ASC,
  "agent_id" ASC
);
CREATE INDEX "index_ottiv_skills_on_account_id"
ON "public"."ottiv_skills" (
  "account_id" ASC
);
CREATE UNIQUE INDEX "idx_ottiv_skills_account_type_name"
ON "public"."ottiv_skills" (
  "account_id" ASC,
  "type" ASC,
  "name" ASC
);
CREATE UNIQUE INDEX "index_ottiv_user_contacts_on_user_id"
ON "public"."ottiv_user_contacts" (
  "user_id" ASC
);
CREATE INDEX "index_ottiv_user_contacts_on_contact_id"
ON "public"."ottiv_user_contacts" (
  "contact_id" ASC
);
CREATE INDEX "idx_pipeline_stages_pipeline_id"
ON "public"."pipeline_stages" (
  "pipeline_id" ASC
);
CREATE INDEX "idx_pipeline_stages_account_id"
ON "public"."pipeline_stages" (
  "account_id" ASC
);
CREATE INDEX "index_platform_app_permissibles_on_platform_app_id"
ON "public"."platform_app_permissibles" (
  "platform_app_id" ASC
);
CREATE INDEX "index_platform_app_permissibles_on_permissibles"
ON "public"."platform_app_permissibles" (
  "permissible_type" ASC,
  "permissible_id" ASC
);
CREATE UNIQUE INDEX "unique_permissibles_index"
ON "public"."platform_app_permissibles" (
  "platform_app_id" ASC,
  "permissible_id" ASC,
  "permissible_type" ASC
);
CREATE UNIQUE INDEX "index_portals_on_slug"
ON "public"."portals" (
  "slug" ASC
);
CREATE UNIQUE INDEX "index_portals_on_custom_domain"
ON "public"."portals" (
  "custom_domain" ASC
);
CREATE INDEX "index_portals_on_channel_web_widget_id"
ON "public"."portals" (
  "channel_web_widget_id" ASC
);
CREATE INDEX "index_portals_members_on_user_id"
ON "public"."portals_members" (
  "user_id" ASC
);
CREATE INDEX "index_portals_members_on_portal_id"
ON "public"."portals_members" (
  "portal_id" ASC
);
CREATE UNIQUE INDEX "index_portals_members_on_portal_id_and_user_id"
ON "public"."portals_members" (
  "portal_id" ASC,
  "user_id" ASC
);
CREATE INDEX "idx_products_status"
ON "public"."products" (
  "status" ASC
);
CREATE UNIQUE INDEX "idx_products_slug_unique"
ON "public"."products" (
  "slug" ASC
);
CREATE INDEX "idx_products_account_id"
ON "public"."products" (
  "account_id" ASC
);
CREATE UNIQUE INDEX "index_related_categories_on_related_category_id_and_category_id"
ON "public"."related_categories" (
  "related_category_id" ASC,
  "category_id" ASC
);
CREATE UNIQUE INDEX "index_related_categories_on_category_id_and_related_category_id"
ON "public"."related_categories" (
  "category_id" ASC,
  "related_category_id" ASC
);
CREATE INDEX "index_reporting_events_on_user_id"
ON "public"."reporting_events" (
  "user_id" ASC
);
CREATE INDEX "index_reporting_events_on_name"
ON "public"."reporting_events" (
  "name" ASC
);
CREATE INDEX "index_reporting_events_on_inbox_id"
ON "public"."reporting_events" (
  "inbox_id" ASC
);
CREATE INDEX "index_reporting_events_on_created_at"
ON "public"."reporting_events" (
  "created_at" ASC
);
CREATE INDEX "index_reporting_events_on_conversation_id"
ON "public"."reporting_events" (
  "conversation_id" ASC
);
CREATE INDEX "index_reporting_events_on_account_id"
ON "public"."reporting_events" (
  "account_id" ASC
);
CREATE INDEX "reporting_events__account_id__name__created_at"
ON "public"."reporting_events" (
  "account_id" ASC,
  "name" ASC,
  "created_at" ASC
);
CREATE INDEX "idx_service_photos_account"
ON "public"."service_media" (
  "account_id" ASC
);
CREATE INDEX "idx_service_notes_account"
ON "public"."service_notes" (
  "account_id" ASC
);
CREATE INDEX "idx_service_orders_vehicle"
ON "public"."service_orders" (
  "vehicle_id" ASC
);
CREATE INDEX "idx_service_orders_workshop"
ON "public"."service_orders" (
  "workshop_id" ASC
);
CREATE INDEX "idx_service_orders_account"
ON "public"."service_orders" (
  "account_id" ASC
);
CREATE INDEX "idx_service_parts_account"
ON "public"."service_parts" (
  "account_id" ASC
);
CREATE INDEX "idx_service_types_account"
ON "public"."service_types" (
  "account_id" ASC
);
CREATE INDEX "index_sla_events_on_inbox_id"
ON "public"."sla_events" (
  "inbox_id" ASC
);
CREATE INDEX "index_sla_events_on_applied_sla_id"
ON "public"."sla_events" (
  "applied_sla_id" ASC
);
CREATE INDEX "index_sla_events_on_sla_policy_id"
ON "public"."sla_events" (
  "sla_policy_id" ASC
);
CREATE INDEX "index_sla_events_on_conversation_id"
ON "public"."sla_events" (
  "conversation_id" ASC
);
CREATE INDEX "index_sla_events_on_account_id"
ON "public"."sla_events" (
  "account_id" ASC
);
CREATE INDEX "index_sla_policies_on_account_id"
ON "public"."sla_policies" (
  "account_id" ASC
);
CREATE INDEX "index_taggings_on_context"
ON "public"."taggings" (
  "context" ASC
);
CREATE INDEX "index_taggings_on_taggable_type"
ON "public"."taggings" (
  "taggable_type" ASC
);
CREATE INDEX "index_taggings_on_tagger_id_and_tagger_type"
ON "public"."taggings" (
  "tagger_id" ASC,
  "tagger_type" ASC
);
CREATE INDEX "index_taggings_on_tagger_id"
ON "public"."taggings" (
  "tagger_id" ASC
);
CREATE UNIQUE INDEX "taggings_idx"
ON "public"."taggings" (
  "tag_id" ASC,
  "taggable_id" ASC,
  "taggable_type" ASC,
  "context" ASC,
  "tagger_id" ASC,
  "tagger_type" ASC
);
CREATE INDEX "index_taggings_on_tag_id"
ON "public"."taggings" (
  "tag_id" ASC
);
CREATE INDEX "index_taggings_on_taggable_id_and_taggable_type_and_context"
ON "public"."taggings" (
  "taggable_id" ASC,
  "taggable_type" ASC,
  "context" ASC
);
CREATE INDEX "taggings_idy"
ON "public"."taggings" (
  "taggable_id" ASC,
  "taggable_type" ASC,
  "tagger_id" ASC,
  "context" ASC
);
CREATE INDEX "index_taggings_on_taggable_id"
ON "public"."taggings" (
  "taggable_id" ASC
);
CREATE INDEX "tags_name_trgm_idx"
ON "public"."tags" (

);
CREATE UNIQUE INDEX "index_tags_on_name"
ON "public"."tags" (
  "name" ASC
);
CREATE UNIQUE INDEX "index_team_members_on_team_id_and_user_id"
ON "public"."team_members" (
  "team_id" ASC,
  "user_id" ASC
);
CREATE INDEX "index_team_members_on_team_id"
ON "public"."team_members" (
  "team_id" ASC
);
CREATE INDEX "index_team_members_on_user_id"
ON "public"."team_members" (
  "user_id" ASC
);
CREATE INDEX "index_teams_on_account_id"
ON "public"."teams" (
  "account_id" ASC
);
CREATE UNIQUE INDEX "index_teams_on_name_and_account_id"
ON "public"."teams" (
  "name" ASC,
  "account_id" ASC
);
CREATE UNIQUE INDEX "index_users_on_otp_secret"
ON "public"."users" (
  "otp_secret" ASC
);
CREATE INDEX "index_users_on_otp_required_for_login"
ON "public"."users" (
  "otp_required_for_login" ASC
);
CREATE INDEX "index_users_on_email"
ON "public"."users" (
  "email" ASC
);
CREATE UNIQUE INDEX "index_users_on_pubsub_token"
ON "public"."users" (
  "pubsub_token" ASC
);
CREATE UNIQUE INDEX "index_users_on_uid_and_provider"
ON "public"."users" (
  "uid" ASC,
  "provider" ASC
);
CREATE UNIQUE INDEX "index_users_on_reset_password_token"
ON "public"."users" (
  "reset_password_token" ASC
);
CREATE UNIQUE INDEX "index_webhooks_on_account_id_and_url"
ON "public"."webhooks" (
  "account_id" ASC,
  "url" ASC
);
CREATE INDEX "index_working_hours_on_inbox_id"
ON "public"."working_hours" (
  "inbox_id" ASC
);
CREATE INDEX "index_working_hours_on_account_id"
ON "public"."working_hours" (
  "account_id" ASC
);
CREATE INDEX "idx_notifications_account"
ON "public"."workshop_notifications" (
  "account_id" ASC
);
CREATE INDEX "idx_workshops_account"
ON "public"."workshops" (
  "account_id" ASC
);
CREATE INDEX "idx_workshops_active"
ON "public"."workshops" (
  "is_active" ASC
);
ALTER TABLE "public"."active_storage_attachments" ADD CONSTRAINT "fk_rails_c3b3935057" FOREIGN KEY ("blob_id") REFERENCES "public"."active_storage_blobs" ("id");
ALTER TABLE "public"."active_storage_variant_records" ADD CONSTRAINT "fk_rails_993965df05" FOREIGN KEY ("blob_id") REFERENCES "public"."active_storage_blobs" ("id");
ALTER TABLE "public"."deal_activities" ADD CONSTRAINT "deal_activities_assignee_id_fkey" FOREIGN KEY ("assignee_id") REFERENCES "public"."users" ("id");
ALTER TABLE "public"."deal_activities" ADD CONSTRAINT "deal_activities_deal_id_fkey" FOREIGN KEY ("deal_id") REFERENCES "public"."deals" ("id");
ALTER TABLE "public"."deal_closing_checklists" ADD CONSTRAINT "deal_closing_checklists_deal_id_fkey" FOREIGN KEY ("deal_id") REFERENCES "public"."deals" ("id");
ALTER TABLE "public"."deal_products" ADD CONSTRAINT "deal_products_deal_id_fkey" FOREIGN KEY ("deal_id") REFERENCES "public"."deals" ("id");
ALTER TABLE "public"."deal_proposal_items" ADD CONSTRAINT "deal_proposal_items_proposal_id_fkey" FOREIGN KEY ("proposal_id") REFERENCES "public"."deal_proposals" ("id");
ALTER TABLE "public"."deal_proposals" ADD CONSTRAINT "deal_proposals_deal_id_fkey" FOREIGN KEY ("deal_id") REFERENCES "public"."deals" ("id");
ALTER TABLE "public"."deal_registration" ADD CONSTRAINT "deal_registration_deal_id_fkey" FOREIGN KEY ("deal_id") REFERENCES "public"."deals" ("id");
ALTER TABLE "public"."deals" ADD CONSTRAINT "fk_stage" FOREIGN KEY ("stage_id") REFERENCES "public"."pipeline_stages" ("id");
ALTER TABLE "public"."deals" ADD CONSTRAINT "fk_pipeline" FOREIGN KEY ("pipeline_id") REFERENCES "public"."pipelines" ("id");
ALTER TABLE "public"."deals" ADD CONSTRAINT "fk_user" FOREIGN KEY ("assignee_id") REFERENCES "public"."users" ("id");
ALTER TABLE "public"."deals" ADD CONSTRAINT "fk_contact" FOREIGN KEY ("contact_id") REFERENCES "public"."contacts" ("id");
ALTER TABLE "public"."inboxes" ADD CONSTRAINT "fk_rails_a1f654bf2d" FOREIGN KEY ("portal_id") REFERENCES "public"."portals" ("id");
ALTER TABLE "public"."log_chat" ADD CONSTRAINT "log_chat_messages_fk" FOREIGN KEY ("messages_id") REFERENCES "public"."messages" ("id");
ALTER TABLE "public"."ottiv_calendar_item_contacts" ADD CONSTRAINT "fk_rails_dd0fda35f1" FOREIGN KEY ("ottiv_calendar_item_id") REFERENCES "public"."ottiv_calendar_items" ("id");
ALTER TABLE "public"."ottiv_calendar_item_contacts" ADD CONSTRAINT "fk_rails_e0672d2ac4" FOREIGN KEY ("contact_id") REFERENCES "public"."contacts" ("id");
ALTER TABLE "public"."ottiv_calendar_item_participants" ADD CONSTRAINT "fk_rails_6dc3b6235a" FOREIGN KEY ("ottiv_calendar_item_id") REFERENCES "public"."ottiv_calendar_items" ("id");
ALTER TABLE "public"."ottiv_calendar_item_participants" ADD CONSTRAINT "fk_rails_8d8d774143" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id");
ALTER TABLE "public"."ottiv_calendar_items" ADD CONSTRAINT "fk_rails_6232f51625" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id");
ALTER TABLE "public"."ottiv_calendar_items" ADD CONSTRAINT "fk_rails_6cb78a3f08" FOREIGN KEY ("account_id") REFERENCES "public"."accounts" ("id");
ALTER TABLE "public"."ottiv_calendar_items" ADD CONSTRAINT "fk_rails_8609a52e25" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations" ("id");
ALTER TABLE "public"."ottiv_calls" ADD CONSTRAINT "fk_rails_66e3042715" FOREIGN KEY ("account_id") REFERENCES "public"."accounts" ("id");
ALTER TABLE "public"."ottiv_calls" ADD CONSTRAINT "fk_rails_2c0d02a286" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations" ("id");
ALTER TABLE "public"."ottiv_calls" ADD CONSTRAINT "fk_rails_c9ae5007f7" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id");
ALTER TABLE "public"."ottiv_calls" ADD CONSTRAINT "fk_rails_cc077d636e" FOREIGN KEY ("recording_message_id") REFERENCES "public"."messages" ("id");
ALTER TABLE "public"."ottiv_calls" ADD CONSTRAINT "fk_rails_46920faf6b" FOREIGN KEY ("recording_attachment_id") REFERENCES "public"."attachments" ("id");
ALTER TABLE "public"."ottiv_cost_types" ADD CONSTRAINT "fk_rails_e752976f79" FOREIGN KEY ("account_id") REFERENCES "public"."accounts" ("id");
ALTER TABLE "public"."ottiv_notification_settings" ADD CONSTRAINT "fk_rails_dd3ad17f99" FOREIGN KEY ("account_id") REFERENCES "public"."accounts" ("id");
ALTER TABLE "public"."ottiv_notification_settings" ADD CONSTRAINT "fk_rails_eb91db3971" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id");
ALTER TABLE "public"."ottiv_notification_subscriptions" ADD CONSTRAINT "fk_rails_9990825d6e" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id");
ALTER TABLE "public"."ottiv_notifications" ADD CONSTRAINT "fk_rails_54e34fa6d8" FOREIGN KEY ("account_id") REFERENCES "public"."accounts" ("id");
ALTER TABLE "public"."ottiv_notifications" ADD CONSTRAINT "fk_rails_6eae1a89c6" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id");
ALTER TABLE "public"."ottiv_portal_costs" ADD CONSTRAINT "fk_rails_e2755bb7bc" FOREIGN KEY ("portal_id") REFERENCES "public"."ottiv_portals" ("id");
ALTER TABLE "public"."ottiv_portal_costs" ADD CONSTRAINT "fk_rails_d29c3fa02e" FOREIGN KEY ("cost_type_id") REFERENCES "public"."ottiv_cost_types" ("id");
ALTER TABLE "public"."ottiv_portals" ADD CONSTRAINT "fk_rails_629edac0d5" FOREIGN KEY ("account_id") REFERENCES "public"."accounts" ("id");
ALTER TABLE "public"."ottiv_reminders" ADD CONSTRAINT "fk_rails_31da048171" FOREIGN KEY ("ottiv_calendar_item_id") REFERENCES "public"."ottiv_calendar_items" ("id");
ALTER TABLE "public"."ottiv_scheduled_message_occurrences" ADD CONSTRAINT "fk_rails_233a635a96" FOREIGN KEY ("ottiv_scheduled_message_id") REFERENCES "public"."ottiv_scheduled_messages" ("id");
ALTER TABLE "public"."ottiv_scheduled_messages" ADD CONSTRAINT "fk_rails_0e1503e8e0" FOREIGN KEY ("account_id") REFERENCES "public"."accounts" ("id");
ALTER TABLE "public"."ottiv_scheduled_messages" ADD CONSTRAINT "fk_rails_1eb9678f73" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations" ("id");
ALTER TABLE "public"."ottiv_scheduled_messages" ADD CONSTRAINT "fk_rails_cc3e11293d" FOREIGN KEY ("contact_id") REFERENCES "public"."contacts" ("id");
ALTER TABLE "public"."ottiv_scheduled_messages" ADD CONSTRAINT "fk_rails_b41ccb98dd" FOREIGN KEY ("created_by") REFERENCES "public"."users" ("id");
ALTER TABLE "public"."ottiv_skill_agents" ADD CONSTRAINT "fk_rails_8ac692a1f8" FOREIGN KEY ("account_id") REFERENCES "public"."accounts" ("id");
ALTER TABLE "public"."ottiv_skill_agents" ADD CONSTRAINT "fk_rails_9912ae0047" FOREIGN KEY ("skill_id") REFERENCES "public"."ottiv_skills" ("id");
ALTER TABLE "public"."ottiv_skill_agents" ADD CONSTRAINT "fk_rails_20fd85da65" FOREIGN KEY ("agent_id") REFERENCES "public"."users" ("id");
ALTER TABLE "public"."ottiv_skills" ADD CONSTRAINT "fk_rails_15cae1e092" FOREIGN KEY ("account_id") REFERENCES "public"."accounts" ("id");
ALTER TABLE "public"."ottiv_user_contacts" ADD CONSTRAINT "fk_rails_7ba72448e3" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id");
ALTER TABLE "public"."ottiv_user_contacts" ADD CONSTRAINT "fk_rails_ce633dddff" FOREIGN KEY ("contact_id") REFERENCES "public"."contacts" ("id");
ALTER TABLE "public"."pipelines" ADD CONSTRAINT "pipelines_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "public"."accounts" ("id");
ALTER TABLE "public"."proposal_template_items" ADD CONSTRAINT "proposal_template_items_template_id_fkey" FOREIGN KEY ("template_id") REFERENCES "public"."proposal_templates" ("id");
ALTER TABLE "public"."service_media" ADD CONSTRAINT "service_photos_service_order_id_fkey" FOREIGN KEY ("service_order_id") REFERENCES "public"."service_orders" ("id");
ALTER TABLE "public"."service_notes" ADD CONSTRAINT "service_notes_service_order_id_fkey" FOREIGN KEY ("service_order_id") REFERENCES "public"."service_orders" ("id");
ALTER TABLE "public"."service_order_attachments" ADD CONSTRAINT "fk_soa_service_order" FOREIGN KEY ("service_order_id") REFERENCES "public"."service_orders" ("id");
ALTER TABLE "public"."service_orders" ADD CONSTRAINT "service_orders_workshop_id_fkey" FOREIGN KEY ("workshop_id") REFERENCES "public"."workshops" ("id");
ALTER TABLE "public"."service_orders" ADD CONSTRAINT "service_orders_service_type_id_fkey" FOREIGN KEY ("service_type_id") REFERENCES "public"."service_types" ("id");
ALTER TABLE "public"."service_orders" ADD CONSTRAINT "service_orders_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "public"."products" ("id");
ALTER TABLE "public"."service_orders" ADD CONSTRAINT "service_orders_service_category_id_fkey" FOREIGN KEY ("service_category_id") REFERENCES "public"."service_category" ("id");
ALTER TABLE "public"."service_orders" ADD CONSTRAINT "fk_service_category" FOREIGN KEY ("service_category_id") REFERENCES "public"."service_category" ("id");
ALTER TABLE "public"."service_parts" ADD CONSTRAINT "service_parts_service_order_id_fkey" FOREIGN KEY ("service_order_id") REFERENCES "public"."service_orders" ("id");
ALTER TABLE "public"."workshop_notifications" ADD CONSTRAINT "workshop_notifications_service_order_id_fkey" FOREIGN KEY ("service_order_id") REFERENCES "public"."service_orders" ("id");
