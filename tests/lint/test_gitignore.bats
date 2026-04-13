@test ".gitignore exists" {
  [ -f .gitignore ]
}

@test ".gitignore excludes .env" {
  grep -q '^.env' .gitignore
}

@test ".gitignore excludes data/" {
  grep -q '^data/' .gitignore
}

@test ".gitignore allows .env.example" {
  grep -q '!.env.example' .gitignore
}
