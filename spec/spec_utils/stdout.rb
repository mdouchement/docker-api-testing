def with_captured_console
  old_stdout = $stdout
  old_stderr = $stderr
  $stdout = $stderr = StringIO.new('', 'w')
  yield
  $stdout.string
ensure
  $stdout = old_stdout
  $stderr = old_stderr
end
