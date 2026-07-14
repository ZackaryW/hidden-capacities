Feature: hidden-capacities journeys
  Each journey is bound to a Flutter widget proof by its proof tag. The step
  runs the bound flutter test and inherits its verdict; behave never inspects
  Dart source.

  @proof_app_boots
  Scenario: the app boots to a no-token prompt and navigates to Settings
    Given a bound integration proof
    When the bound integration proof is executed
    Then it passes

  @proof_settings_persist
  Scenario: saving the token, passphrase and auto-decrypt persists them
    Given a bound integration proof
    When the bound integration proof is executed
    Then it passes

  # Note: the decrypt-and-view journey's logic is covered by unit tests
  # (home_controller_test, hidden_cap_service_test) rather than a widget proof;
  # flutter_quill's editor timers block widget-test completion.

  @proof_edit_reencrypt
  Scenario: a user decrypts a block, edits it in the editor, and saves to re-encrypt
    Given a bound integration proof
    When the bound integration proof is executed
    Then it passes

  @proof_edit_after_encrypt
  Scenario: a user opens the just-encrypted block for editing from the success screen
    Given a bound integration proof
    When the bound integration proof is executed
    Then it passes
