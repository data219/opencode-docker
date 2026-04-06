@test ".gitignore exists" {
  [ -f .gitignore ]
}

@test ".gitignore excludes .env" {
  grep -q '^.env' .gitignore
}

@test ".gitignore excludes opencode-config/" {
  grep -q 'opencode-config/' .gitignore
}

@test ".gitignore excludes opencode-data/" {
  grep -q 'opencode-data/' .gitignore
}

@test ".gitignore allows .env.example" {
  grep -q '!.env.example' .gitignore
}
