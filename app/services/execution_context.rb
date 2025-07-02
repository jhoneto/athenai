class ExecutionContext
  attr_reader :captured_output

  def initialize
    @captured_output = StringIO.new
  end

  def execute_code(code, params = {})
    # Capturar output
    original_stdout = $stdout
    $stdout = @captured_output

    # Criar um binding isolado com os parâmetros
    binding_context = create_safe_binding(params)

    # Avaliar o código no contexto isolado
    result = binding_context.eval(code)

    result
  ensure
    # Restaurar stdout original
    $stdout = original_stdout
  end

  private

  def create_safe_binding(params)
    # Criar um objeto anônimo para servir como contexto
    context = Object.new
    captured_output = @captured_output

    # Definir métodos helper seguros
    context.define_singleton_method(:puts) do |*args|
      captured_output.puts(*args)
    end

    context.define_singleton_method(:print) do |*args|
      captured_output.print(*args)
    end

    context.define_singleton_method(:p) do |*args|
      captured_output.puts(args.map(&:inspect).join(" "))
    end

    # Adicionar parâmetros como variáveis locais
    params.each do |key, value|
      context.define_singleton_method(key) { value }
    end

    # Restringir acesso a métodos perigosos
    context.define_singleton_method(:system) do |*args|
      raise SecurityError, "system calls not allowed"
    end

    context.define_singleton_method(:`) do |*args|
      raise SecurityError, "backtick execution not allowed"
    end

    context.define_singleton_method(:exec) do |*args|
      raise SecurityError, "exec not allowed"
    end

    context.define_singleton_method(:spawn) do |*args|
      raise SecurityError, "spawn not allowed"
    end

    context.define_singleton_method(:fork) do |*args|
      raise SecurityError, "fork not allowed"
    end

    context.define_singleton_method(:exit) do |*args|
      raise SecurityError, "exit not allowed"
    end

    context.define_singleton_method(:exit!) do |*args|
      raise SecurityError, "exit! not allowed"
    end

    context.instance_eval { binding }
  end
end
