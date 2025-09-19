# frozen_string_literal: true

require 'optparse'
require 'set'
require 'ripper'
require 'active_support/core_ext/string/inflections'

module ViewValues
  class CLI
    CODE_KEY_IGNORES = %w[try send public_send].freeze

    def self.run(argv)
      new.run(argv)
    end

    def run(argv)
      opts = {
        root: Dir.pwd,
        instance_var: (ViewValues.config.instance_var_name rescue :view_values).to_s,
        check_unused: false,
        include: nil,
        format: 'text'
      }

      parser = OptionParser.new do |o|
        o.banner = 'Usage: view_values check [options]'
        o.on('--root=PATH', 'Project root (default: current dir)') { |v| opts[:root] = File.expand_path(v) }
        o.on('--instance-var=NAME', 'Instance var name without @ (default: view_values)') { |v| opts[:instance_var] = v.to_s }
        o.on('--check-unused', 'Fail also when declared but unused keys exist') { opts[:check_unused] = true }
        o.on('--include=GLOB', 'Limit controllers to glob (relative to root)') { |v| opts[:include] = v }
        o.on('--format=FORMAT', 'text (default) | json (reserved)') { |v| opts[:format] = v }
      end

      cmd = argv.shift
      case cmd
      when 'check'
        parser.parse!(argv)
        status = Check.new(opts).call
        return status
      else
        puts parser
        return 1
      end
    end

    class Check
      VIEW_EXTS = %w[erb haml slim].freeze

      def initialize(opts)
        @root = opts[:root]
        @instance_var = opts[:instance_var]
        @check_unused = opts[:check_unused]
        @include = opts[:include]
        @format = opts[:format]
      end

      def call
        reports = []
        controller_files.each do |file|
          controller_name = path_to_controller_name(file)
          declared = extract_declared(file)
          declared.each do |action, keys|
            used = extract_used_keys(controller_name, action)
            missing = used - keys
            unused = keys - used
            if !missing.empty? || (@check_unused && !unused.empty?)
              reports << { controller: controller_name, action: action, missing: missing.to_a.sort, unused: unused.to_a.sort, views: view_files(controller_name, action) }
            end
          end
        end

        print_reports(reports)
        reports.empty? ? 0 : 1
      end

      private

      def controller_files
        patterns = []
        patterns << File.join(@root, 'app/controllers/**/*_controller.rb')
        patterns << File.join(@root, 'spec/app/controllers/**/*_controller.rb')
        files = patterns.flat_map { |p| Dir[p] }.uniq
        files = files.grep(/#{Regexp.escape(@include)}/) if @include
        files
      end

      def path_to_controller_name(path)
        rel = path.sub(%r{^.*/controllers/}, '')
        parts = rel.sub('.rb', '').split('/')
        namespaces = parts[0..-2].map { |seg| seg.camelize }
        base = parts[-1].sub(/_controller\z/, '').camelize + 'Controller'
        ([*namespaces, base].reject(&:empty?).join('::'))
      end

      def extract_declared(path)
        src = File.read(path)
        actions = {}
        current_action = nil
        src.each_line do |line|
          if (m = line.match(/^\s*def\s+([a-zA-Z0-9_!?]+)/))
            current_action = m[1]
          elsif line =~ /^\s*end\s*$/
            current_action = nil
          end

          next unless current_action
          next unless line.include?('build_view_values')

          declared = Set.new
          # data keys like { a: 1, 'b' => 2 }
          line.scan(/\{[^}]*\}/).each do |h|
            h.scan(/([a-zA-Z_]\w*[!?]?)[\s]*:/) { |(k)| declared << k }
            h.scan(/['"]([a-zA-Z_]\w*[!?]?)['"]\s*=>/) { |(k)| declared << k }
          end

          # helpers: %i[a b] or [:a, 'b']
          if (m = line.match(/helpers:\s*(%i\[[^\]]*\]|%I\[[^\]]*\]|\[[^\]]*\])/))
            lit = m[1]
            if lit.start_with?('%i', '%I')
              lit.scan(/([a-zA-Z_]\w*[!?]?)/) { |(k)| declared << k }
            else
              lit.scan(/[:'\"]([a-zA-Z_]\w*[!?]?)/) { |(k)| declared << k }
            end
          end

          actions[current_action] ||= Set.new
          actions[current_action].merge(declared)
        end
        actions
      end

      def extract_used_keys(controller_name, action)
        files = view_files(controller_name, action)
        used = Set.new
        files.each do |f|
          content = File.read(f)
          # code usage
          content.scan(/@#{Regexp.escape(@instance_var)}\.(\w[\w!?]*)/) do |(k)|
            next if CODE_KEY_IGNORES.include?(k)
            used << k
          end
          # comment allow-list
          content.scan(/#\s*use:\s*(.*)$/) do |(rest)|
            rest.scan(/@#{Regexp.escape(@instance_var)}\.(\w[\w!?\.]*)/) do |(tok)|
              used << tok.split('.').first
            end
          end
        end
        used
      end

      def view_files(controller_name, action)
        dir = controller_name.sub(/Controller\z/, '').gsub('::', '/').underscore
        bases = []
        bases << File.join(@root, 'app/views', dir, action)
        bases << File.join(@root, 'spec/app/views', dir, action)
        bases.flat_map { |base| VIEW_EXTS.flat_map { |ext| Dir["#{base}.html.#{ext}"] } }.uniq
      end

      def print_reports(reports)
        if @format == 'text'
          if reports.empty?
            puts 'view_values check: OK'
            return
          end
          reports.each do |r|
            puts "NG: #{r[:controller]}##{r[:action]}"
            puts "  views: #{r[:views].join(', ')}"
            unless r[:missing].empty?
              puts "  missing (used but not declared): #{r[:missing].join(', ')}"
            end
            unless r[:unused].empty?
              puts "  unused (declared but not used): #{r[:unused].join(', ')}"
            end
          end
        else
          # reserved for json output later
          puts({ reports: reports }.to_json)
        end
      end
    end
  end
end
