require 'rails_helper'

RSpec.describe ExecutionContext do
  let(:context) { described_class.new }

  describe "#execute_code" do
    it "executes simple Ruby code" do
      code = "2 + 2"
      result = context.execute_code(code)
      expect(result).to eq(4)
    end

    it "executes code with parameters" do
      code = "a + b"
      params = { "a" => 5, "b" => 3 }
      result = context.execute_code(code, params)
      expect(result).to eq(8)
    end

    it "captures puts output" do
      code = 'puts "Hello World"'
      result = context.execute_code(code)
      expect(context.captured_output.string).to eq("Hello World\n")
    end

    it "captures print output" do
      code = 'print "Hello"'
      result = context.execute_code(code)
      expect(context.captured_output.string).to eq("Hello")
    end

    it "captures p output" do
      code = 'p "Hello"'
      result = context.execute_code(code)
      expect(context.captured_output.string).to eq("\"Hello\"\n")
    end

    it "prevents system calls" do
      code = 'system("echo test")'
      expect {
        context.execute_code(code)
      }.to raise_error(SecurityError, "system calls not allowed")
    end

    it "prevents backtick execution" do
      code = '`echo test`'
      expect {
        context.execute_code(code)
      }.to raise_error(SecurityError, "backtick execution not allowed")
    end

    it "prevents exec calls" do
      code = 'exec("echo test")'
      expect {
        context.execute_code(code)
      }.to raise_error(SecurityError, "exec not allowed")
    end

    it "prevents spawn calls" do
      code = 'spawn("echo test")'
      expect {
        context.execute_code(code)
      }.to raise_error(SecurityError, "spawn not allowed")
    end

    it "prevents fork calls" do
      code = 'fork { puts "test" }'
      expect {
        context.execute_code(code)
      }.to raise_error(SecurityError, "fork not allowed")
    end

    it "prevents exit calls" do
      code = 'exit(0)'
      expect {
        context.execute_code(code)
      }.to raise_error(SecurityError, "exit not allowed")
    end

    it "prevents exit! calls" do
      code = 'exit!(0)'
      expect {
        context.execute_code(code)
      }.to raise_error(SecurityError, "exit! not allowed")
    end

    it "allows basic math operations" do
      code = "Math.sqrt(16)"
      result = context.execute_code(code)
      expect(result).to eq(4.0)
    end

    it "allows string operations" do
      code = '"hello".upcase'
      result = context.execute_code(code)
      expect(result).to eq("HELLO")
    end

    it "allows array operations" do
      code = "[1, 2, 3].sum"
      result = context.execute_code(code)
      expect(result).to eq(6)
    end

    it "allows hash operations" do
      code = '{ a: 1, b: 2 }[:a]'
      result = context.execute_code(code)
      expect(result).to eq(1)
    end

    it "handles syntax errors" do
      code = "def broken_syntax"
      expect {
        context.execute_code(code)
      }.to raise_error(SyntaxError)
    end

    it "handles runtime errors" do
      code = "1 / 0"
      expect {
        context.execute_code(code)
      }.to raise_error(ZeroDivisionError)
    end

    it "restores stdout after execution" do
      original_stdout = $stdout
      code = 'puts "test"'
      context.execute_code(code)
      expect($stdout).to eq(original_stdout)
    end

    it "restores stdout even when exception occurs" do
      original_stdout = $stdout
      code = "raise 'error'"
      expect {
        context.execute_code(code)
      }.to raise_error(RuntimeError)
      expect($stdout).to eq(original_stdout)
    end

    context "with complex code" do
      it "executes method definitions and calls" do
        code = <<~RUBY
          def greet(name)
            "Hello, \#{name}!"
          end

          greet(name)
        RUBY

        params = { "name" => "World" }
        result = context.execute_code(code, params)
        expect(result).to eq("Hello, World!")
      end

      it "executes loops and iterations" do
        code = <<~RUBY
          total = 0
          numbers.each do |num|
            total += num
          end
          total
        RUBY

        params = { "numbers" => [ 1, 2, 3, 4, 5 ] }
        result = context.execute_code(code, params)
        expect(result).to eq(15)
      end

      it "executes conditional logic" do
        code = <<~RUBY
          if age >= 18
            "adult"
          else
            "minor"
          end
        RUBY

        params = { "age" => 25 }
        result = context.execute_code(code, params)
        expect(result).to eq("adult")
      end
    end
  end

  describe "#captured_output" do
    it "returns a StringIO object" do
      expect(context.captured_output).to be_a(StringIO)
    end

    it "starts empty" do
      expect(context.captured_output.string).to be_empty
    end
  end
end
