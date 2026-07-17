# Padrões de Background Jobs

## Filosofia de Jobs

Jobs devem **orquestrar, não executar**. A lógica complexa pertence a classes com namespace no model.

```ruby
# Bom — job orquestra
class WelcomeEmailJob < ApplicationJob
  def perform(user)
    UserMailer.welcome(user).deliver_now
  end
end

# Ruim — job executa tudo
class OnboardingJob < ApplicationJob
  def perform(user)
    # 100 linhas de lógica de onboarding
    # Chamadas HTTP, criação de registros...
  end
end
```

## Estrutura Básica de Job

```ruby
# app/jobs/application_job.rb
class ApplicationJob < ActiveJob::Base
  retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3
  retry_on Net::OpenTimeout, wait: :polynomially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError
end

# app/jobs/example_job.rb
class ExampleJob < ApplicationJob
  queue_as :default

  def perform(record)
    return if record.processed?

    process_record(record)
  rescue StandardError => e
    handle_failure(record, e)
    raise
  end

  private

  def process_record(record)
    # lógica orquestrada aqui
  end

  def handle_failure(record, error)
    Rails.error.report(error, handled: true, context: { record_id: record.id })
  end
end
```

## Configuração do SolidQueue

```yaml
# config/queue.yml
default: &default
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: [critical]
      threads: 3
      processes: 1
    - queues: [default, low]
      threads: 5
      processes: 2

development:
  <<: *default

production:
  <<: *default
```

## Prioridade de Filas

```ruby
class WelcomeEmailJob < ApplicationJob
  queue_as :default
end

class ReportGenerationJob < ApplicationJob
  queue_as :low
end

class CriticalNotificationJob < ApplicationJob
  queue_as :critical
end
```

## Tratamento de Erros

### Estratégias de Retry

```ruby
class ExternalApiJob < ApplicationJob
  # Backoff exponencial para timeout
  retry_on Net::OpenTimeout, wait: :polynomially_longer, attempts: 5

  # Delay fixo para rate limit
  retry_on RateLimitError, wait: 1.minute, attempts: 3

  # Sem retry para dados inválidos
  discard_on InvalidDataError
end
```

### Relatório de Erros

```ruby
class ExampleJob < ApplicationJob
  def perform(record)
    process(record)
  rescue StandardError => e
    Rails.error.report(e, handled: true, context: {
      record_id: record.id,
      account_id: record.account_id
    })
    # Não re-raise se o job foi "bem-sucedido" (erro tratado)
  end
end
```

## Padrões de Job

### Idempotência

Jobs devem ser seguros para executar múltiplas vezes:

```ruby
class ProcessRecordJob < ApplicationJob
  def perform(record)
    return if record.done?    # Guard clause — já processado
    return if record.failed?  # Guard clause — falha permanente

    process_record(record)
  end
end
```

### Processamento em Lotes

```ruby
class BulkExportJob < ApplicationJob
  def perform(account)
    account.resources.find_each(batch_size: 100) do |resource|
      ExportResourceJob.perform_later(resource)
    end
  end
end
```

### Jobs Agendados (config/recurring.yml)

```yaml
clear_finished_jobs:
  class: SolidQueue::RecurringJob
  schedule: "12 * * * *"

daily_report:
  class: DailyReportJob
  schedule: "0 6 * * *"
```

## Testando Jobs

```ruby
# spec/jobs/welcome_email_job_spec.rb
RSpec.describe WelcomeEmailJob do
  let(:user) { create(:user) }

  describe "#perform" do
    it "entrega o email de boas-vindas" do
      expect { described_class.perform_now(user) }
        .to have_enqueued_mail(UserMailer, :welcome).with(user)
    end
  end
end

# Testar enfileiramento do job
it "enfileira o job após criar usuário" do
  expect { create(:user) }.to have_enqueued_job(WelcomeEmailJob)
end
```

## Anti-Padrões

### Trabalho Síncrono de Longa Duração

```ruby
# Ruim — bloqueia por muito tempo
class ExportJob < ApplicationJob
  def perform(account)
    account.resources.each do |resource|
      generate_pdf(resource)  # 5 segundos cada
    end
  end
end

# Bom — distribui em jobs individuais
class ExportBatchJob < ApplicationJob
  def perform(account)
    account.resources.find_each do |resource|
      ExportResourcePdfJob.perform_later(resource)
    end
  end
end
```

### Lógica de Negócio em Jobs

```ruby
# Ruim — job contém lógica de negócio
class ProcessJob < ApplicationJob
  def perform(record)
    response = HTTParty.post(api_url, body: record.data.to_json)
    parsed = JSON.parse(response.body)
    record.update!(result: parsed["result"])
    # mais 50 linhas...
  end
end

# Bom — job orquestra
class ProcessJob < ApplicationJob
  def perform(record)
    Record::Processor.new(record).call
  end
end
```
