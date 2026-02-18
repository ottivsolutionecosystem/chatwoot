---
name: Reorganizar Ottiv para estrutura Core/Analytics
overview: Reorganizar todos os arquivos Ottiv existentes para a nova estrutura `app/ottiv/core/` e criar estrutura base para `app/ottiv/analytics/`. Atualizar namespaces, rotas, jobs com prefixos e Redis keys.
todos:
  - id: create-folder-structure
    content: Criar estrutura de pastas app/ottiv/core/ e app/ottiv/analytics/ com todas as subpastas necessárias
    status: completed
  - id: move-controllers
    content: Mover e renomear todos os controllers Ottiv para app/ottiv/core/controllers/ com novos namespaces
    status: completed
    dependencies:
      - create-folder-structure
  - id: move-services
    content: Mover e renomear todos os services Ottiv para app/ottiv/core/services/ com novos namespaces
    status: completed
    dependencies:
      - create-folder-structure
  - id: move-queries
    content: Mover finder Ottiv para app/ottiv/core/queries/ com novo namespace
    status: completed
    dependencies:
      - create-folder-structure
  - id: move-jobs
    content: Mover jobs Ottiv para app/ottiv/core/jobs/ com novos namespaces e prefixos de queue
    status: completed
    dependencies:
      - create-folder-structure
  - id: move-concerns
    content: Mover concern Ottiv para app/ottiv/core/concerns/ com novo namespace
    status: completed
    dependencies:
      - create-folder-structure
  - id: update-controller-references
    content: Atualizar referências de services e queries dentro dos controllers movidos
    status: completed
    dependencies:
      - move-controllers
      - move-services
      - move-queries
  - id: update-routes
    content: Atualizar config/routes.rb com novos paths dos controllers Ottiv
    status: completed
    dependencies:
      - move-controllers
  - id: update-schedule
    content: Atualizar config/schedule.yml com novo namespace do job e queue prefixado
    status: completed
    dependencies:
      - move-jobs
  - id: create-redis-keys
    content: Criar módulo app/ottiv/core/concerns/redis_keys.rb com namespace para chaves Redis
    status: completed
    dependencies:
      - create-folder-structure
  - id: create-analytics-structure
    content: Criar estrutura de pastas e arquivos placeholder para analytics (ainda não implementado)
    status: completed
    dependencies:
      - create-folder-structure
  - id: configure-autoloading
    content: Configurar autoloading em config/application.rb para app/ottiv
    status: completed
    dependencies:
      - create-folder-structure
---

# Reorganização Ottiv: Estrutura

Core/Analytics

## Objetivo

Reorganizar todos os arquivos Ottiv existentes para `app/ottiv/core/` e preparar estrutura para `app/ottiv/analytics/` (ainda não implementado).

## Estrutura Final

```javascript
app/
└── ottiv/
    ├── core/
    │   ├── controllers/
    │   │   └── api/
    │   │       └── v1/
    │   │           ├── accounts/
    │   │           ├── conversations/
    │   │           ├── notifications/
    │   │           └── ...
    │   ├── services/
    │   ├── queries/
    │   ├── serializers/
    │   ├── jobs/
    │   └── concerns/
    │
    └── analytics/
        ├── controllers/
        │   └── api/
        │       └── v1/
        ├── services/
        ├── queries/
        ├── serializers/
        └── jobs/
```



## Mapeamento de Arquivos

### Controllers → `app/ottiv/core/controllers/`

**API V1 Accounts (15 controllers):**

- `app/controllers/api/v1/accounts/ottiv_*_controller.rb` → `app/ottiv/core/controllers/api/v1/accounts/*_controller.rb`
- `ottiv_search_controller.rb` → `search_controller.rb`
- `ottiv_conversations_controller.rb` → `conversations_controller.rb`
- `ottiv_calendar_items_controller.rb` → `calendar_items_controller.rb`
- `ottiv_scheduled_messages_controller.rb` → `scheduled_messages_controller.rb`
- `ottiv_reminders_controller.rb` → `reminders_controller.rb`
- `ottiv_portals_controller.rb` → `portals_controller.rb`
- `ottiv_portals_dashboard_controller.rb` → `portals_dashboard_controller.rb`
- `ottiv_cost_types_controller.rb` → `cost_types_controller.rb`
- `ottiv_portal_costs_controller.rb` → `portal_costs_controller.rb`
- `ottiv_deals_controller.rb` → `deals_controller.rb`
- `ottiv_deal_phases_controller.rb` → `deal_phases_controller.rb`
- `ottiv_sellers_controller.rb` → `sellers_controller.rb`
- `ottiv_mentions_controller.rb` → `mentions_controller.rb`
- `ottiv_notifications_controller.rb` → `notifications_controller.rb`
- `ottiv_notification_settings_controller.rb` → `notification_settings_controller.rb`
- `ottiv_user_contacts_controller.rb` → `user_contacts_controller.rb`
- `ottiv_config_controller.rb` → `config_controller.rb`

**API V1 Conversations:**

- `app/controllers/api/v1/accounts/conversations/ottiv_messages_controller.rb` → `app/ottiv/core/controllers/api/v1/conversations/messages_controller.rb`

**API V1 Global (sem account scope):**

- `app/controllers/api/v1/ottiv_scheduled_messages_controller.rb` → `app/ottiv/core/controllers/api/v1/scheduled_messages_controller.rb`
- `app/controllers/api/v1/ottiv_reminders_controller.rb` → `app/ottiv/core/controllers/api/v1/reminders_controller.rb`
- `app/controllers/api/v1/ottiv_notification_subscriptions_controller.rb` → `app/ottiv/core/controllers/api/v1/notification_subscriptions_controller.rb`

**API Ottiv:**

- `app/controllers/api/ottiv/ottiv_configs_controller.rb` → `app/ottiv/core/controllers/api/ottiv/configs_controller.rb`

**Platform API:**

- `app/controllers/platform/api/v1/ottiv_notification_settings_controller.rb` → `app/ottiv/core/controllers/platform/api/v1/notification_settings_controller.rb`

### Services → `app/ottiv/core/services/`

- `app/services/ottiv_search_service.rb` → `app/ottiv/core/services/search_service.rb`
- `app/services/ottiv_calendar_items/*` → `app/ottiv/core/services/calendar_items/*`
- `create_service.rb`
- `update_service.rb`
- `complete_service.rb`
- `cancel_service.rb`
- `app/services/ottiv_scheduled_messages/*` → `app/ottiv/core/services/scheduled_messages/*`
- `create_service.rb`
- `send_service.rb`

### Queries → `app/ottiv/core/queries/`

- `app/finders/ottiv_conversation_finder.rb` → `app/ottiv/core/queries/conversation_finder.rb`

### Serializers → `app/ottiv/core/serializers/`

- `app/views/api/v1/conversations/partials/_ottiv_conversation_list_item.json.jbuilder` → `app/ottiv/core/serializers/conversation_list_item_serializer.rb` (ou manter como jbuilder em `app/views/ottiv/core/...`)

### Jobs → `app/ottiv/core/jobs/`

- `app/jobs/ottiv_complete_past_items_job.rb` → `app/ottiv/core/jobs/complete_past_items_job.rb`
- `app/jobs/ottiv_notify_participants_job.rb` → `app/ottiv/core/jobs/notify_participants_job.rb`

### Concerns → `app/ottiv/core/concerns/`

- `app/models/concerns/ottiv_conversation_helpers.rb` → `app/ottiv/core/concerns/conversation_helpers.rb`

## Atualizações Necessárias

### 1. Namespaces dos Controllers

**Antes:**

```ruby
class Api::V1::Accounts::OttivSearchController < Api::V1::Accounts::BaseController
```

**Depois:**

```ruby
module Ottiv
  module Core
    module Controllers
      module Api
        module V1
          module Accounts
            class SearchController < Api::V1::Accounts::BaseController
```



### 2. Namespaces dos Services

**Antes:**

```ruby
class OttivSearchService
class OttivCalendarItems::CreateService
```

**Depois:**

```ruby
module Ottiv
  module Core
    module Services
      class SearchService
      module CalendarItems
        class CreateService
```



### 3. Namespaces dos Jobs

**Antes:**

```ruby
class OttivCompletePastItemsJob < ApplicationJob
  queue_as :low
```

**Depois:**

```ruby
module Ottiv
  module Core
    module Jobs
      class CompletePastItemsJob < ApplicationJob
        queue_as :ottiv_core_low
```



### 4. Namespaces dos Queries

**Antes:**

```ruby
class OttivConversationFinder < ConversationFinder
```

**Depois:**

```ruby
module Ottiv
  module Core
    module Queries
      class ConversationFinder < ConversationFinder
```



### 5. Namespaces dos Concerns

**Antes:**

```ruby
module OttivConversationHelpers
```

**Depois:**

```ruby
module Ottiv
  module Core
    module Concerns
      module ConversationHelpers
```



### 6. Atualizar Rotas em `config/routes.rb`

Atualizar todas as referências de controllers Ottiv para usar os novos paths:

```ruby
namespace :api, defaults: { format: 'json' } do
  namespace :ottiv do
    get 'config-find', to: 'ottiv/core/controllers/api/ottiv/configs#find'
  end

  namespace :v1 do
    resources :accounts do
      scope module: :accounts do
        namespace :ottiv do
          # Usar controller: 'ottiv/core/controllers/api/v1/accounts/...'
          resources :search, only: [] do
            collection do
              post :index
              get :index
            end
          end
          # ... outras rotas ...
        end
      end
    end
  end
end
```



### 7. Atualizar `config/schedule.yml`

```yaml
ottiv_complete_past_items_job:
  cron: '*/30 * * * *'
  class: 'Ottiv::Core::Jobs::CompletePastItemsJob'
  queue: ottiv_core_scheduled_jobs
```



### 8. Atualizar Referências nos Controllers

Atualizar chamadas de services e finders:**Antes:**

```ruby
OttivSearchService.new(...)
OttivConversationFinder.new(...)
OttivCalendarItems::CreateService.new(...)
```

**Depois:**

```ruby
Ottiv::Core::Services::SearchService.new(...)
Ottiv::Core::Queries::ConversationFinder.new(...)
Ottiv::Core::Services::CalendarItems::CreateService.new(...)
```



### 9. Atualizar Models (Account, User, Contact)

Manter models em `app/models/` mas atualizar referências de classes:

- `app/models/account.rb` - manter associações `has_many :ottiv_*`
- `app/models/user.rb` - manter associações `has_many :ottiv_*`
- `app/models/contact.rb` - manter associação `has_one :ottiv_user_contact`

### 10. Criar Estrutura Analytics (Vazia)

Criar estrutura de pastas para analytics (sem implementação ainda):

```javascript
app/ottiv/analytics/
├── controllers/
│   └── api/
│       └── v1/
│           ├── dashboard_controller.rb (placeholder)
│           ├── agents_controller.rb (placeholder)
│           ├── inboxes_controller.rb (placeholder)
│           └── conversations_controller.rb (placeholder)
├── services/
│   ├── agents_metrics_service.rb (placeholder)
│   ├── inbox_metrics_service.rb (placeholder)
│   └── sla_metrics_service.rb (placeholder)
├── queries/
│   ├── agents_metrics_query.rb (placeholder)
│   ├── conversations_metrics_query.rb (placeholder)
│   └── inbox_metrics_query.rb (placeholder)
├── serializers/
│   └── metrics_serializer.rb (placeholder)
└── jobs/
    └── refresh_metrics_job.rb (placeholder)
```



### 11. Redis Keys com Namespace

Criar `app/ottiv/core/concerns/redis_keys.rb`:

```ruby
module Ottiv
  module Core
    module Concerns
      module RedisKeys
        REDIS_NAMESPACE = 'ottiv:core'
        
        module Keys
          CONVERSATION_LIST_CACHE = "#{REDIS_NAMESPACE}:conversations:list:%{account_id}:%{user_id}"
          SEARCH_CACHE = "#{REDIS_NAMESPACE}:search:%{account_id}:%{query_hash}"
          CALENDAR_ITEM_MUTEX = "#{REDIS_NAMESPACE}:mutex:calendar_item:%{item_id}"
          SCHEDULED_MESSAGE_MUTEX = "#{REDIS_NAMESPACE}:mutex:scheduled_message:%{message_id}"
          NOTIFICATION_QUEUE = "#{REDIS_NAMESPACE}:notifications:queue:%{user_id}"
          CONFIG_CACHE = "#{REDIS_NAMESPACE}:config:%{account_id}"
        end
      end
    end
  end
end
```



### 12. Configurar Autoloading

Adicionar em `config/application.rb`:

```ruby
config.autoload_paths += %W[
  #{config.root}/app/ottiv
]
```



## Ordem de Execução

1. Criar estrutura de pastas `app/ottiv/core/` e `app/ottiv/analytics/`
2. Mover e renomear arquivos conforme mapeamento
3. Atualizar namespaces em todos os arquivos movidos
4. Atualizar referências nos controllers (chamadas de services/queries)
5. Atualizar rotas em `config/routes.rb`
6. Atualizar `config/schedule.yml`
7. Criar módulo Redis keys
8. Atualizar referências em models (Account, User, Contact)
9. Criar arquivos placeholder para analytics
10. Configurar autoloading
11. Testar e verificar que tudo funciona

## Arquivos Principais a Modificar

- [config/routes.rb](chatwoot/config/routes.rb) - Atualizar paths dos controllers
- [config/schedule.yml](chatwoot/config/schedule.yml) - Atualizar classe do job