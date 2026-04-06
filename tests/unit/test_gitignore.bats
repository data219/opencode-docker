@test ".gitignore contains opencode-config/" {
  grep -q "opencode-config" .gitignore
}

@test ".gitignore contains opencode-data/" {
  grep -q "opencode-data" .gitignore
}

@test ".gitignore contains opencode-state/" {
  grep -q "opencode-state" .gitignore
}

@test ".gitignore contains workspace/" {
  grep -q "workspace" .gitignore
}

@test ".gitignore contains skills/" {
  grep -q "skills" .gitignore
}

@test ".gitignore contains .env" {
  grep -q "^\.env$" .gitignore
}

@test ".gitignore contains .env.local" {
  grep -q ".env.local" .gitignore
}
