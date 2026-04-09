# Backfill de `ottiv_calls` a partir de mensagens existentes

Antes da telemetria `POST .../ottiv_calls/sync`, as gravações Wavoip chegavam ao Chatwoot como **mensagem privada outgoing** com anexo de áudio, via:

- **Compress** (`processWavoipRecording`): texto `Gravação da chamada (ID: <id>)` e arquivo `gravacao_chamada_<id>.mp3`
- **Chatwoot** (`Ottiv::Core::Jobs::FetchCallRecordingJob`): texto `[Ottiv] Gravação Wavoip (<id>)` e arquivo no padrão `wavoip_recording_<id>_...`

Este backfill **não baixa nada do Wavoip**: apenas cria linhas em `ottiv_calls` apontando para `Message` / `Attachment` já armazenados, para o relatório (`GET .../ottiv_calls`) e auditoria ficarem consistentes.

## Pré-requisitos

- Migração `ottiv_calls` aplicada
- Rodar no ambiente com acesso ao banco de produção/staging (conforme o caso)

## Rake task

| Variável      | Obrigatória | Descrição |
|---------------|-------------|-----------|
| `ACCOUNT_ID`  | Sim         | ID da conta Chatwoot |
| `DRY_RUN`     | Não         | `1` / `true` — apenas contabiliza o que seria criado, sem `INSERT` |
| `SINCE`       | Não         | Início (inclusivo) por `messages.created_at`, ex. `2025-01-01` |
| `UNTIL`       | Não         | Fim (inclusivo) por `messages.created_at` |

### Exemplos

Simulação (recomendado antes de gravar):

```bash
cd chatwoot
ACCOUNT_ID=42 DRY_RUN=1 bundle exec rake ottiv:backfill_calls_from_messages
```

Executar o backfill:

```bash
ACCOUNT_ID=42 bundle exec rake ottiv:backfill_calls_from_messages
```

Janela de datas:

```bash
ACCOUNT_ID=42 SINCE=2024-06-01 UNTIL=2025-12-31 bundle exec rake ottiv:backfill_calls_from_messages
```

## Serviço (uso programático)

```ruby
Ottiv::Core::Services::Calls::BackfillFromRecordingMessages.new(
  account: Account.find(42),
  dry_run: false,
  since: Time.zone.parse('2025-01-01'),
  until_time: Time.zone.parse('2025-12-31')
).perform
# => { scanned:, created:, skipped_duplicate:, skipped_no_call_id:, skipped_no_audio:, errors: [] }
```

## Regras de seleção

- Conversas da conta (`conversations.account_id`)
- `messages.private = true` e `message_type = outgoing`
- Conteúdo contém um dos padrões acima **ou** (fallback) anexo áudio com nome `gravacao_chamada_*.mp3` / `wavoip_recording_*`

## O que é gravado em cada `OttivCall`

- `provider`: `wavoip`
- `provider_call_id`: extraído do texto ou do nome do arquivo
- `status`: `recording_attached`
- `conversation_id`: conversa da mensagem
- **`user_id`** (e **`assignee_id`** no JSON da API, mesmo valor): `conversations.assignee_id` no momento do backfill (agente atribuído à conversa), **não** o remetente da mensagem. Sem assignee, fica `NULL`. No relatório, filtro `user_id` ou `agent_id` referem-se a esse assignee.
- `started_at` / `ended_at`: alinhados ao `created_at` da mensagem (sem duração real da chamada)
- `recording_message_id` / `recording_attachment_id`: primeira mensagem/anexo áudio encontrado
- `metadata`: inclui `backfilled`, `backfilled_at`, `source_message_id`

Registros com o mesmo `(account_id, provider, provider_call_id)` já existentes são **ignorados** (`skipped_duplicate`).

## Limitações

- Se aparecer `ActiveRecord::EagerLoadPolymorphicError` em `:sender`, o ambiente está com código antigo (o task usa `preload` de `:attachments` e `:conversation`, sem eager load de `sender`) — faça **deploy/rebuild** da imagem ou `git pull` + restart antes de rodar de novo.
- Mensagens com texto customizado que não siga os padrões e arquivo sem nome reconhecível **não** são associadas (`skipped_no_call_id`).
- Mensagem sem anexo áudio: `skipped_no_audio`.
- Não reexecuta download nem altera mensagens antigas.

## Relacionado

- API de sync: `POST /api/ottiv/v1/accounts/:account_id/ottiv_calls/sync`
- Relatório: `GET .../ottiv_calls` e `.../summary` — filtro opcional `user_id` ou `agent_id` (assignee). A **lista** vem ordenada só por `created_at` decrescente. O **summary** inclui `by_user_id` (contagem por assignee; chave `"null"` quando não há assignee gravado no registro).
- **Relatório na UI (frontend Auttus)**: ver [frontend/docs/OTTIV_CALLS_REPORT.md](../../frontend/docs/OTTIV_CALLS_REPORT.md) — rota `/reports`, aba **Chamadas**. No Chatwoot, `CHATWOOT_PUBLIC_BASE_URL` deve coincidir com `VITE_CHATWOOT_URL` para os links de áudio (`/rails/active_storage/...`) abrirem no browser.
- Variáveis de ambiente do job de gravação: `WAVOIP_RECORDING_URL`, `WAVOIP_RECORDING_DELAY` (ver `.env.example`)
