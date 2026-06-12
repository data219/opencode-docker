load ../test_helper

@test "bootstrap skills follow OpenCode skill naming rules" {
  run python3 scripts/validate-skills.py bootstrap/skills

  assert_success
  assert_output --partial "Skill validation passed"
}
