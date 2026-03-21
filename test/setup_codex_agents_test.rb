require_relative "test_helper"
require "open3"

class SetupCodexAgentsTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)
  SCRIPT_PATH = File.join(REPO_ROOT, "scripts", "setup-codex-agents.sh")
  LOCAL_SOURCE_PATH = File.join(REPO_ROOT, "tmp", "awesome-codex-subagents")
  MANAGED_AGENT_FILES = %w[
    accessibility-tester.toml
    api-designer.toml
    architect-reviewer.toml
    backend-developer.toml
    browser-debugger.toml
    build-engineer.toml
    cli-developer.toml
    code-mapper.toml
    code-reviewer.toml
    database-administrator.toml
    debugger.toml
    dependency-manager.toml
    deployment-engineer.toml
    devops-engineer.toml
    docs-researcher.toml
    documentation-engineer.toml
    dx-optimizer.toml
    error-detective.toml
    frontend-developer.toml
    fullstack-developer.toml
    git-workflow-manager.toml
    legacy-modernizer.toml
    performance-engineer.toml
    qa-expert.toml
    refactoring-specialist.toml
    reviewer.toml
    search-specialist.toml
    security-auditor.toml
    security-engineer.toml
    sre-engineer.toml
    test-automator.toml
    tooling-engineer.toml
    ui-designer.toml
    ui-fixer.toml
  ].freeze

  def test_setup_installs_all_managed_agents_from_local_source
    Dir.mktmpdir("codex-agents-test-") do |dir|
      destination_dir = File.join(dir, "agents")
      cache_dir = File.join(dir, "cache")

      stdout, stderr, status = run_setup(
        "AOZORASEARCH_CODEX_AGENT_SOURCE_URL" => LOCAL_SOURCE_PATH,
        "AOZORASEARCH_CODEX_AGENT_CACHE_DIR" => cache_dir,
        "AOZORASEARCH_CODEX_AGENT_DEST_DIR" => destination_dir,
      )

      assert status.success?, stderr
      assert_match(/Installed #{MANAGED_AGENT_FILES.size} managed agents/, stdout)

      installed_files = Dir.children(destination_dir).sort
      managed_manifest = File.join(destination_dir, ".aozorasearch-managed-agents")

      assert File.file?(managed_manifest)
      assert_equal(MANAGED_AGENT_FILES.sort,
                   File.readlines(managed_manifest, chomp: true).reject(&:empty?).sort)
      assert_equal((MANAGED_AGENT_FILES + [".aozorasearch-managed-agents"]).sort, installed_files)
    end
  end

  def test_setup_replaces_stale_managed_files_but_preserves_unmanaged_files
    Dir.mktmpdir("codex-agents-test-") do |dir|
      destination_dir = File.join(dir, "agents")
      cache_dir = File.join(dir, "cache")
      FileUtils.mkdir_p(destination_dir)
      File.write(File.join(destination_dir, "custom-agent.toml"), "name = \"custom-agent\"\n")
      File.write(File.join(destination_dir, "obsolete-agent.toml"), "name = \"obsolete-agent\"\n")
      File.write(File.join(destination_dir, ".aozorasearch-managed-agents"), "obsolete-agent.toml\n")

      _stdout, stderr, status = run_setup(
        "AOZORASEARCH_CODEX_AGENT_SOURCE_URL" => LOCAL_SOURCE_PATH,
        "AOZORASEARCH_CODEX_AGENT_CACHE_DIR" => cache_dir,
        "AOZORASEARCH_CODEX_AGENT_DEST_DIR" => destination_dir,
      )

      assert status.success?, stderr
      refute File.exist?(File.join(destination_dir, "obsolete-agent.toml"))
      assert File.exist?(File.join(destination_dir, "custom-agent.toml"))
      assert File.exist?(File.join(destination_dir, "ui-designer.toml"))
      assert File.exist?(File.join(destination_dir, "security-auditor.toml"))
    end
  end

  private

  def run_setup(extra_env)
    Open3.capture3(
      {
        "BUNDLE_GEMFILE" => File.join(REPO_ROOT, "Gemfile"),
      }.merge(extra_env),
      "bash",
      SCRIPT_PATH,
      chdir: REPO_ROOT,
    )
  end
end
