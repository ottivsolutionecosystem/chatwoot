# frozen_string_literal: true

# Configura o autoloading do Zeitwerk para os arquivos Ottiv com o namespace correto.
#
# Sem esta configuração, adicionar app/ottiv via config.autoload_paths faria com que
# Zeitwerk resolvesse app/ottiv/core/controllers/... como Core::Controllers::...
# Em vez do esperado: Ottiv::Core::Controllers::...
#
# Usando push_dir com namespace: Ottiv (disponível desde Zeitwerk 2.6.0),
# garantimos que a hierarquia de constantes seja corretamente prefixada com Ottiv::.
#
# IMPORTANTE: Pré-definimos Ottiv::Core e seus sub-módulos ANTES do push_dir para
# evitar o erro "uninitialized constant Ottiv::Core::Controllers::Api::Ottiv::Core".
# Esse erro ocorre porque Zeitwerk cria um alias Ottiv::Core::Controllers::Api::Ottiv = ::Ottiv
# para facilitar lookups internos. Se ::Ottiv::Core não estiver definido nesse momento,
# a resolução circular falha. Pré-definir garante que o módulo já existe.
#
# Referência: https://github.com/fxn/zeitwerk#custom-namespace

# Pré-define a hierarquia de módulos Ottiv para evitar erros de resolução circular
# durante o setup do Zeitwerk. Os arquivos em app/ottiv/ serão carregados dentro
# desses módulos existentes.
module Ottiv
  module Core
    module Controllers
      module Platform
        module Api
          module V1; end
        end
      end
      module Api
        module V1
          module Accounts; end
          module Webhook; end
          module Conversations; end
        end
      end
    end

    module Services
      module ScheduledMessages; end
      module CalendarItems; end
      module Wavoip; end
      module Finance; end
    end

    module Jobs
      module OttivSearch; end
    end
    module Queries; end
    module Concerns; end
    module Meilisearch; end
  end
end

ottiv_path = Rails.root.join('app/ottiv')

if ottiv_path.exist?
  # push_dir com namespace: Ottiv faz com que app/ottiv/core/... resolva para
  # Ottiv::Core::... (em vez de Core::... sem o namespace).
  # O Zeitwerk 2.6+ já inclui o diretório no eager load automaticamente.
  Rails.autoloaders.main.push_dir(ottiv_path, namespace: Ottiv)
end
