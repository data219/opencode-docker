@test ".gitignore excludes .env" {
  grep -q "^\.env$" .gitignore
}

@test ".gitignore excludes .env.local" {
  grep -q ".env.local" .gitignore
}

@test ".gitignore excludes .env.* with exception for .env.example" {
  grep -q '^.env\.\*' .gitignore
  grep -q '!\.env.example' .gitignore
}

@test ".gitignore excludes data/" {
  grep -q "^data/" .gitignore
}

@test ".gitignore excludes build artifacts (*.tar, *.tar.gz)" {
  grep -q "\*\.tar" .gitignore
}

@test ".gitignore does NOT exclude skills/" {
  ! grep -q "^skills/" .gitignore
}
