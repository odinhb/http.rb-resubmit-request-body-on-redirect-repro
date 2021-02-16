def unwind_causes(exception)
  if exception.cause
    puts "CAUSE: #{exception.cause.class}: #{exception.cause.message}"
    puts
    unwind_causes(exception.cause)
  end
end
