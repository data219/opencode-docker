@test ".env.example documents ZHIPU_API_KEY" {
  grep -q "ZHIPU_API_KEY" .env.example
}

@test ".env.example marks ZHIPU_API_KEY as required" {
  grep -qi "required\|must\|PLEASE" .env.example
}

@test ".env.example documents OPENCODE_MODE" {
  grep -q "OPENCODE_MODE" .env.example
}

@test ".env.example documents OPENCODE_PORT" {
  grep -q "OPENCODE_PORT" .env.example
}

@test ".env.example documents OPENCODE_SERVER_PASSWORD" {
  grep -q "OPENCODE_SERVER_PASSWORD" .env.example
}

@test ".env.example documents OPENCODE_BIND_ADDRESS" {
  grep -q "OPENCODE_BIND_ADDRESS" .env.example
}

@test ".env.example clarifies OPENCODE_BIND_ADDRESS is host-level port binding" {
  grep -qi "host.*level\|host.*port\|host.*binding\|compose.*only\|NOT.*pass.*container" .env.example
}

@test ".env.example has strong warning about 0.0.0.0 + empty password" {
  grep -qi "0.0.0.0.*password\|password.*0.0.0.0\|WARNING\|MUST.*password" .env.example
}

@test ".env.example documents TUI access via docker exec" {
  grep -q "docker exec" .env.example
}

@test ".env.example does NOT list TUI as a mode option" {
  mode_line=$(grep "OPENCODE_MODE" .env.example)
  ! echo "$mode_line" | grep -qi "tui"
}

@test ".env.example documents build-args for optional languages" {
  grep -q "INSTALL_JAVA\|INSTALL_RUBY\|INSTALL_SWIFT\|INSTALL_ELIXIR" .env.example
}

@test ".env.example separates build args from runtime env vars" {
  grep -qi "BUILD.*ARG\|build.*time\|runtime" .env.example
}

@test ".env.example documents GEMINI_API_KEY" {
  grep -q "GEMINI_API_KEY" .env.example
}

@test ".env.example marks GEMINI_API_KEY as optional" {
  grep -qi "optional.*gemini\|gemini.*optional" .env.example
}
