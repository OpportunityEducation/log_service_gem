group :unit do
  guard 'rspec', :spec_paths => ["spec/log_service"] do
    watch('spec/spec_helper.rb')  { "spec" }
    watch('spec/log_service/spec_helper.rb')  { "spec" }
    watch(%r{^spec/log_service/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$})     { |m| "spec/log_service/#{m[1]}_spec.rb" }
  end
end

group :integration do
  guard 'rspec', :spec_paths => ["spec/integration"] do
    watch('spec/spec_helper.rb')  { "spec" }
    watch('spec/integration/spec_helper.rb')  { "spec" }
    watch(%r{^spec/integration/.+_spec\.rb$})
  end
end

group :synchrony do
  guard 'rspec', :spec_paths => ["spec/synchrony"] do
    watch('spec/spec_helper.rb')  { "spec" }
    watch('spec/synchrony/spec_helper.rb')  { "spec" }
    watch(%r{^spec/synchrony/.+_spec\.rb$})
  end
end
