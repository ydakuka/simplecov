# frozen_string_literal: true

require "simplecov"
raise "YAML loaded by require simplecov" if defined?(YAML) || defined?(Psych)
require "tmpdir"

case ARGV.fetch(0)
when "load"
  # The require above is the complete operation.
when "missing"
  Dir.mktmpdir do |dir|
    value = SimpleCov::Baseline.read_if_exists(File.join(dir, "missing.yml"))
    raise "missing baseline returned a value" unless value.nil?
    raise "YAML loaded for an absent baseline" if defined?(YAML) || defined?(Psych)
  end
when "invalid_path"
  begin
    SimpleCov::Baseline.read_if_exists(nil)
    raise "invalid baseline path was accepted"
  rescue TypeError
    raise "YAML loaded for an invalid path" if defined?(YAML) || defined?(Psych)
  end
when "read"
  Dir.mktmpdir do |dir|
    path = File.join(dir, "baseline.yml")
    File.write(path, "lib/foo.rb: 41.2\n")
    baseline = SimpleCov::Baseline.read_if_exists(path)
    floor = baseline.floor_for("lib/foo.rb", :line)
    raise "baseline changed" unless floor.percent == 41.2 && floor.missed.nil?
  end
when "invalid_yaml"
  Dir.mktmpdir do |dir|
    path = File.join(dir, "baseline.yml")
    File.write(path, "{")
    begin
      SimpleCov::Baseline.read_if_exists(path)
      raise "invalid YAML was accepted"
    rescue SimpleCov::ConfigurationError => error
      prefix = "baseline file " + path + " is not valid YAML: "
      raise "baseline error changed" unless error.message.start_with?(prefix)
    end
  end
when "write"
  baseline = SimpleCov::Baseline.generate("lib/foo.rb" => {line: {percent: 41.2, missed: 3}})
  text = baseline.to_yaml
  document = YAML.safe_load(text)
  expected = {"lib/foo.rb" => {"lines" => {"percent" => 41.2, "missed" => 3}}}
  raise "serialized baseline changed" unless document == expected
else
  raise "unknown lazy YAML fixture mode"
end
