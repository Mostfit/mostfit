Merb.logger.info("Loaded TEST Environment...")
Merb::Config.use { |c|
  c[:testing]           = true
  c[:exception_details] = true
  c[:log_auto_flush ]   = true
  c[:log_level]         = :error
  c[:log_stream] = STDOUT

  # c[:log_file]  = Merb.root / "log" / "test.log"
  # or redirect logger using IO handle
}
